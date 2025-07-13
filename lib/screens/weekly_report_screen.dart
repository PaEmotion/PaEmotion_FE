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

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  List<Record> _allRecords = [];
  List<DateTime> _validWeeks = [];
  int _currentPageIndex = 0;
  bool _loading = true;
  final PageController _pageController = PageController();

  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecordsAndSetupWeeks();
  }

  Future<void> _loadRecordsAndSetupWeeks() async {
    final records = await RecordStorage.loadRecords();
    final currentMonday = _mondayOfWeek(_today);
    final weeksSet = <DateTime>{};

    for (final record in records) {
      final date = DateTime.parse(record.spendDate);
      final monday = _mondayOfWeek(date);
      if (monday.isBefore(currentMonday)) {
        weeksSet.add(monday);
      }
    }

    final sortedWeeks = weeksSet.toList()
      ..sort((a, b) => b.compareTo(a));

    setState(() {
      _allRecords = records;
      _validWeeks = sortedWeeks;
      _currentPageIndex = 0;
      _loading = false;
    });
  }

  DateTime _mondayOfWeek(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  List<Record> _recordsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    return _allRecords.where((r) {
      final date = DateTime.parse(r.spendDate);
      return !date.isBefore(weekStart) && date.isBefore(weekEnd);
    }).toList();
  }

  Map<String, int> _getCategoryTotals(List<Record> records) {
    final map = <String, int>{};
    for (var r in records) {
      map[r.category] = (map[r.category] ?? 0) + r.spendCost;
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

  String _formatWeekLabel(DateTime weekStart) {
    final thursday = weekStart.add(const Duration(days: 3));
    final targetMonth = thursday.month;
    final firstDayOfMonth = DateTime(thursday.year, targetMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    final diffDays = thursday.day + firstWeekday - 2;
    final weekOfMonth = (diffDays ~/ 7) + 1;
    return '${thursday.year}년 $targetMonth월 ${weekOfMonth}주차';
  }

  String _formatWeekRange(DateTime weekStart) {
    final formatter = DateFormat('yyyy.MM.dd');
    final end = weekStart.add(const Duration(days: 6));
    return '${formatter.format(weekStart)} ~ ${formatter.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_validWeeks.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('주간 리포트', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          centerTitle: true,
          elevation: 0,
        ),
        body: const Center(child: Text('지난 주간 소비 기록이 없습니다.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('주간 리포트', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<DateTime>(
              isExpanded: true,
              value: _validWeeks[_currentPageIndex],
              items: _validWeeks.map((week) {
                return DropdownMenuItem<DateTime>(
                  value: week,
                  child: Text(_formatWeekLabel(week)),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                final newIndex = _validWeeks.indexOf(val);
                if (newIndex != -1) {
                  setState(() {
                    _currentPageIndex = newIndex;
                  });
                  _pageController.jumpToPage(newIndex);
                }
              },
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _validWeeks.length,
              reverse: true,
              onPageChanged: (index) {
                setState(() {
                  _currentPageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final week = _validWeeks[index];
                final records = _recordsForWeek(week);
                final categoryData = _getCategoryTotals(records);
                final emotionData = _getEmotionCounts(records);

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
                          '${_formatWeekLabel(week)} 소비 리포트',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatWeekRange(week),
                          style: const TextStyle(
                            fontSize: 13,
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



