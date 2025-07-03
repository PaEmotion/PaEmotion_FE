import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/record.dart';
import '../utils/record_storage.dart';
import 'record_list_screen.dart';

// 품목 카테고리별 색상 매핑 (임시)
final Map<String, Color> categoryColors = {
  '쇼핑': Colors.pinkAccent,
  '배달음식': Colors.deepOrangeAccent,
  '외식': Colors.purple,
  '카페': Colors.brown,
  '취미': Colors.teal,
  '뷰티': Colors.pink,
  '건강': Colors.green,
  '자기계발': Colors.indigo,
  '선물': Colors.orange,
  '여행': Colors.blue,
};

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<Record> _allRecords = [];
  List<String> _availableDates = [];
  String? _selectedDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // 초기: 빈 PageController 할당
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

    final dates = records
        .map((r) {
      final dt = DateTime.parse(r.date);
      final normalized = DateTime(dt.year, dt.month, dt.day);
      return DateFormat('yyyy-MM-dd').format(normalized);
    })
        .toSet()
        .toList()
      ..sort();

    final lastPageIndex = dates.isNotEmpty ? dates.length - 1 : 0;

    setState(() {
      _allRecords = records;
      _availableDates = dates;
      _selectedDate = dates.isNotEmpty ? dates.last : null;

      // 기존 컨트롤러 해제, 새로 생성해서 초기 페이지 설정
      _pageController.dispose();
      _pageController = PageController(initialPage: lastPageIndex);
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedDate = _availableDates[index];
    });
  }

  void _onDropdownChanged(String? newDate) {
    if (newDate == null) return;
    final newIndex = _availableDates.indexOf(newDate);
    if (newIndex != -1) {
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _selectedDate = newDate;
      });
    }
  }

  List<Record> _recordsForDate(String date) {
    return _allRecords.where((r) {
      final normalized = DateFormat('yyyy-MM-dd').format(DateTime.parse(r.date));
      return normalized == date;
    }).toList();
  }

  List<PieChartSectionData> _buildPieSections(List<Record> records) {
    final Map<String, int> totalsByCategory = {};
    for (final record in records) {
      totalsByCategory.update(
        record.category,
            (value) => value + record.amount,
        ifAbsent: () => record.amount,
      );
    }

    final total = totalsByCategory.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];

    return totalsByCategory.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final color = categoryColors[entry.key] ?? Colors.grey;

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: '${entry.key} ${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일간 리포트', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _availableDates.isEmpty
          ? const Center(child: Text('소비기록이 없습니다.'))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _selectedDate,
              isExpanded: true,
              dropdownColor: Colors.grey[200],
              iconEnabledColor: Colors.black87,
              style:
              const TextStyle(color: Colors.black87, fontSize: 16),
              items: _availableDates.map((date) {
                return DropdownMenuItem(
                  value: date,
                  child: Text('$date 리포트'),
                );
              }).toList(),
              onChanged: _onDropdownChanged,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _availableDates.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final date = _availableDates[index];
                final records = _recordsForDate(date);
                final pieSections = _buildPieSections(records);

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
                          '$date 소비 리포트',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: pieSections.isEmpty
                              ? const Center(
                              child:
                              Text('해당 날짜의 소비기록이 없습니다.'))
                              : PieChart(
                            PieChartData(
                              sections: pieSections,
                              sectionsSpace: 4,
                              centerSpaceRadius: 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'AI 분석 리포트는 추후 제공될 예정입니다.',
                          style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordListScreen(
                                      selectedDate: date),
                                ),
                              );
                              if (result == true) {
                                await _loadRecords();
                              }
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('소비기록 수정',
                                style:
                                TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
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

