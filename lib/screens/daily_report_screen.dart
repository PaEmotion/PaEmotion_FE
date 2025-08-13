import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/record.dart';
import '../utils/record_utils.dart';

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

final List<String> allCategories = [
  '쇼핑', '배달음식', '외식', '카페', '취미', '뷰티', '건강', '자기계발', '선물', '여행', '모임'
];

final List<String> allEmotions = [
  '행복', '사랑', '기대감', '기회감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움'
];

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final numberFormat = NumberFormat('#,###');
  List<Record> _allRecords = [];
  List<String> _availableDates = [];
  Set<String> _availableDateSet = {};
  late DateTime _selectedDate;
  bool _isCalendarVisible = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = now;
    _loadAvailableDatesForMonth(now);
  }

  Future<void> _loadAvailableDatesForMonth(DateTime month) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0);

      final records = await fetchRecordsInRange(firstDay, lastDay);

      final datesWithRecords = records
          .map((r) => DateFormat('yyyy-MM-dd').format(DateTime.parse(r.spendDate)))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {
        _allRecords = records;
        _availableDates = datesWithRecords;
        _availableDateSet = datesWithRecords.toSet();

        final selectedStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        if (!_availableDateSet.contains(selectedStr)) {
          _selectedDate = datesWithRecords.isNotEmpty
              ? DateTime.parse(datesWithRecords.first)
              : firstDay;
        }
      });
    } catch (e) {
      setState(() {
        _allRecords = [];
        _availableDates = [];
        _availableDateSet = {};
      });
    }
  }

  List<Record> _recordsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return _allRecords.where((r) =>
    DateFormat('yyyy-MM-dd').format(DateTime.parse(r.spendDate)) == dateStr).toList();
  }

  Map<String, int> _getCategoryTotals(List<Record> records) {
    final map = <String, int>{};
    for (var r in records) {
      final id = r.spend_category;
      if (id > 0 && id <= allCategories.length) {
        final name = allCategories[id - 1];
        map[name] = (map[name] ?? 0) + r.spendCost;
      }
    }
    return map;
  }

  Map<String, int> _getEmotionCounts(List<Record> records) {
    final map = <String, int>{};
    for (var r in records) {
      final id = r.emotion_category;
      if (id > 0 && id <= allEmotions.length) {
        final name = allEmotions[id - 1];
        map[name] = (map[name] ?? 0) + 1;
      }
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

  Widget _buildSpendList(List<Record> records, double smallFontSize) {
    if (records.isEmpty) {
      return const Text('소비 항목 없음');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '소비 항목',
          style: TextStyle(fontSize: smallFontSize + 2, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: smallFontSize * 0.5),
        ...records.map((record) {
          final emotionIndex = (record.emotion_category - 1).clamp(0, allEmotions.length - 1);
          final emotionName = allEmotions[emotionIndex];
          final emotionColor = emotionColors[emotionName] ?? Colors.grey;

          return Padding(
            padding: EdgeInsets.symmetric(vertical: smallFontSize * 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: smallFontSize * 0.7,
                      height: smallFontSize * 0.7,
                      margin: EdgeInsets.only(right: smallFontSize * 0.3),
                      decoration: BoxDecoration(
                        color: emotionColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(record.spendItem, style: TextStyle(fontSize: smallFontSize)),
                  ],
                ),
                Text('${numberFormat.format(record.spendCost)}원',
                    style: TextStyle(fontSize: smallFontSize, color: Colors.grey)),
              ],
            ),
          );
        }).toList(),
        const Divider(),
        SizedBox(height: smallFontSize),
      ],
    );
  }

  Widget _buildAllList(String title, Map<String, int> dataMap, Map<String, Color> colorMap, double smallFontSize) {
    final entries = dataMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalSum = dataMap.values.fold<double>(0.0, (a, b) => a + b.toDouble());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: smallFontSize, fontWeight: FontWeight.bold)),
        SizedBox(height: smallFontSize * 0.5),
        ...entries.map((entry) {
          final color = colorMap[entry.key] ?? Colors.grey;
          final percent = totalSum > 0 ? (entry.value / totalSum) * 100 : 0;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: smallFontSize * 0.2),
            child: Row(
              children: [
                Container(
                  width: smallFontSize * 0.7,
                  height: smallFontSize * 0.7,
                  color: color,
                ),
                SizedBox(width: smallFontSize * 0.3),
                Expanded(
                  child: Text(entry.key,
                      style: TextStyle(fontSize: smallFontSize * 0.9),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${percent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: smallFontSize * 0.9, color: Colors.black54)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _onDateSelected(DateTime selected) {
    final formatted = DateFormat('yyyy-MM-dd').format(selected);
    if (_availableDateSet.contains(formatted)) {
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;

        double titleFontSize;
        double smallFontSize;
        double sectionSpacing;
        double contentPadding;
        double pieHeight;

        if (width < 350) {
          titleFontSize = 18;
          smallFontSize = 12;
          sectionSpacing = 16;
          contentPadding = 16;
          pieHeight = 150;
        } else if (width < 600) {
          titleFontSize = 22;
          smallFontSize = 14;
          sectionSpacing = 20;
          contentPadding = 20;
          pieHeight = 180;
        } else {
          titleFontSize = 26;
          smallFontSize = 16;
          sectionSpacing = 24;
          contentPadding = 24;
          pieHeight = 200;
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _isCalendarVisible = !_isCalendarVisible),
                child: Padding(
                  padding: EdgeInsets.all(contentPadding * 0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('yyyy년 M월 d일').format(_selectedDate),
                        style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: contentPadding * 0.3),
                      Icon(_isCalendarVisible ? Icons.expand_less : Icons.expand_more,
                          size: titleFontSize * 0.6),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isCalendarVisible
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: TableCalendar(
                  focusedDay: _selectedDate,
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                  onDaySelected: (selected, focused) {
                    _onDateSelected(selected);
                  },
                  enabledDayPredicate: (day) =>
                      _availableDateSet.contains(DateFormat('yyyy-MM-dd').format(day)),
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                  calendarStyle: CalendarStyle(
                    selectedDecoration:
                    BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                    selectedTextStyle:
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPageChanged: (focusedDay) {
                    _loadAvailableDatesForMonth(focusedDay);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(contentPadding),
                child: _availableDates.isEmpty
                    ? const Center(child: Text('소비기록이 없습니다.'))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('yyyy년 M월 d일').format(_selectedDate)} 소비 리포트',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: sectionSpacing),
                    _buildSpendList(records, smallFontSize),
                    SizedBox(
                      height: pieHeight,
                      child: emotionPie.isEmpty
                          ? const Center(child: Text('데이터 없음'))
                          : PieChart(
                        PieChartData(
                          sections: emotionPie,
                          sectionsSpace: 2,
                          centerSpaceRadius: pieHeight * 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: smallFontSize),
                    _buildAllList(
                        '감정별 소비 내역', emotionData, emotionColors, smallFontSize),
                    SizedBox(height: smallFontSize),
                    SizedBox(
                      height: pieHeight,
                      child: categoryPie.isEmpty
                          ? const Center(child: Text('데이터 없음'))
                          : PieChart(
                        PieChartData(
                          sections: categoryPie,
                          sectionsSpace: 2,
                          centerSpaceRadius: pieHeight * 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: smallFontSize),
                    _buildAllList(
                        '카테고리별 소비 내역', categoryData, categoryColors, smallFontSize),
                    SizedBox(height: sectionSpacing),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}