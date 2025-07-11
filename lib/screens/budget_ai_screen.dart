import 'package:flutter/material.dart';

class BudgetAiScreen extends StatelessWidget {
  const BudgetAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예산 설정 도움 AI'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          '임시 화면입니다',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}