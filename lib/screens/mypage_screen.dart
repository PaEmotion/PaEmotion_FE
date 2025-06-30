import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'mp_edit_screen.dart';
import 'mp_pwreset_screen.dart';
import 'mp_challenge_list_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _name;
  String? _nickname;
  String? _email;
  bool _isLoading = true;
  String? _error;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://your-api.com',
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          _error = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        setState(() {
          _name = data['name'];
          _nickname = data['nickname'];
          _email = data['email'];
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = '인증 실패. 다시 로그인 해주세요.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '사용자 정보를 불러오는데 실패했습니다.';
          _isLoading = false;
        });
      }
    } on DioError catch (e) {
      if (e.response?.statusCode == 401) {
        setState(() {
          _error = '인증 실패. 다시 로그인 해주세요.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '오류가 발생했습니다: ${e.message}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    // 필요하면 refresh_token 등도 삭제

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserInfo,
                child: const Text('다시 시도'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('로그인 화면으로 이동'),
              )
            ],
          ),
        ),
      );
    }

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
            Text('닉네임: ${_nickname ?? '-'}', style: const TextStyle(fontSize: 18)),
            Text('이메일: ${_email ?? '-'}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
