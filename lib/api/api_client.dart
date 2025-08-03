import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../utils/user_storage.dart';
import '../utils/user_manager.dart';
import '../models/user.dart';

class ApiClient {
  // 메인 Dio
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://5f21f1fcbd69.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // refresh 전용 Dio (인터셉터 없음)
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: 'https://5f21f1fcbd69.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const String _refreshPath = '/users/token/refresh';

  // 토큰 붙여야 하는 private path
  static const List<String> _privatePaths = [
    '/users/me',
    '/challenges/join',
    '/challenges/create',
    '/challenges/current',
    '/users/nickname',
  ];

  // 동시 refresh 단일화 처리용 Completer
  static Completer<String?>? _refreshCompleter;

  /// 앱 시작 시 액세스 토큰 만료 임박 감지 => 선제 refresh
  static Future<void> ensureValidAccessToken({Duration skew = const Duration(minutes: 2)}) async {
    final user = await UserStorage.loadUser();
    if (user == null || user.accessToken.isEmpty || user.refreshToken.isEmpty) {
      return;
    }

    if (_isAccessTokenExpiringSoon(user.accessToken, skew: skew)) {
      debugPrint('⏱️ Access token expiring soon at app start → refreshing...');
      try {
        final newAccess = await _refreshAccessToken(user.refreshToken);
        if (newAccess != null && newAccess.isNotEmpty) {
          final updated = User(
            id: user.id,
            email: user.email,
            name: user.name,
            nickname: user.nickname,
            accessToken: newAccess,
            refreshToken: user.refreshToken,
          );
          await UserStorage.saveUser(updated);
          debugPrint('✅ Pre-emptive refresh success on app start');
        } else {
          debugPrint('⚠️ Pre-emptive refresh returned empty token');
        }
      } catch (e) {
        debugPrint('❌ Pre-emptive refresh failed: $e');
        // 실패해도 인터셉터 401 처리에 맡김
      }
    } else {
      debugPrint('✅ Access token still valid at app start (no refresh needed)');
    }
  }

