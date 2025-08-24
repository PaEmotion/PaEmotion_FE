import 'package:flutter/material.dart';

class MpChallengeListScreen extends StatelessWidget {
  const MpChallengeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('과거 챌린지 관리'),
      ),
      body: Center(
        child: Text(
          '과거 챌린지 관리 화면입니다.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
