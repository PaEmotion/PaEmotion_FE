import 'package:flutter/material.dart';

class PwResetScreen extends StatefulWidget {
  const PwResetScreen({super.key});

  @override
  State<PwResetScreen> createState() => _PwResetScreenState();
}

class _PwResetScreenState extends State<PwResetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: const Center(
        child: Text(
          '비밀번호 변경 화면입니다',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
