import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/user_storage.dart';
import 'mp_edit_screen.dart';
import 'mp_pwreset_screen.dart';
import 'test_main_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _nickname = '사용자';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');

    if (jsonString == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final accessToken = user.accessToken;

    try {
      final dio = Dio();
      final response = await ApiClient.dio.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $accessToken'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final nicknameFromApi = data['nickname'] as String?;
        if (!mounted) return;
        setState(() {
          _nickname = (nicknameFromApi != null && nicknameFromApi.isNotEmpty) ? nicknameFromApi : _nickname;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    // 유저 데이터 및 토큰 클리어
    UserStorage.clearUser();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await UserStorage.clearUser();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임 영역
            Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _nickname ?? '사용자',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: '닉네임 수정',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MpEditScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            Text('개인정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('비밀번호 변경'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MpPwResetScreen()),
                );
              },
              trailing: const Icon(Icons.chevron_right),
            ),

            const Divider(height: 40),
            Text('기타', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.psychology_alt),
              title: const Text('소비성향 테스트'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestMainScreen()),
                );
              },
              trailing: const Icon(Icons.chevron_right),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

