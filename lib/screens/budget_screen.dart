import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../constants/api_endpoints/budget_api.dart';
import '../constants/api_endpoints/ml_api.dart';
import '../constants/api_endpoints/record_api.dart';
import '../models/record.dart';
import '../api/api_client.dart';
import 'budget_creating_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isLoading = true;
  int? _totalBudget;
  int? _totalSpending;
  late String _currentMonth;
  double? _predictedSpending;
  Map<int, int> _categoryBudgets = {};
  Map<int, int> _categorySpendings = {};
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
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final endOfMonth = DateTime.now().add(const Duration(days: 1));
    final budgetMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);

    try {
      // 1️⃣ 예산 데이터 조회
      final budgetRes = await ApiClient.dio.get(
        BudgetApi.me,
        queryParameters: {'budgetMonth': budgetMonthStr},
      );

      print("💡 _loadData() 호출 - budgetMonth: $budgetMonthStr");
      print("💡 GET BudgetApi.me 응답 상태: ${budgetRes.statusCode}");
      print("💡 응답 데이터 전체: ${budgetRes.data}");

      final body = budgetRes.data;
      final budgetData = body['data'] ?? {};

      if (budgetData == null || budgetData['categoryBudget'] == null) {
        setState(() {
          _totalBudget = null;
          _categoryBudgets = {};
          _totalSpending = null;
          _categorySpendings = {};
          _predictedSpending = null;
          _isLoading = false;
        });
        return;
      }

      // 2️⃣ 예산 데이터 가공
      final int totalAmount = budgetData['totalAmount'] ?? 0;
      final List categoryList = budgetData['categoryBudget'];
      final Map<int, int> categoryBudgets = {
        for (var item in categoryList)
          (item['spendCategoryId'] as int): (item['amount'] as int),
      };
      print("💡 totalAmount: $totalAmount");
      print("💡 categoryBudget 리스트: $categoryList");

      // 3️⃣ 소비 기록 조회
      List<Record> records = await fetchRecordsInRange(startOfMonth, endOfMonth);
      Map<int, int> categorySpendings = {};
      int totalSpending = 0;
      for (var record in records) {
        final catId = record.spend_category;
        final amount = record.spendCost;
        categorySpendings[catId] = (categorySpendings[catId] ?? 0) + amount;
        totalSpending += amount;
      }
      print("💡 totalSpending: $totalSpending");
      print("💡 categorySpendings: $categorySpendings");

      // 4️⃣ ML 예측 지출 조회 (실패해도 무시)
      double? prediction;
      try {
        final response = await ApiClient.dio.get(MlApi.predictBudget);
        final data = response.data['data'];
        final String predictionStr = data['예측'];
        final numericString = predictionStr.replaceAll(RegExp(r'[^0-9]'), '');
        prediction = double.tryParse(numericString);
        print("💡 ML 예측 지출: $prediction");
      } catch (e) {
        print("⚠️ 예측 지출 가져오기 실패: $e");
        prediction = null;
      }

      // 5️⃣ 화면에 상태 반영
      if (mounted) {
        setState(() {
          _totalBudget = totalAmount;
          _categoryBudgets = categoryBudgets;
          _totalSpending = totalSpending;
          _categorySpendings = categorySpendings;
          _predictedSpending = prediction;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ _loadData() 예외 발생: $e");
      setState(() {
        _totalBudget = null;
        _categoryBudgets = {};
        _totalSpending = null;
        _categorySpendings = {};
        _predictedSpending = null;
        _isLoading = false;
      });
    }
  }

  Future<List<Record>> fetchRecordsInRange(DateTime start, DateTime end) async {
    final dio = ApiClient.dio;
    try {
      final res = await dio.get(RecordApi.list, queryParameters: {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다.')),
      );
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
    // 로딩 상태 분기 처리
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _totalBudget == null
          ? LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          double baseFontSize;
          double horizontalPadding;

          if (width < 350) {
            baseFontSize = 12;
            horizontalPadding = 16;
          } else if (width < 600) {
            baseFontSize = 14;
            horizontalPadding = 24;
          } else {
            baseFontSize = 18;
            horizontalPadding = 32;
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BudgetCreatingScreen()),
                  ).then((value) {
                    if (value == true) _loadData();
                  });
                },
                child: Text(
                  '이번달 예산 설정하기',
                  style: TextStyle(fontSize: baseFontSize),
                ),
              ),
            ),
          );
        },
      )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            double baseFontSize;
            double basePadding;
            double circleRadius;
            double circleLineWidth;
            double trailingIconSize;

            if (width < 350) {
              baseFontSize = 12;
              basePadding = 8;
              circleRadius = 80;
              circleLineWidth = 14;
              trailingIconSize = 12;
            } else if (width < 600) {
              baseFontSize = 14;
              basePadding = 16;
              circleRadius = 120;
              circleLineWidth = 20;
              trailingIconSize = 16;
            } else {
              baseFontSize = 18;
              basePadding = 24;
              circleRadius = 150;
              circleLineWidth = 24;
              trailingIconSize = 20;
            }

            final spendingPercent = (_totalBudget != null &&
                _totalSpending != null &&
                _totalBudget! > 0)
                ? (_totalSpending! / _totalBudget!)
                : 0.0;

            final allCatIds = _categoryNames.keys.toList()..sort();

            String formatNumber(int num) {
              return num.toString().replaceAllMapped(
                  RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(basePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (_totalBudget != null && _totalSpending != null)
                        ? '이번 달 예산입니다.'
                        : '예산을 설정하고\n소비를 관리해보세요',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: baseFontSize + 8,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (_totalBudget != null && _totalSpending != null)
                    Padding(
                      padding: EdgeInsets.only(top: 4.0, left: 4.0),
                      child: Text(
                        '${DateTime.now().year}.${DateTime.now().month.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: baseFontSize,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  SizedBox(height: basePadding),
                  if (_totalBudget != null && _totalSpending != null) ...[
                    Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        '이번달 예산은 ${formatNumber(_totalBudget!)}원\n총 ${formatNumber(_totalSpending!)}원을 소비했어요.',
                        style: TextStyle(fontSize: baseFontSize),
                      ),
                    ),
                    SizedBox(height: basePadding * 1.25),
                    Center(
                      child: CircularPercentIndicator(
                        radius: circleRadius,
                        lineWidth: circleLineWidth,
                        percent: spendingPercent > 1.0 ? 1.0 : spendingPercent,
                        center: Text(
                          "${(spendingPercent * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize + 2,
                          ),
                        ),
                        progressColor: spendingPercent > 1.0
                            ? Colors.orangeAccent
                            : Colors.green,
                        backgroundColor: Colors.grey.shade300,
                        animation: true,
                        animationDuration: 600,
                      ),
                    ),
                    SizedBox(height: basePadding * 1.5),
                    Center(
                      child: Text(
                        _feedbackMessage(),
                        style: TextStyle(
                          fontSize: baseFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (_predictedSpending != null) ...[
                      SizedBox(height: basePadding / 2),
                      Center(
                        child: Text(
                          '다음주 지출은 ${formatNumber(_predictedSpending!.round())}원으로 예상됩니다.',
                          style: TextStyle(
                            fontSize: baseFontSize - 2,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(height: basePadding / 2),
                      Center(
                        child: Text(
                          '다음주 지출 예측 정보가 아직 생성되지 않았어요.',
                          style: TextStyle(
                            fontSize: baseFontSize - 2,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: basePadding * 2),
                    ...allCatIds.map((catId) {
                      final catBudget = _categoryBudgets[catId] ?? 0;
                      final catSpending = _categorySpendings[catId] ?? 0;
                      final catPercent = catBudget > 0
                          ? (catSpending / catBudget)
                          : (catSpending > 0 ? 1.0 : 0.0);

                      final catColor = (catPercent >= 1.0 ||
                          (catBudget == 0 && catSpending > 0))
                          ? Colors.orange[700]!
                          : Colors.green.withOpacity(catPercent.clamp(0.5, 1.0));

                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              _categoryNames[catId] ?? '카테고리 $catId',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: baseFontSize,
                              ),
                            ),
                            subtitle: Text(
                              '예산: ${formatNumber(catBudget)}원, 사용: ${formatNumber(catSpending)}원',
                              style: TextStyle(fontSize: baseFontSize - 2),
                            ),
                            trailing: CircularPercentIndicator(
                              radius: trailingIconSize,
                              lineWidth: 3,
                              percent: catPercent.clamp(0.0, 1.0),
                              progressColor: catColor,
                              backgroundColor: Colors.grey.shade300,
                              animation: true,
                            ),
                          ),
                          Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}