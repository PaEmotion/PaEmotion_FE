import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  Future<bool> checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1)); // 로그인 상태 확인 모의 딜레이
    return false; // 로그인 안 된 상태로 가정 (나중에 SharedPreferences 등으로 교체)
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}