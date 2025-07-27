import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../models/user.dart';
import '../models/record.dart';
import '../api/api_client.dart';
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
  Map<int, int> _categoryBudgets = {}; // spendCategoryId -> amount
  Map<int, int> _categorySpendings = {}; // spendCategoryId -> actual spending
  Map<int, String> _categoryNames = {
    1: '쇼핑',
    2: '배달음식',
    3: '외식',
    4: '카페',
    5: '취미',
    6: '뷰티',
    7: '건강',
    8: '자기계발',
    9: '선물',
    10: '여행',
    11: '모임',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString == null) return;

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final userId = user.id;

    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final endOfMonth = DateTime.now().add(const Duration(days: 1)); // 내일까지 포함

    final budgetMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);

    try {
      // 1. 예산 데이터 조회
      final budgetRes = await ApiClient.dio.get(
        '/budgets/$userId',
        queryParameters: {'budgetMonth': budgetMonthStr},
      );
      final budgetData = budgetRes.data;

      if (budgetData == null || budgetData['categoryBudget'] == null) {
        setState(() {
          _totalBudget = null;
          _categoryBudgets = {};
          _totalSpending = null;
          _categorySpendings = {};
          _predictedSpending = null;
        });
        return;
      }

      final int totalAmount = budgetData['totalAmount'] ?? 0;
      final List categoryList = budgetData['categoryBudget'];

      // 예산 데이터가 있는 카테고리만 맵으로 저장
      final Map<int, int> categoryBudgets = {
        for (var item in categoryList)
          (item['spendCategoryId'] as int): (item['amount'] as int),
      };

      // 2. 현재 달 소비 기록 불러오기
      List<Record> records = await fetchRecordsInRange(startOfMonth, endOfMonth);

      // 3. 카테고리별 소비 합산
      Map<int, int> categorySpendings = {};
      int totalSpending = 0;

      for (var record in records) {
        final catId = record.spend_category;  // spendCategoryId
        final amount = record.spendCost;
        categorySpendings[catId] = (categorySpendings[catId] ?? 0) + amount;
        totalSpending += amount;
      }

      final response = await ApiClient.dio.get('/ml/predict/$userId');
      final predList = response.data['예측'];
      double? prediction;


      if (predList is List && predList.isNotEmpty) {
        prediction = predList[0].toDouble();
      } else {
        prediction = null;
      }


      if (mounted) {
        setState(() {
          _totalBudget = totalAmount;
          _categoryBudgets = categoryBudgets;
          _totalSpending = totalSpending;
          _categorySpendings = categorySpendings;
          _predictedSpending = prediction;
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
    }
  }

  Future<List<Record>> fetchRecordsInRange(DateTime start, DateTime end) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) throw Exception('로그인 정보 없음');
    final userMap = jsonDecode(userJson);
    final user = User.fromJson(userMap);
    final userId = user.id;
    final dio = ApiClient.dio;

    try {
      final res = await dio.get('/records/$userId', queryParameters: {
        'startDate': DateFormat('yyyy-MM-dd').format(start),
        'endDate': DateFormat('yyyy-MM-dd').format(end),
      });
      final data = res.data;
      if (data is List && data.isNotEmpty) {
        return data.map<Record>((e) => Record.fromJson(e)).toList();
      } else {
        return <Record>[];
      }
    } catch (e) {
      print('기록 불러오기 실패 ($start ~ $end): $e');
      return <Record>[];
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

    final allCatIds = _categoryNames.keys.toList()..sort();

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
                ] else ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '다음주 지출 예측 정보가 아직 생성되지 않았어요.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 모든 카테고리의 사용내역 표시 (예산 설정 안한 카테고리까지 표시)
                ...allCatIds.map((catId) {
                  final catBudget = _categoryBudgets[catId] ?? 0;
                  final catSpending = _categorySpendings[catId] ?? 0;
                  final catPercent = catBudget > 0
                      ? (catSpending / catBudget)
                      : (catSpending > 0 ? 1.0 : 0.0);

                  final catColor = (catPercent >= 1.0 || (catBudget == 0 && catSpending > 0))
                      ? Colors.orange[700]!
                      : Colors.green.withOpacity(catPercent.clamp(0.5, 1.0));


                  return Column(
                    children: [
                      ListTile(
                        title: Text(
                          _categoryNames[catId] ?? '카테고리 $catId',
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
                          percent: catPercent.clamp(0.0, 1.0),
                          progressColor: catColor,
                          backgroundColor: Colors.grey.shade300,
                          animation: true,
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                }).toList(),
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