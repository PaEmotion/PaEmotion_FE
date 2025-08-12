import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class UserStorage {
  static const _profileKey = 'user_profile';

  static Future<void> saveProfile(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final profileJson = jsonEncode(user.toJson(includeTokens: false));
    await prefs.setString(_profileKey, profileJson);
  }

  static Future<Map<String, dynamic>?> loadProfileJson() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey);
    if (jsonString == null) return null;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  static Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
