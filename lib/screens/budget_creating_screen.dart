import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/budget.dart';
import '../models/record.dart';
import '../utils/budget_storage.dart';
import '../utils/record_storage.dart';

class BudgetCreatingScreen extends StatefulWidget {
  const BudgetCreatingScreen({super.key});

  @override
  State<BudgetCreatingScreen> createState() => _BudgetCreatingScreenState();
}

class _BudgetCreatingScreenState extends State<BudgetCreatingScreen> {
  final String currentMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  final List<String> allCategories = [
    '쇼핑', '배달음식', '외식', '카페', '취미',
    '뷰티', '건강', '자기계발', '선물', '여행', '모임'
  ];

  List<Map<String, Object>> budgetItems = [];
  Map<String, int> lastMonthTotals = {};

  final NumberFormat numberFormat = NumberFormat('#,###');

  int get totalBudget {
    int sum = 0;
    for (final item in budgetItems) {
      final controller = item['controller'] as TextEditingController;
      final value = int.tryParse(controller.text) ?? 0;
      sum += value;
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    _loadSavedBudgets();
    _loadLastMonthSpending();
  }

  Future<void> _loadSavedBudgets() async {
    final savedBudgets = await BudgetStorage.loadBudgets(currentMonth);
    setState(() {
      budgetItems = savedBudgets.map((b) => <String, Object>{
        'category': b.category,
        'controller': TextEditingController(text: b.amount.toString()),
      }).toList();
    });
  }

  String _getLastMonth() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);
    return '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';
  }

  // 카테고리 int + 1 해서 불러오는 코드
  Future<void> _loadLastMonthSpending() async {
    final records = await RecordStorage.loadRecords();
    final lastMonth = _getLastMonth();

    final Map<String, int> totals = {};
    for (var record in records) {
      if (record.spendDate.startsWith(lastMonth)) {
        final int categoryId = record.spend_category;
        if (categoryId > 0 && categoryId <= allCategories.length) {
          final String categoryName = allCategories[categoryId - 1];
          totals[categoryName] = (totals[categoryName] ?? 0) + record.spendCost;
        }
      }
    }

    setState(() {
      lastMonthTotals = totals;
    });
  }


  void _addBudgetItem() {
    final selected = budgetItems.map((e) => e['category'] as String).toSet();
    final available = allCategories.where((c) => !selected.contains(c)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('더 이상 추가할 수 있는 카테고리가 없습니다.')),
      );
      return;
    }

    setState(() {
      budgetItems.add({
        'category': available.first,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeBudgetItem(int index) {
    setState(() {
      (budgetItems[index]['controller'] as TextEditingController).dispose();
      budgetItems.removeAt(index);
    });
  }

  Future<void> _saveBudgets() async {
    for (final item in budgetItems) {
      final controller = item['controller'] as TextEditingController;
      final amount = int.tryParse(controller.text) ?? 0;
      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('0원 이상의 예산을 입력해주세요.')),
        );
        return;
      }
    }

    for (final item in budgetItems) {
      final category = item['category'] as String;
      final amount = int.parse((item['controller'] as TextEditingController).text);
      final budget = Budget(month: currentMonth, category: category, amount: amount);
      await BudgetStorage.saveBudget(budget);
    }

    _showDialog('예산이 저장되었습니다!');
  }

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final item in budgetItems) {
      (item['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = budgetItems.map((e) => e['category'] as String).toSet();
    final available = allCategories.where((c) => !selected.contains(c)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('예산 설정하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (budgetItems.isEmpty)
              const Center(
                child: Text('카테고리를 추가하여 예산을 입력하세요.'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: budgetItems.length,
                itemBuilder: (context, index) {
                  final item = budgetItems[index];
                  final category = item['category'] as String;
                  final controller = item['controller'] as TextEditingController;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButton<String>(
                                value: category,
                                isExpanded: true,
                                items: allCategories
                                    .where((c) => c == category || !selected.contains(c))
                                    .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                                    .toList(),
                                onChanged: (newCategory) {
                                  if (newCategory == null) return;
                                  if (selected.contains(newCategory) && newCategory != category) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$newCategory 는 이미 선택된 카테고리입니다.')),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    item['category'] = newCategory;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  hintText: '예산을 입력해주세요.',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: Color(0xFFF5F5F5),
                                ),
                                style: const TextStyle(fontSize: 14),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Color(0xFFEF9A9A)),
                                onPressed: () => _removeBudgetItem(index),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 4),
                          child: Text(
                            lastMonthTotals.containsKey(category)
                                ? '지난달 $category에 사용한 금액: ${numberFormat.format(lastMonthTotals[category])}원'
                                : '지난달 $category에 사용한 금액이 없습니다.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (available.isNotEmpty)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _addBudgetItem,
                  icon: const Icon(Icons.add),
                  label: const Text('카테고리 추가'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1.5),
                    foregroundColor: Colors.black,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              "총 예산: ${numberFormat.format(totalBudget)}원",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveBudgets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('예산 저장하기', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

