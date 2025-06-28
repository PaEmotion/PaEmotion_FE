import 'package:flutter/material.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '예산 설정 및 관리 화면',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
