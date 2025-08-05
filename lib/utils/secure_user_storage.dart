import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureUserStorage {
  // 내부적으로 암호화하여 저장하는 플러터 시큐어 스토리지 이용
  static const _accessTokenKey = 'secure_access_token';
  static const _refreshTokenKey = 'secure_refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> loadAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> loadRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
