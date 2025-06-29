import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  void _loadUserName() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _userName = user?.displayName ?? '사용자';
    });
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
              '안녕하세요, ${_userName ?? ''}님!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 개인정보 수정 섹션
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

            // 과거 챌린지 관리 섹션
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

            // 로그아웃 버튼
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
