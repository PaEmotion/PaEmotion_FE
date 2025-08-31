import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../repository/user_repository.dart';
import '../utils/secure_user_storage.dart';
import '../utils/user_storage.dart';

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
    await _repo.persistUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;

    // UserRepository 내부 클리어
    await _repo.clear();

    // ️SharedPreferences 전체 삭제
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    await prefs.clear();
    await prefs.setBool('seenOnboarding', seenOnboarding);

    // Notify
    notifyListeners();
  }
}
