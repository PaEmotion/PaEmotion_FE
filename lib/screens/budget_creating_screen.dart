import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../api/api_client.dart';

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
  int lastMonthTotalSpent = 0;

  final NumberFormat numberFormat = NumberFormat('#,###');
  int? _userId;

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
    _loadUserAndLastMonthSpending();
  }

  Future<void> _loadUserAndLastMonthSpending() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString == null) return;

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    _userId = user.id;

    await _loadLastMonthSpendingFromApi();
  }

  String _getLastMonth() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);
    return '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadLastMonthSpendingFromApi() async {
    if (_userId == null) return;

    final dio = ApiClient.dio;
    final lastMonthStr = '${_getLastMonth()}-01';

    debugPrint('User ID: $_userId');
    debugPrint('Requesting last month spending for: $lastMonthStr');
    debugPrint('Full URL: ${dio.options.baseUrl}/budgets/lastspent/$_userId');

    try {
      final response = await dio.get(
        '/budgets/lastspent/$_userId',
        queryParameters: {'lastMonth': lastMonthStr},
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;

        Map<String, int> totals = {};
        if (data['categorySpent'] != null) {
          for (final item in data['categorySpent']) {
            final int spendCategoryId = item['spendCategoryId'];
            final int spent = item['spent'];
            if (spendCategoryId > 0 && spendCategoryId <= allCategories.length) {
              final String categoryName = allCategories[spendCategoryId - 1];
              totals[categoryName] = spent;
            }
          }
        }

        setState(() {
          lastMonthTotals = totals;
          lastMonthTotalSpent = data['totalSpent'] ?? 0;
        });
      } else {
        debugPrint('지난달 소비 API 실패: 상태코드 ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('지난달 소비 API 호출 중 오류: $e');
    }
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
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
      return;
    }

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

    final List<Map<String, dynamic>> categoryBudgetJson = budgetItems.map((item) {
      final categoryName = item['category'] as String;
      final spendCategoryId = allCategories.indexOf(categoryName) + 1;
      final amount = int.parse((item['controller'] as TextEditingController).text);
      return {
        'spendCategoryId': spendCategoryId,
        'amount': amount,
      };
    }).toList();

    final String budgetMonth = '$currentMonth-01';

    final requestBody = {
      'budgetMonth': budgetMonth,
      'categoryBudget': categoryBudgetJson,
    };

    try {
      final dio = ApiClient.dio;
      final response = await dio.post(
        '/budgets/create/$_userId',
        data: requestBody,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showDialog('예산이 성공적으로 저장되었습니다!');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('서버 전송 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 중 오류 발생: $e')),
      );
    }
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
                  final category = (item['category'] ?? '') as String;
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
            const SizedBox(height: 8),
            Text(
              '지난달 총 소비금액: ${numberFormat.format(lastMonthTotalSpent)}원',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const Divider(height: 20),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '예산 설정 전에 한 번 더 확인해주세요. 설정 후에는 수정이 제한돼요.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
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
