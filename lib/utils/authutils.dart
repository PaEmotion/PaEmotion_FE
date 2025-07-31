import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';
import 'user_storage.dart';
import 'user_manager.dart';

class AuthUtils {
  static int? getExpiryTimestampFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded);

      if (payloadMap is Map<String, dynamic> && payloadMap.containsKey('exp')) {
        return payloadMap['exp'];
      }
    } catch (_) {}

    return null;
  }

  // 토큰 만료 여부 확인 (현재시간과 비교)
  static bool isTokenExpired(String token) {
    final exp = getExpiryTimestampFromJwt(token);
    if (exp == null) return true;

    final expiryDate =
    DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    return DateTime.now().toUtc().isAfter(expiryDate);
  }
}

class TokenCheckerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onLogout;

  const TokenCheckerWidget({required this.child, required this.onLogout, Key? key})
      : super(key: key);

  @override
  State<TokenCheckerWidget> createState() => _TokenCheckerWidgetState();
}

class _TokenCheckerWidgetState extends State<TokenCheckerWidget> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString == null) return;

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final token = user.accessToken;

    if (token == null || AuthUtils.isTokenExpired(token)) {
      // accessToken 만료 => refresh 시도
      try {
        final response = await ApiClient.dio.post(
          '/users/token/refresh',
          data: {
            'refresh_token': user.refreshToken,
          },
        );
        print("aceestoken 발급상태: $response");
        final newAccessToken = response.data['access_token'];
        final updatedUser = User(
          id: user.id,
          email: user.email,
          name: user.name,
          nickname: user.nickname,
          accessToken: newAccessToken,
          refreshToken: user.refreshToken,
        );
        await UserManager().setUser(updatedUser);


      } catch (e) {
        // refreshToken도 만료된 경우 => 로그아웃
        await prefs.clear();
        await UserStorage.clearUser();
        widget.onLogout();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
