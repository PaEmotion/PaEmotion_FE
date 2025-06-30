import 'package:flutter/material.dart';

class MpPwResetScreen extends StatefulWidget {
  const MpPwResetScreen({super.key});

  @override
  State<MpPwResetScreen> createState() => _MpPwResetScreenState();
}

class _MpPwResetScreenState extends State<MpPwResetScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: const Center(
        child: Text(
          '비밀번호 변경 화면입니다',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

