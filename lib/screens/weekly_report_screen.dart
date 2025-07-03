import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final List<String> availableWeeks = [
    // 임시 더미 데이터
    '2025-06 1주차',
    '2025-06 2주차',
    '2025-06 3주차',
    '2025-06 4주차',
    '2025-06 5주차',
  ];

  late int currentPageIndex;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    currentPageIndex = availableWeeks.length - 1; // 현재달 - 1 = 저번달
    _pageController = PageController(initialPage: currentPageIndex);
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
          '주간 리포트',
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
            padding: const EdgeInsets.only(left: 20, right: 16, top: 12, bottom: 8),
            child: DropdownButton<String>(
              value: availableWeeks[currentPageIndex],
              items: availableWeeks.map((week) {
                return DropdownMenuItem<String>(
                  value: week,
                  child: Text(
                    '$week 리포트',
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (selected) {
                if (selected == null) return;
                final newIndex = availableWeeks.indexOf(selected);
                if (newIndex != -1) {
                  setState(() {
                    currentPageIndex = newIndex;
                  });
                  _pageController?.jumpToPage(newIndex);
                }
              },
            ),
          ),

          // 리포트 페이지
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: availableWeeks.length,
              onPageChanged: (index) {
                setState(() {
                  currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final week = availableWeeks[index];
                return WeeklyReportPage(week: week);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyReportPage extends StatelessWidget {
  final String week;
  const WeeklyReportPage({super.key, required this.week});

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
              '$week 소비 리포트',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 50,
                      color: Colors.purple,
                      title: '외식',
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: Colors.teal,
                      title: '쇼핑',
                    ),
                    PieChartSectionData(
                      value: 20,
                      color: Colors.amber,
                      title: '교통',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              // 임시 더미 데이터
              '이번 주에는 외식 지출이 많았습니다.\n'
                  'AI는 스트레스로 인한 즉흥적 소비 가능성을 지적합니다.\n'
                  '다음 주에는 계획 소비를 시도해보세요.',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}