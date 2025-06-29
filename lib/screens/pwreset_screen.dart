import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PwResetScreen extends StatefulWidget {
  const PwResetScreen({super.key});

  @override
  State<PwResetScreen> createState() => _PwResetScreenState();
}

class _PwResetScreenState extends State<PwResetScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendPasswordResetEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 재설정 이메일을 보냈습니다.')),
        );
        Navigator.pop(context); // 다시 로그인 화면으로 돌아가기
      } on FirebaseAuthException catch (e) {
        String message = '에러가 발생했습니다.';
        if (e.code == 'user-not-found') {
          message = '등록된 이메일이 없습니다.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일 입력',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value != null && value.contains('@')
                    ? null
                    : '올바른 이메일을 입력하세요',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendPasswordResetEmail,
                  child: const Text('재설정 이메일 보내기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}