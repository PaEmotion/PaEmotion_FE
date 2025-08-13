import '../models/user.dart';
import '../utils/user_storage.dart';
import '../utils/secure_user_storage.dart';

class UserRepository {
  final SecureUserStorage secureStorage;

  UserRepository({required this.secureStorage});

  Future<void> persistUser(User user) async {
    // 프로필 정보와 access, refresh 토큰을 분리 저장
    await UserStorage.saveProfile(user);
    await secureStorage.saveTokens(
      accessToken: user.accessToken,
      refreshToken: user.refreshToken,
    );
  }

  Future<User?> loadUser() async {
    final profileJson = await UserStorage.loadProfileJson();
    if (profileJson == null) return null;

    final access = await secureStorage.loadAccessToken();
    final refresh = await secureStorage.loadRefreshToken();

    if (access == null || refresh == null) return null;

    return User.fromJson(profileJson, accessToken: access, refreshToken: refresh);
  }

  Future<void> clear() async {
    await UserStorage.clearProfile();
    await secureStorage.clear();
  }
}
