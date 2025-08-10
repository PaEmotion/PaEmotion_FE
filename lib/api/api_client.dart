import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/user_manager.dart';
import '../models/user.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://d3445b7362f0.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: 'https://d3445b7362f0.ngrok-free.app',
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

  // 진행 중인 refresh 단일화
  static Future<String?>? _ongoingRefresh;

  /// 앱 시작 등에서 미리 access token 만료 직전이면 갱신
  static Future<void> ensureValidAccessToken({Duration skew = const Duration(minutes: 2)}) async {
    final user = UserManager().currentUser;
    if (user == null || user.accessToken.isEmpty || user.refreshToken.isEmpty) return;

    if (_isAccessTokenExpiringSoon(user.accessToken, skew: skew)) {
      debugPrint('⏱️ Preemptive refresh: token expiring soon');
      try {
        final newAccess = await _refreshAccessToken(user.refreshToken);
        if (newAccess != null && newAccess.isNotEmpty) {
          await _saveUpdatedAccessToken(user, newAccess);
          debugPrint('✅ Preemptive refresh succeeded');
        } else {
          debugPrint('⚠️ Preemptive refresh returned empty');
        }
      } catch (e) {
        debugPrint('❌ Preemptive refresh failed: $e');
      }
    } else {
      debugPrint('✅ Access token still fresh');
    }
  }

  static void initInterceptor(GlobalKey<NavigatorState> navigatorKey) {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('➡️ Request: [${options.method}] ${options.uri.toString()}');
          debugPrint('Headers before auth check: ${options.headers}');
          debugPrint('Data: ${options.data}');

          final path = options.uri.path;

          if (path == _refreshPath) {
            debugPrint('ℹ️ Request is token refresh, skipping auth header attach');
            return handler.next(options);
          }

          final normalizedPath = path.replaceAll(RegExp(r'/+$'), '');
          final requiresAuth = _privatePaths.any((p) {
            final normalizedP = p.replaceAll(RegExp(r'/+$'), '');
            return normalizedPath == normalizedP || normalizedPath.startsWith('$normalizedP/');
          });

          debugPrint('Authentication required for $path? $requiresAuth');

          final user = UserManager().currentUser;
          debugPrint('Current user: $user');

          if (!requiresAuth) {
            debugPrint('ℹ️ No auth needed, so Authorization header NOT added');
            return handler.next(options);
          }

          if (user == null || user.accessToken.isEmpty) {
            debugPrint('⚠️ No logged-in user/token for $path');
            return handler.next(options);
          }

          String accessToUse = user.accessToken;

          try {
            if (_isAccessTokenExpiringSoon(user.accessToken)) {
              debugPrint('⏱️ Access token expiring soon before request → refreshing');
              final refreshed = await _refreshAccessToken(user.refreshToken);
              if (refreshed != null && refreshed.isNotEmpty) {
                await _saveUpdatedAccessToken(user, refreshed);
                accessToUse = refreshed;
                debugPrint('🛡️ Used refreshed access token');
              } else {
                debugPrint('⚠️ Refresh returned empty, falling back to old token');
              }
            }
          } catch (e) {
            debugPrint('⚠️ Pre-request refresh attempt failed: $e');
          }

          options.headers['Authorization'] = 'Bearer $accessToUse';
          debugPrint('🛡️ Authorization header set for $path');
          debugPrint('Headers after auth attach: ${options.headers}');
          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint('⬅️ Response: [${response.statusCode}] ${response.requestOptions.uri.toString()}');
          debugPrint('Response data: ${response.data}');
          handler.next(response);
        },

        onError: (DioException e, ErrorInterceptorHandler handler) async {
          debugPrint('❌ Error: [${e.response?.statusCode}] ${e.requestOptions.uri.toString()}');
          debugPrint('Error data: ${e.response?.data}');

          final req = e.requestOptions;
          final path = Uri.parse(req.uri.toString()).path;

          if (req.extra['retried'] == true) {
            debugPrint('⚠️ Request already retried once, forwarding error');
            return handler.next(e);
          }

          if (path == _refreshPath) {
            debugPrint('🚫 Refresh endpoint failed → forcing logout');
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
                debugPrint('🔁 Retry once with existing token');
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
              } catch (retryErr) {
                debugPrint('⚠️ Retry without refresh failed: $retryErr');
              }
            }
          }

          final currentUser = UserManager().currentUser;
          final refreshToken = currentUser?.refreshToken ?? '';
          if (currentUser == null || refreshToken.isEmpty) {
            debugPrint('⚠️ No refresh token available → logout');
            await _forceLogout(navigatorKey.currentState);
            return handler.next(e);
          }

          try {
            debugPrint('🔄 Attempting refresh after 401');
            final newAccess = await _refreshAccessToken(refreshToken);
            if (newAccess == null || newAccess.isEmpty) {
              debugPrint('🚫 Refresh failed or empty → logout');
              await _forceLogout(navigatorKey.currentState);
              return handler.next(e);
            }

            await _saveUpdatedAccessToken(currentUser, newAccess);

            debugPrint('✅ Retry original request with refreshed token');
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
          } catch (refreshErr) {
            debugPrint('❌ Token refresh failed: $refreshErr');
            await _forceLogout(navigatorKey.currentState);
            return handler.next(e);
          }
        },
      ),
    );
  }

  static Future<String?> _refreshAccessToken(String refreshToken) async {
    if (_ongoingRefresh != null) {
      debugPrint('⏳ Waiting for ongoing refresh');
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
        // 응답이 { success, message, data: { access_token: ... } } 형태일 경우
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final v = inner['access_token'] ?? inner['accessToken'];
          if (v is String) newAccess = v;
        }

        // 혹시 루트에 직접 있을 경우도 대비 (기존 구조 호환)
        final rootToken = data['access_token'] ?? data['accessToken'];
        if (rootToken is String) newAccess ??= rootToken;
      }

      debugPrint('🔑 Got new access token');
      completer.complete(newAccess);
      return newAccess;
    } catch (err) {
      debugPrint('❌ Refresh error: $err');
      completer.completeError(err);
      rethrow;
    } finally {
      _ongoingRefresh = null;
    }
  }

  static Future<void> _saveUpdatedAccessToken(User user, String newAccessToken) async {
    // UserManager 안에서 copyWith + persistence + notify 처리
    await UserManager().updateAccessToken(newAccessToken);
  }

  static bool _isAccessTokenExpiringSoon(String accessToken,
      {Duration skew = const Duration(minutes: 2)}) {
    try {
      final exp = _getJwtExpiry(accessToken);
      if (exp == null) return false;
      final now = DateTime.now().toUtc();
      return exp.isBefore(now.add(skew));
    } catch (e) {
      debugPrint('⚠️ JWT parse failed: $e');
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
    debugPrint('🚪 Forcing logout');
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
