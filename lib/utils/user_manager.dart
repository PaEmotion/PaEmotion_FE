import '../models/user.dart';
import 'user_storage.dart';

class UserManager {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  User? _user;

  Future<void> init() async {
    _user = await UserStorage.loadUser();
  }

  User? get currentUser => _user;

  bool get isLoggedIn => _user != null;

  Future<void> setUser(User user) async {
    _user = user;
    await UserStorage.saveUser(user);
  }

  Future<void> logout() async {
    _user = null;
    await UserStorage.clearUser();
  }
}
