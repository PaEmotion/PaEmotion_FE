import 'package:flutter/material.dart';

class MpEditScreen extends StatelessWidget {
  const MpEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보 수정'),
      ),
      body: Center(
        child: Text(
          '개인정보 수정 화면입니다.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
