import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});

  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  late String selectedMonth;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  List<String> _generateMonthList() {
    final now = DateTime.now();
    return List.generate(12, (index) {
      final date = DateTime(now.year, now.month + index);
      return "${date.year}-${date.month.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _saveBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final amount = int.tryParse(_amountController.text);
    if (amount == null) {
      _showDialog('숫자만 입력해주세요.');
      return;
    }

    await prefs.setInt('budget_$selectedMonth', amount);
    _showDialog('예산이 저장되었습니다!');
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final months = _generateMonthList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('이번달 예산 설정'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '예산 설정할 달을 선택하세요',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              items: months
                  .map((month) => DropdownMenuItem(
                value: month,
                child: Text(month),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '예산 금액을 입력해주세요.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '예: 500000',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBudget,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '예산 설정하기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}