  static void initInterceptor(GlobalKey<NavigatorState> navigatorKey) {
    dio.interceptors.clear();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('➡️ Request: [${options.method}] ${options.uri}');
          final path = options.uri.path;

          // refresh 토큰 요청일 경우 Authorization 없음
          if (path == _refreshPath) {
            return handler.next(options);
          }

          // privatePaths에 포함되는지 검사
          final requiresAuth = _privatePaths.any((p) => path.startsWith(p));

          if (!requiresAuth) {
            // privatePath가 아니면 Authorization 없이 진행
            debugPrint('ℹ️ Not private path, no Authorization added for $path');
            return handler.next(options);
          }

          final user = await UserStorage.loadUser();

          if (user == null || user.accessToken.isEmpty) {
            debugPrint('⚠️ No user/accessToken for $path (will likely 401)');
            return handler.next(options);
          }

          try {
            if (_isAccessTokenExpiringSoon(user.accessToken)) {
              debugPrint('⏱️ Access token expiring soon before request $path → refreshing...');
              final newAccess = await _refreshAccessToken(user.refreshToken);
              if (newAccess != null && newAccess.isNotEmpty) {
                final updated = User(
                  id: user.id,
                  email: user.email,
                  name: user.name,
                  nickname: user.nickname,
                  accessToken: newAccess,
                  refreshToken: user.refreshToken,
                );
                await UserStorage.saveUser(updated);
                options.headers['Authorization'] = 'Bearer $newAccess';
                debugPrint('🛡️ Added refreshed Authorization header for $path');
              } else {
                options.headers['Authorization'] = 'Bearer ${user.accessToken}';
                debugPrint('🛡️ Added current Authorization header (refresh returned empty) for $path');
              }
            } else {
              if (!(options.headers['Authorization']?.toString().startsWith('Bearer ') ?? false)) {
                options.headers['Authorization'] = 'Bearer ${user.accessToken}';
                debugPrint('🛡️ Added Authorization header for $path');
              }
            }
          } catch (e) {
            options.headers['Authorization'] = 'Bearer ${user.accessToken}';
            debugPrint('⚠️ Pre-request refresh failed, sending with current token for $path: $e');
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          debugPrint('⬅️ Response: [${response.statusCode}] ${response.requestOptions.uri}');
          handler.next(response);
        },

        onError: (DioException e, ErrorInterceptorHandler handler) async {
          debugPrint('❌ Error: [${e.response?.statusCode}] ${e.requestOptions.uri}');

          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final req = e.requestOptions;
          final path = Uri.parse(req.uri.toString()).path;

          // refresh 요청에서 401 발생 시 강제 로그아웃
          if (path == _refreshPath) {
            debugPrint('🚫 Refresh endpoint 401 → forcing logout');
            await _forceLogout(navigatorKey.currentContext);
            return handler.next(e);
          }

          final hadAuth = (req.headers['Authorization'] ?? '').toString().startsWith('Bearer ');

          if (!hadAuth) {
            final u = await UserStorage.loadUser();
            if (u != null && u.accessToken.isNotEmpty) {
              try {
                debugPrint('🔁 Retrying original request with current access token (no refresh)');
                req.headers['Authorization'] = 'Bearer ${u.accessToken}';
                final retryNoRefresh = await dio.fetch(req);
                return handler.resolve(retryNoRefresh);
              } catch (retryErr) {
                debugPrint('⚠️ Retry without refresh failed: $retryErr');
              }
            }
          }

          final user = await UserStorage.loadUser();
          final refreshToken = user?.refreshToken ?? '';
          if (user == null || refreshToken.isEmpty) {
            debugPrint('⚠️ No user/refresh token → forcing logout');
            await _forceLogout(navigatorKey.currentContext);
            return handler.next(e);
          }

          try {
            debugPrint('🔄 Attempting to refresh access token (on 401)');
            final newAccessToken = await _refreshAccessToken(refreshToken);

            if (newAccessToken == null || newAccessToken.isEmpty) {
              debugPrint('🚫 Refresh rejected → forcing logout');
              await _forceLogout(navigatorKey.currentContext);
              return handler.next(e);
            }

            final updatedUser = User(
              id: user.id,
              email: user.email,
              name: user.name,
              nickname: user.nickname,
              accessToken: newAccessToken,
              refreshToken: user.refreshToken,
            );
            await UserStorage.saveUser(updatedUser);

            debugPrint('✅ Token refreshed, retrying original request');
            req.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(req);
            return handler.resolve(retryResponse);
          } catch (refreshErr) {
            debugPrint('❌ Token refresh failed: $refreshErr');
            await _forceLogout(navigatorKey.currentContext);
            return handler.next(e);
          }
        },
      ),
    );
  }

  /// refresh 토큰으로 access 토큰 갱신 (동시에 한 번만 수행)
  static Future<String?> _refreshAccessToken(String refreshToken) async {
    if (_refreshCompleter != null) {
      debugPrint('⏳ Waiting for ongoing token refresh');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String?>();
    try {
      final res = await _refreshDio.post(
        _refreshPath,
        data: {'refresh_token': refreshToken},
      );

      String? newAccess;
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final v = data['access_token'] ?? data['accessToken'];
        if (v is String) newAccess = v;
      }
      debugPrint('🔑 Received new access token');

      _refreshCompleter!.complete(newAccess);
      return newAccess;
    } catch (err) {
      debugPrint('❌ Error refreshing token: $err');
      _refreshCompleter!.completeError(err);
      rethrow;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// 액세스 토큰 만료 임박 여부 판단
  static bool _isAccessTokenExpiringSoon(String accessToken,
      {Duration skew = const Duration(minutes: 2)}) {
    try {
      final exp = _getJwtExpiry(accessToken);
      if (exp == null) return false;
      final now = DateTime.now().toUtc();
      return exp.isBefore(now.add(skew));
    } catch (_) {
      return false;
    }
  }

  /// JWT 토큰 만료 시간 추출
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

  static Future<void> _forceLogout(BuildContext? context) async {
    debugPrint('🚪 Forcing logout');
    await UserManager().logout();
    if (context != null) {
      showDialog(
        context: context,
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
