import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/user_manager.dart';
import '../models/user.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: '서버 URL',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: '서버 URL',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const String _refreshPath = '/users/token/refresh';

  static const List<String> _privatePaths = [
    '/users/me',
    '/challenges/join',
    '/challenges/create',
    '/challenges/current',
    '/users/nickname',
    '/records/me',
    '/records/me/',
    '/ml/predict',
    '/budgets/me',
    '/budgets/lastspent/me',
    '/budgets/create',
    '/challenges/detail/'
  ];

  static Future<String?>? _ongoingRefresh;

  static Future<void> ensureValidAccessToken({Duration skew = const Duration(minutes: 2)}) async {
    final user = UserManager().currentUser;
    if (user == null || user.accessToken.isEmpty || user.refreshToken.isEmpty) return;

    if (_isAccessTokenExpiringSoon(user.accessToken, skew: skew)) {
      try {
        final newAccess = await _refreshAccessToken(user.refreshToken);
        if (newAccess != null && newAccess.isNotEmpty) {
          await _saveUpdatedAccessToken(user, newAccess);
        }
      } catch (_) {
        // 토큰 갱신 실패 시 기존 토큰 사용
      }
    }
  }

  static void initInterceptor(GlobalKey<NavigatorState> navigatorKey) {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.uri.path;

          if (path == _refreshPath) {
            return handler.next(options);
          }

          final normalizedPath = path.replaceAll(RegExp(r'/+$'), '');
          final requiresAuth = _privatePaths.any((p) {
            final normalizedP = p.replaceAll(RegExp(r'/+$'), '');
            return normalizedPath == normalizedP || normalizedPath.startsWith('$normalizedP/');
          });

          final user = UserManager().currentUser;

          if (!requiresAuth) {
            return handler.next(options);
          }

          if (user == null || user.accessToken.isEmpty) {
            return handler.next(options);
          }

          String accessToUse = user.accessToken;

          try {
            if (_isAccessTokenExpiringSoon(user.accessToken)) {
              final refreshed = await _refreshAccessToken(user.refreshToken);
              if (refreshed != null && refreshed.isNotEmpty) {
                await _saveUpdatedAccessToken(user, refreshed);
                accessToUse = refreshed;
              }
            }
          } catch (_) {
            // 토큰 갱신 실패 시 기존 토큰 사용
          }

          options.headers['Authorization'] = 'Bearer $accessToUse';
          handler.next(options);
        },

        onResponse: (response, handler) {
          handler.next(response);
        },

        onError: (DioException e, ErrorInterceptorHandler handler) async {
          final req = e.requestOptions;
          final path = Uri.parse(req.uri.toString()).path;

          if (req.extra['retried'] == true) {
            return handler.next(e);
          }

          if (path == _refreshPath) {
            await _forceLogout(navigatorKey.currentState);
            return handler.next(e);
          }

          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final hadAuthHeader = (req.headers['Authorization'] ?? '').toString().startsWith('Bearer ');
          if (!hadAuthHeader) {
            final current = UserManager().currentUser;
            if (current != null && current.accessToken.isNotEmpty) {
              try {
                final retryNoRefresh = await dio.fetch(
                  req.copyWith(
                    headers: {
                      ...Map<String, dynamic>.from(req.headers),
                      'Authorization': 'Bearer ${current.accessToken}',
                    },
                    extra: {...req.extra, 'retried': true},
                  ),
                );
                return handler.resolve(retryNoRefresh);
              } catch (_) {
                // 재시도 실패 무시
              }
            }
          }

          final currentUser = UserManager().currentUser;
          final refreshToken = currentUser?.refreshToken ?? '';
          if (currentUser == null || refreshToken.isEmpty) {
            await _forceLogout(navigatorKey.currentState);
            return handler.next(e);
          }

          try {
            final newAccess = await _refreshAccessToken(refreshToken);
            if (newAccess == null || newAccess.isEmpty) {
              await _forceLogout(navigatorKey.currentState);
              return handler.next(e);
            }

            await _saveUpdatedAccessToken(currentUser, newAccess);
            final retryResponse = await dio.fetch(
              req.copyWith(
                headers: {
                  ...Map<String, dynamic>.from(req.headers),
                  'Authorization': 'Bearer $newAccess',
                },
                extra: {...req.extra, 'retried': true},
              ),
            );
            return handler.resolve(retryResponse);
          } catch (_) {
            await _forceLogout(navigatorKey.currentState);
            return handler.next(e);
          }
        },
      ),
    );
  }

  static Future<String?> _refreshAccessToken(String refreshToken) async {
    if (_ongoingRefresh != null) {
      return _ongoingRefresh!;
    }

    final completer = Completer<String?>();
    _ongoingRefresh = completer.future;

    try {
      final res = await _refreshDio.post(
        _refreshPath,
        data: {'refresh_token': refreshToken},
      );

      String? newAccess;
      final data = res.data;

      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final v = inner['access_token'] ?? inner['accessToken'];
          if (v is String) newAccess = v;
        }

        final rootToken = data['access_token'] ?? data['accessToken'];
        if (rootToken is String) newAccess ??= rootToken;
      }

      completer.complete(newAccess);
      return newAccess;
    } catch (err) {
      completer.completeError(err);
      rethrow;
    } finally {
      _ongoingRefresh = null;
    }
  }

  static Future<void> _saveUpdatedAccessToken(User user, String newAccessToken) async {
    await UserManager().updateAccessToken(newAccessToken);
  }

  static bool _isAccessTokenExpiringSoon(String accessToken,
      {Duration skew = const Duration(minutes: 2)}) {
    try {
      final exp = _getJwtExpiry(accessToken);
      if (exp == null) return false;
      final now = DateTime.now().toUtc();
      return exp.isBefore(now.add(skew));
    } catch (_) {
      return true;
    }
  }

  static DateTime? _getJwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = _decodeBase64Url(parts[1]);
    final map = jsonDecode(payload);
    if (map is! Map || map['exp'] == null) return null;
    final expSec = map['exp'];
    if (expSec is int) {
      return DateTime.fromMillisecondsSinceEpoch(expSec * 1000, isUtc: true);
    } else if (expSec is double) {
      return DateTime.fromMillisecondsSinceEpoch(expSec.toInt() * 1000, isUtc: true);
    }
    return null;
  }

  static String _decodeBase64Url(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');
    while (output.length % 4 != 0) {
      output += '=';
    }
    return utf8.decode(base64Url.decode(output));
  }

  static Future<void> _forceLogout(NavigatorState? navigatorState) async {
    await UserManager().logout();
    if (navigatorState != null) {
      showDialog(
        context: navigatorState.context,
        builder: (context) => AlertDialog(
          title: const Text('세션 만료'),
          content: const Text('로그인 세션이 만료되었습니다. 다시 로그인 해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}