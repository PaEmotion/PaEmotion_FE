import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final List<String> availableMonths = [
    // 임시 더미 데이터
    '2025-01',
    '2025-02',
    '2025-03',
  ];

  late int currentPageIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final defaultMonth = DateTime(now.year, now.month - 1);
    final defaultMonthStr =
        '${defaultMonth.year.toString().padLeft(4, '0')}-${defaultMonth.month.toString().padLeft(2, '0')}';

    currentPageIndex = availableMonths.indexOf(defaultMonthStr);
    if (currentPageIndex == -1) {
      currentPageIndex = availableMonths.length - 1;
    }

    _pageController = PageController(initialPage: currentPageIndex); // 초기화
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '월간 리포트',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
            const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 8),
            child: DropdownButton<String>(
              value: availableMonths[currentPageIndex],
              isExpanded: false,
              items: availableMonths.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(
                    '$month 리포트',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected == null) return;
                final newIndex = availableMonths.indexOf(selected);
                if (newIndex != -1) {
                  setState(() {
                    currentPageIndex = newIndex;
                  });
                  _pageController?.jumpToPage(newIndex);
                }
              },
            ),
          ),

          // 리포트 페이지 뷰
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: availableMonths.length,
              onPageChanged: (index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final month = availableMonths[index];
                return MonthlyReportPage(month: month);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyReportPage extends StatelessWidget {
  final String month;
  const MonthlyReportPage({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month 소비 리포트',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 40,
                      color: Colors.blue,
                      title: '식비',
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: Colors.orange,
                      title: '쇼핑',
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: Colors.green,
                      title: '교통',
                    ),
                    PieChartSectionData(
                      value: 10,
                      color: Colors.red,
                      title: '기타',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 임시 더미 데이터
            const Text(
              '이번 달에는 식비 지출이 전체의 40%를 차지했습니다.\n'
                  'AI는 스트레스 해소를 위한 과소비 가능성을 지적했습니다.\n'
                  '다음 달에는 소비 습관을 조정해보세요.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
