import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/record.dart';
import '../utils/record_storage.dart';
import 'record_list_screen.dart';

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

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  List<Record> _allRecords = [];
  List<String> _availableDates = [];
  Set<String> _availableDateSet = {};
  late DateTime _selectedDate;
  bool _isCalendarVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await RecordStorage.loadRecords();
    final dates = records
        .map((r) => DateFormat('yyyy-MM-dd').format(DateTime.parse(r.spendDate)))
        .toSet()
        .toList()
      ..sort();

    setState(() {
      _allRecords = records;
      _availableDates = dates;
      _availableDateSet = dates.toSet();
      _selectedDate = dates.isNotEmpty ? DateTime.parse(dates.last) : DateTime.now();
    });
  }

  void _changeDateBySwipe(bool forward) {
    final current = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final index = _availableDates.indexOf(current);
    if (index == -1) return;
    final newIndex = forward ? index + 1 : index - 1;
    if (newIndex >= 0 && newIndex < _availableDates.length) {
      setState(() {
        _selectedDate = DateTime.parse(_availableDates[newIndex]);
      });
    }
  }

  List<Record> _recordsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _allRecords.where((r) => DateFormat('yyyy-MM-dd').format(DateTime.parse(r.spendDate)) == dateStr).toList();
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

  Widget _buildAllList(String title, Map<String, int> dataMap, Map<String, Color> colorMap) {
    final entries = dataMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalSum = dataMap.values.fold<double>(0.0, (a, b) => a + b.toDouble());

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
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: color),
                          const SizedBox(width: 6),
                          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                    Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
    final selectedStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final records = _recordsForDate(_selectedDate);
    final categoryData = _getCategoryTotals(records);
    final emotionData = _getEmotionCounts(records);
    final categoryPie = _buildPieSections(categoryData, categoryColors);
    final emotionPie = _buildPieSections(emotionData, emotionColors);

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
          GestureDetector(
            onTap: () => setState(() => _isCalendarVisible = !_isCalendarVisible),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('yyyy년 M월 d일').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(_isCalendarVisible ? Icons.expand_less : Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isCalendarVisible ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: TableCalendar(
              focusedDay: _selectedDate,
              firstDay: DateTime.utc(2022, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selected, focused) {
                final formatted = DateFormat('yyyy-MM-dd').format(selected);
                if (_availableDateSet.contains(formatted)) {
                  setState(() {
                    _selectedDate = selected;
                    _isCalendarVisible = false;
                  });
                }
              },
              enabledDayPredicate: (day) => _availableDateSet.contains(DateFormat('yyyy-MM-dd').format(day)),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < 0) {
                  _changeDateBySwipe(true);
                } else if (details.primaryVelocity! > 0) {
                  _changeDateBySwipe(false);
                }
              },
              child: SingleChildScrollView(
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
                        '${DateFormat('yyyy년 M월 d일').format(_selectedDate)} 소비 리포트',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: categoryPie.isEmpty
                            ? const Center(child: Text('데이터 없음'))
                            : PieChart(
                          PieChartData(
                            sections: categoryPie,
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAllList('카테고리별 소비 내역', categoryData, categoryColors),
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 200,
                        child: emotionPie.isEmpty
                            ? const Center(child: Text('데이터 없음'))
                            : PieChart(
                          PieChartData(
                            sections: emotionPie,
                            sectionsSpace: 2,
                            centerSpaceRadius: 60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAllList('감정별 소비 내역', emotionData, emotionColors),
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RecordListScreen(selectedDate: selectedStr),
                              ),
                            );
                            if (result == true) {
                              await _loadRecords();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('소비기록 수정', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}










