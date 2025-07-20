import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../utils/budget_storage.dart';
import '../utils/record_storage.dart';
import '../models/budget.dart';
import '../models/user.dart';
import '../api/api_client.dart';

import 'budget_ai_screen.dart';
import 'budget_edit_screen.dart';
import 'budget_creating_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int? _totalBudget;
  int? _totalSpending;
  late String _currentMonth;
  double? _predictedSpending;

  Map<String, int> _categoryBudgets = {};
  Map<String, int> _categorySpendings = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    _loadData();
  }

  Future<void> _loadData() async {
    final budgets = await BudgetStorage.loadBudgets(_currentMonth);
    int totalBudget = 0;
    Map<String, int> categoryBudgets = {};
    for (var b in budgets) {
      totalBudget += b.amount;
      categoryBudgets[b.category] = b.amount;
    }

    final totalSpending = await RecordStorage.getMonthlySpending(_currentMonth);
    Map<String, int> categorySpendings = {};
    for (var category in categoryBudgets.keys) {
      final spending = await RecordStorage.getCategorySpending(_currentMonth, category);
      categorySpendings[category] = spending;
    }

    // 사용자 ID 불러오고 예측 요청
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user');
      if (jsonString != null) {
        final userMap = jsonDecode(jsonString);
        final user = User.fromJson(userMap);

        final response = await ApiClient.dio.get('/ml/predict/${user.id}');
        final prediction = response.data['예측'][0];
        if (mounted) {
          setState(() {
            _predictedSpending = prediction;
          });
        }
      }
    } catch (e) {
      debugPrint("예측 API 실패: $e");
    }

    if (mounted) {
      setState(() {
        _totalBudget = totalBudget == 0 ? null : totalBudget;
        _totalSpending = totalSpending;
        _categoryBudgets = categoryBudgets;
        _categorySpendings = categorySpendings;
      });
    }
  }

  String _feedbackMessage() {
    if (_totalBudget == null || _totalSpending == null) return '';
    final percent = _totalSpending! / _totalBudget!;
    if (percent < 0.5) return '아직 넉넉해요 😊 계획적인 소비 아주 좋아요!';
    if (percent < 0.8) return '조금만 더 신경 써볼까요? 😌 아직 괜찮아요!';
    if (percent <= 1.0) return '예산이 거의 다 닳았어요! ⚠️ 살짝 조심해볼까요?';
    return '예산 초과! 😱 다음 달엔 더 잘해볼 수 있어요!';
  }

  @override
  Widget build(BuildContext context) {
    final spendingPercent = (_totalBudget != null &&
        _totalSpending != null &&
        _totalBudget! > 0)
        ? (_totalSpending! / _totalBudget!)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (_totalBudget != null && _totalSpending != null)
                    ? '이번 달 예산입니다.'
                    : '예산을 설정하고\n소비를 관리해보세요',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_totalBudget != null && _totalSpending != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                  child: Text(
                    '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (_totalBudget != null && _totalSpending != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    '이번달 예산은 ${_totalBudget!.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]},',
                    )}원\n총 ${_totalSpending!.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                          (m) => '${m[1]},',
                    )}원을 소비했어요.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 20),
                if (_categoryBudgets.isNotEmpty)
                  ..._categoryBudgets.entries.map((entry) {
                    final category = entry.key;
                    final catBudget = entry.value;
                    final catSpending = _categorySpendings[category] ?? 0;
                    final catPercent = catBudget > 0
                        ? (catSpending / catBudget)
                        : 0.0;

                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '예산: ${catBudget.toString().replaceAllMapped(
                              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]},',
                            )}원, 사용: ${catSpending.toString().replaceAllMapped(
                              RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                                  (m) => '${m[1]},',
                            )}원',
                          ),
                          trailing: CircularPercentIndicator(
                            radius: 16,
                            lineWidth: 3,
                            percent: catPercent > 1.0 ? 1.0 : catPercent,
                            progressColor: catPercent > 1.0 ? Colors.orangeAccent : Colors.green,
                            backgroundColor: Colors.grey.shade300,
                            animation: true,
                          ),
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                const SizedBox(height: 20),
                Center(
                  child: CircularPercentIndicator(
                    radius: 120,
                    lineWidth: 20,
                    percent: spendingPercent > 1.0 ? 1.0 : spendingPercent,
                    center: Text(
                      "${(spendingPercent * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    progressColor:
                    spendingPercent > 1.0 ? Colors.orangeAccent : Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    animation: true,
                    animationDuration: 600,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    _feedbackMessage(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
                if (_predictedSpending != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '다음주 지출은 ${_predictedSpending!.round().toString().replaceAllMapped(
                        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
                            (m) => '${m[1]},',
                      )}원으로 예상됩니다.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetAiScreen(),
                        ),
                      ).then((value) {
                        if (value == true) {
                          _loadData();
                        }
                      });
                    },
                    child: const Text(
                      '예산 사용 분석 보러가기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetEditScreen()),
                      ).then((value) {
                        if (value == true) _loadData();
                      });
                    },
                    child: const Text(
                      '예산 수정하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
              if (_totalBudget == null) ...[
                const SizedBox(height: 450),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetAiScreen(),
                        ),
                      ).then((value) {
                        if (value == true) {
                          _loadData();
                        }
                      });
                    },
                    child: const Text(
                      'AI에게 예산 설정 도움받기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetCreatingScreen()),
                      ).then((value) {
                        if (value == true) _loadData();
                      });
                    },
                    child: const Text(
                      '이번달 예산 설정하기',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


