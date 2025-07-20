import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import '../models/user.dart';
import '../utils/user_storage.dart';
import 'mp_challenge_list_screen.dart';
import 'mp_edit_screen.dart';
import 'mp_pwreset_screen.dart';
import 'test_main_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _name = '사용자';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString != null) {
      final userMap = jsonDecode(jsonString);
      final user = User.fromJson(userMap);
      setState(() {
        _name = user.name.isNotEmpty ? user.name : '사용자';
      });
    } else {
      setState(() {
        _name = '사용자';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user');

    // SharedPreference에 저장된 유저 정보 모두 삭제
    await UserStorage.clearUser();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '안녕하세요, ${_name ?? '사용자'}님!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            Text('개인정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('개인정보 수정'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MpEditScreen()),
                );
              },
              trailing: const Icon(Icons.chevron_right),
            ),
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

            Text('과거 챌린지', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('챌린지 관리'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MpChallengeListScreen()),
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



