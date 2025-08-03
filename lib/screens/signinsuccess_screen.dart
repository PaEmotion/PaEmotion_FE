import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignInSuccessScreen extends StatelessWidget {
  const SignInSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 완료')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '회원가입이 완료되었습니다!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // 로그인 화면으로 돌아가기
                },
                child: const Text('로그인 하러 가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
