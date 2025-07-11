import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/record.dart';
import '../utils/record_storage.dart';

final Map<String, Color> categoryColors = {
  '쇼핑': Colors.purple[300]!,
  '배달음식': Colors.orange[400]!,
  '외식': Colors.deepOrange[400]!,
  '카페': Colors.brown[400]!,
  '취미': Colors.teal[300]!,
  '뷰티': Colors.pink[300]!,
  '건강': Colors.green[400]!,
  '자기계발': Colors.blue[300]!,
  '선물': Colors.amber[300]!,
  '여행': Colors.cyan[300]!,
  '모임': Colors.indigo[300]!,
};

final Map<String, Color> emotionColors = {
  '행복': Colors.amberAccent,
  '사랑': Colors.pinkAccent,
  '기대감': Colors.lightBlueAccent,
  '기회감': Colors.lightGreen,
  '슬픔': Colors.blueGrey,
  '우울': Colors.indigo,
  '분노': Colors.redAccent,
  '스트레스': Colors.deepPurpleAccent,
  '피로': Colors.brown,
  '불안': Colors.grey,
  '무료함': Colors.black26,
  '외로움': Colors.deepPurple,
};

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<Record> _allRecords = [];
  List<String> _availableMonths = [];
  String? _selectedMonth;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadRecords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await RecordStorage.loadRecords();
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(DateTime(now.year, now.month));

    final allMonths = records.map((r) {
      final dt = DateTime.parse(r.date);
      return DateFormat('yyyy-MM').format(DateTime(dt.year, dt.month));
    }).toSet().toList()
      ..sort();

    final filteredMonths = allMonths.where((m) => m != currentMonthStr).toList();
    final lastPageIndex = filteredMonths.isNotEmpty ? filteredMonths.length - 1 : 0;

    setState(() {
      _allRecords = records;
      _availableMonths = filteredMonths;
      _selectedMonth = filteredMonths.isNotEmpty ? filteredMonths.last : null;
      _pageController.dispose();
      _pageController = PageController(initialPage: lastPageIndex);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedMonth = _availableMonths[index];
    });
  }

  void _onDropdownChanged(String? newMonth) {
    if (newMonth == null) return;
    final newIndex = _availableMonths.indexOf(newMonth);
    if (newIndex != -1) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedMonth = newMonth;
      });
    }
  }

  List<Record> _recordsForMonth(String month) {
    return _allRecords.where((r) {
      final dt = DateTime.parse(r.date);
      final recordMonth = DateFormat('yyyy-MM').format(DateTime(dt.year, dt.month));
      return recordMonth == month;
    }).toList();
  }

  Map<String, int> _getCategoryTotals(List<Record> records) {
    final map = <String, int>{};
    for (var r in records) {
      map[r.category] = (map[r.category] ?? 0) + r.amount;
    }
    return map;
  }

  Map<String, int> _getEmotionCounts(List<Record> records) {
    final map = <String, int>{};
    for (var r in records) {
      map[r.emotion] = (map[r.emotion] ?? 0) + 1;
    }
    return map;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> dataMap, Map<String, Color> colorMap) {
    final total = dataMap.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];
    return dataMap.entries.map((entry) {
      final color = colorMap[entry.key] ?? Colors.grey;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: 40,
        title: '',
      );
    }).toList();
  }

  Widget _buildDetailList(String title, Map<String, int> dataMap, Map<String, Color> colorMap) {
    final totalSum = dataMap.values.fold(0, (a, b) => a + b).toDouble();
    final entries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final itemWidth = (constraints.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 8,
            children: entries.map((entry) {
              final color = colorMap[entry.key] ?? Colors.grey;
              final percent = totalSum > 0 ? (entry.value / totalSum) * 100 : 0;

              return Container(
                width: itemWidth,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${percent.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('월간 리포트', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _availableMonths.isEmpty
          ? const Center(child: Text('이전 달의 소비 기록이 없습니다.'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedMonth,
              items: _availableMonths.map((month) {
                final dt = DateFormat('yyyy-MM').parse(month);
                final formatted = DateFormat('yyyy년 M월').format(dt);
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text('$formatted 리포트'),
                );
              }).toList(),
              onChanged: _onDropdownChanged,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _availableMonths.length,
              reverse: false,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final month = _availableMonths[index];
                final records = _recordsForMonth(month);
                final categoryData = _getCategoryTotals(records);
                final emotionData = _getEmotionCounts(records);

                final dt = DateFormat('yyyy-MM').parse(month);
                final formattedMonth = DateFormat('yyyy년 M월').format(dt);

                final firstDay = DateTime(dt.year, dt.month, 1);
                final lastDay = DateTime(dt.year, dt.month + 1, 0);
                final formattedRange = '${DateFormat('yyyy.MM.dd').format(firstDay)} ~ ${DateFormat('yyyy.MM.dd').format(lastDay)}';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$formattedMonth 소비 리포트',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedRange,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: categoryData.isEmpty
                              ? const Center(child: Text('데이터 없음'))
                              : PieChart(
                            PieChartData(
                              sections: _buildPieSections(categoryData, categoryColors),
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailList('카테고리별 소비 내역', categoryData, categoryColors),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 200,
                          child: emotionData.isEmpty
                              ? const Center(child: Text('데이터 없음'))
                              : PieChart(
                            PieChartData(
                              sections: _buildPieSections(emotionData, emotionColors),
                              sectionsSpace: 2,
                              centerSpaceRadius: 60,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailList('감정별 소비 내역', emotionData, emotionColors),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




