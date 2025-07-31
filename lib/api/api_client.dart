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
      baseUrl: 'https://e9dde3dc31d4.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // refresh 전용 Dio (인터셉터 없음)
  static final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: 'https://e9dde3dc31d4.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const String _refreshPath = '/users/token/refresh';

  /// 공개(인증 불필요) 엔드포인트만 정리. 나머지는 모두 토큰 부착/검사.
  static const List<String> _publicPaths = <String>[
    '/users/login',
    '/users/register',
    _refreshPath,
    // 공개 목록들 추가 필요 시 여기에...
    '/challenges', // 목록이 공개면 유지
    '/records',    // 네가 말한 대로 공개라면 유지
  ];

  // 동시 refresh 단일화
  static Completer<String?>? _refreshCompleter;

  /// 앱 시작 시 한 번 호출해서 액세스 토큰이 만료/임박이면 선제적으로 refresh
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
        // 실패해도 여기선 바로 로그아웃하지 않고, 인터셉터 401 핸들링에 맡김
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

          final isPublic = _publicPaths.any((p) => path.startsWith(p));
          final hasAuthHeader = (options.headers['Authorization'] ?? '')
              .toString()
              .startsWith('Bearer ');

          if (isPublic) {
            debugPrint('ℹ️ Public endpoint, no Authorization for $path');
            return handler.next(options);
          }

          // 비공개(인증 필요) 요청: 토큰 검사 및 선제 refresh
          final user = await UserStorage.loadUser();

          if (user == null || user.accessToken.isEmpty) {
            debugPrint('⚠️ No user/accessToken for $path (will likely 401)');
            return handler.next(options);
          }

          try {
            // 만료 임박이면 미리 refresh (중복 방지됨)
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
                // 새 토큰 없음 → 기존 토큰으로 보냄(401은 onError에서 처리)
                options.headers['Authorization'] = 'Bearer ${user.accessToken}';
                debugPrint('🛡️ Added current Authorization header (refresh returned empty) for $path');
              }
            } else {
              // 아직 유효 → 현 토큰 사용
              if (!hasAuthHeader) {
                options.headers['Authorization'] = 'Bearer ${user.accessToken}';
                debugPrint('🛡️ Added Authorization header for $path');
              } else {
                debugPrint('🛡️ Authorization header already present for $path (kept as-is)');
              }
            }
          } catch (e) {
            // 선제 refresh 실패 → 기존 토큰으로 시도(401은 onError에서 처리)
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

          // 401만 여기서 다룸 (404 등은 통과)
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          final req = e.requestOptions;
          final path = Uri.parse(req.uri.toString()).path;
          debugPrint('🔄 Handling 401 for path: $path');

          // refresh 자체 401은 재귀 방지
          if (path.startsWith(_refreshPath)) {
            debugPrint('🚫 Refresh endpoint 401 → forcing logout');
            await _forceLogout(navigatorKey.currentContext);
            return handler.next(e);
          }

          // 원 요청에 이미 Authorization 있었는지
          final hadAuth = (req.headers['Authorization'] ?? '')
              .toString()
              .startsWith('Bearer ');

          // Authorization 없던 401이면 한 번 주입 재시도
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

          // 여기부터 refresh 시도
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

            // 저장 갱신
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

  /// 액세스 토큰이 만료됐거나, `skew` 이내로 임박했는지 판정
  static bool _isAccessTokenExpiringSoon(String accessToken,
      {Duration skew = const Duration(minutes: 2)}) {
    try {
      final exp = _getJwtExpiry(accessToken);
      if (exp == null) return false; // exp 없는 토큰이면 판단 불가 → false
      final now = DateTime.now().toUtc();
      return exp.isBefore(now.add(skew));
    } catch (_) {
      return false;
    }
  }

  /// JWT exp(초) → DateTime(UTC)로 파싱
  static DateTime? _getJwtExpiry(String token) {
    // JWT 형식: header.payload.signature
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
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }
}
