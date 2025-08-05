import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    _loadLastMonthSpendingFromApi();
  }

  String _getLastMonth() {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1);
    return '${lastMonthDate.year}-${lastMonthDate.month.toString().padLeft(2, '0')}';
  }

  Future<void> _loadLastMonthSpendingFromApi() async {
    final dio = ApiClient.dio;
    final lastMonthStr = '${_getLastMonth()}-01';

    try {
      final response = await dio.get(
        '/budgets/lastspent/me',
        queryParameters: {'lastMonth': lastMonthStr},
      );

      if (response.statusCode == 200) {
        final json = response.data;
        if (json['success'] == true && json['data'] != null) {
          final data = json['data'];

          Map<String, int> totals = {};
          if (data['categorySpent'] != null) {
            for (final item in data['categorySpent']) {
              final int spendCategoryId = item['spendCategoryId'];
              final int spent = item['spent'];
              if (spendCategoryId > 0 &&
                  spendCategoryId <= allCategories.length) {
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
          debugPrint('API 응답 성공이지만 데이터가 없습니다: ${json['message']}');
        }
      } else {
        debugPrint('지난달 소비 API 실패: 상태코드 ${response.statusCode}');
        debugPrint('에러 메시지: ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint('API 에러: 상태코드 ${e.response!.statusCode}');
        debugPrint('에러 응답 데이터: ${e.response!.data}');
      } else {
        debugPrint('API 호출 중 오류: $e');
      }
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
        '/budgets/create',
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

  double responsiveWidth(BuildContext context, double w) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth * (w / 375);
  }

  double responsiveHeight(BuildContext context, double h) {
    final screenHeight = MediaQuery.of(context).size.height;
    return screenHeight * (h / 812);
  }

  double responsiveFont(BuildContext context, double size) {
    final scale = MediaQuery.of(context).textScaleFactor;
    return size * scale;
  }

  @override
  Widget build(BuildContext context) {
    final selected = budgetItems.map((e) => e['category'] as String).toSet();
    final available = allCategories.where((c) => !selected.contains(c)).toList();

    final horizontalPadding = responsiveWidth(context, 20);
    final verticalSpacing = responsiveHeight(context, 12);
    final iconSize = responsiveWidth(context, 22);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '예산 설정하기',
          style: TextStyle(fontSize: responsiveFont(context, 18), fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (budgetItems.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: verticalSpacing),
                child: Center(
                  child: Text(
                    '카테고리를 추가하여 예산을 입력하세요.',
                    style: TextStyle(fontSize: responsiveFont(context, 14)),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: budgetItems.length,
                itemBuilder: (context, index) {
                  final item = budgetItems[index];
                  final category = (item['category'] ?? '') as String;
                  final controller = item['controller'] as TextEditingController;

                  return Padding(
                    padding: EdgeInsets.only(bottom: verticalSpacing),
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
                                  child: Text(
                                    c,
                                    style: TextStyle(fontSize: responsiveFont(context, 14)),
                                  ),
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
                            SizedBox(width: responsiveWidth(context, 12)),
                            Expanded(
                              flex: 4,
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  hintText: '예산을 입력해주세요.',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: responsiveHeight(context, 10),
                                    horizontal: responsiveWidth(context, 12),
                                  ),
                                  border: InputBorder.none,
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                ),
                                style: TextStyle(fontSize: responsiveFont(context, 14)),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SizedBox(width: responsiveWidth(context, 8)),
                            Expanded(
                              flex: 1,
                              child: IconButton(
                                iconSize: iconSize,
                                icon: const Icon(Icons.delete, color: Color(0xFFEF9A9A)),
                                onPressed: () => _removeBudgetItem(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: responsiveHeight(context, 4), left: responsiveWidth(context, 4)),
                          child: Text(
                            lastMonthTotals.containsKey(category)
                                ? '지난달 $category에 사용한 금액: ${numberFormat.format(lastMonthTotals[category])}원'
                                : '지난달 $category에 사용한 금액이 없습니다.',
                            style: TextStyle(
                              fontSize: responsiveFont(context, 12),
                              color: Colors.grey,
                            ),
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
                  icon: Icon(Icons.add, size: responsiveWidth(context, 18)),
                  label: Text(
                    '카테고리 추가',
                    style: TextStyle(fontSize: responsiveFont(context, 14)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey, width: 1.5),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      vertical: responsiveHeight(context, 12),
                      horizontal: responsiveWidth(context, 16),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(responsiveWidth(context, 6)),
                    ),
                  ),
                ),
              ),
            SizedBox(height: responsiveHeight(context, 14)),
            Text(
              "총 예산: ${numberFormat.format(totalBudget)}원",
              style: TextStyle(
                fontSize: responsiveFont(context, 16),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsiveHeight(context, 6)),
            Text(
              '지난달 총 소비금액: ${numberFormat.format(lastMonthTotalSpent)}원',
              style: TextStyle(fontSize: responsiveFont(context, 13), color: Colors.grey),
            ),
            Divider(height: responsiveHeight(context, 24)),
            Padding(
              padding: EdgeInsets.only(bottom: responsiveHeight(context, 6)),
              child: Text(
                '예산 설정 전에 한 번 더 확인해주세요. 설정 후에는 수정이 제한돼요.',
                style: TextStyle(fontSize: responsiveFont(context, 12), color: Colors.black54),
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
                  padding: EdgeInsets.symmetric(vertical: responsiveHeight(context, 16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(responsiveWidth(context, 8)),
                  ),
                  textStyle: TextStyle(fontSize: responsiveFont(context, 16)),
                ),
                child: const Text('예산 저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}