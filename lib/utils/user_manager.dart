import '../models/user.dart';
import '../repository/user_repository.dart';
import '../utils/secure_user_storage.dart';
import 'package:flutter/foundation.dart';

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal() {
    _repo = UserRepository(secureStorage: SecureUserStorage());
  }

  late final UserRepository _repo;
  User? _user;

  User? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    _user = await _repo.loadUser();
    notifyListeners();
  }

  Future<void> setUser(User user) async {
    _user = user;
    await _repo.persistUser(user);
    notifyListeners();
  }

  Future<void> updateAccessToken(String newAccessToken) async {
    if (_user == null) return;
    _user = _user!.copyWith(accessToken: newAccessToken);
    // 저장 (토큰만 갱신)
    await _repo.persistUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await _repo.clear();
    notifyListeners();
  }
}
