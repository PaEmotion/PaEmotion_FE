import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:collection/collection.dart';
import '../models/record.dart';
import '../models/report.dart';
import '../utils/report_utils.dart';
import '../utils/record_utils.dart';

final Map<String, Color> categoryColors = {
  '쇼핑': Colors.purple.shade300,
  '배달음식': Colors.orange.shade400,
  '외식': Colors.deepOrange.shade400,
  '카페': Colors.brown.shade400,
  '취미': Colors.teal.shade300,
  '뷰티': Colors.pink.shade300,
  '건강': Colors.green.shade400,
  '자기계발': Colors.blue.shade300,
  '선물': Colors.amber.shade300,
  '여행': Colors.cyan.shade300,
  '모임': Colors.indigo.shade300,
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

final List<String> allCategories = categoryColors.keys.toList();
final List<String> allEmotions = emotionColors.keys.toList();

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  List<String> _validWeeks = [];
  int _currentPageIndex = 0;
  String? _selectedReportText;
  List<Record> _currentWeekRecords = [];
  bool _loading = true;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    await _loadReportsAndSetupWeeks();
  }

  Future<void> _loadReportsAndSetupWeeks() async {
    final allReports = await ReportUtils.loadCachedReports();
    final weeklyReports = allReports.where((r) => r.reportType == 'weekly').toList();

    final weekKeys = weeklyReports.map((r) {
      final monday = DateTime.parse(r.reportDate);
      final thursday = ReportUtils.getThursdayBasedDate(monday);
      return DateFormat('yyyy-MM-dd').format(thursday);
    }).toSet().toList();

    weekKeys.sort((a, b) => b.compareTo(a));

    setState(() {
      _validWeeks = weekKeys;
      _currentPageIndex = 0;
      _loading = false;
    });

    if (_validWeeks.isNotEmpty) {
      final firstKey = _validWeeks.first;
      final monday = _parseWeekKeyToMonday(firstKey);
      await _loadReportTextForWeek(firstKey);
      await _loadRecordsForWeek(monday);
    }
  }

  Future<void> _loadReportTextForWeek(String weekKey) async {
    final allReports = await ReportUtils.loadCachedReports();
    Report? matched;

    for (final r in allReports) {
      if (r.reportType != 'weekly') continue;
      final thursdayKey = DateFormat('yyyy-MM-dd').format(
        ReportUtils.getThursdayBasedDate(DateTime.parse(r.reportDate)),
      );
      if (thursdayKey == weekKey) {
        matched = r;
        break;
      }
    }

    setState(() {
      _selectedReportText = matched?.reportText ?? '';
    });
  }

  Future<void> _loadRecordsForWeek(DateTime monday) async {
    final sunday = monday.add(Duration(days: 6));
    final records = await fetchRecordsInRange(monday, sunday.add(Duration(days: 1)));
    setState(() {
      _currentWeekRecords = records;
    });
  }

  DateTime _parseWeekKeyToMonday(String weekKey) {
    final thursday = DateTime.parse(weekKey);
    return thursday.subtract(Duration(days: 3));
  }

  Map<String, int> _getCategoryTotals(List<Record> records) {
    final map = <String, int>{};
    for (final r in records) {
      final idx = r.spend_category;
      if (idx > 0 && idx <= allCategories.length) {
        final name = allCategories[idx - 1];
        map[name] = (map[name] ?? 0) + r.spendCost;
      }
    }
    return map;
  }

  Map<String, int> _getEmotionCounts(List<Record> records) {
    final map = <String, int>{};
    for (final r in records) {
      final idx = r.emotion_category;
      if (idx > 0 && idx <= allEmotions.length) {
        final name = allEmotions[idx - 1];
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    return map;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> dataMap, Map<String, Color> colorMap) {
    final total = dataMap.values.fold(0, (a, b) => a + b);
    if (total == 0) return [];
    return dataMap.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: colorMap[e.key] ?? Colors.grey,
        title: '',
        radius: 40,
      );
    }).toList();
  }

  String _weekLabel(DateTime monday) {
    final iso = DateFormat('yyyy-MM-dd').format(monday);
    return ReportUtils.formatToThursdayBasedWeekTitle(iso);
  }

  String _weekRange(DateTime monday) {
    final formatter = DateFormat('yyyy.MM.dd');
    final sunday = monday.add(Duration(days: 6));
    return '${formatter.format(monday)} ~ ${formatter.format(sunday)}';
  }

  void _onWeekChanged(String? newKey) async {
    if (newKey == null) return;
    final idx = _validWeeks.indexOf(newKey);
    if (idx == -1) return;

    final monday = _parseWeekKeyToMonday(newKey);

    setState(() => _currentPageIndex = idx);
    _pageController.jumpToPage(idx);
    await _loadReportTextForWeek(newKey);
    await _loadRecordsForWeek(monday);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_validWeeks.isEmpty) {
      return Scaffold(
        appBar: _appBar,
        body: const Center(child: Text('소비 기록이 없습니다.')),
      );
    }

    return Scaffold(
      appBar: _appBar,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _validWeeks[_currentPageIndex],
              items: _validWeeks.map((weekKey) {
                final label = ReportUtils.formatToThursdayBasedWeekTitle(weekKey);
                return DropdownMenuItem<String>(
                  value: weekKey,
                  child: Text(label),
                );
              }).toList(),
              onChanged: _onWeekChanged,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _validWeeks.length,
              reverse: true,
              onPageChanged: (idx) async {
                final weekKey = _validWeeks[idx];
                final monday = _parseWeekKeyToMonday(weekKey);
                setState(() => _currentPageIndex = idx);
                await _loadReportTextForWeek(weekKey);
                await _loadRecordsForWeek(monday);
              },
              itemBuilder: (context, idx) {
                final weekKey = _validWeeks[idx];
                final monday = _parseWeekKeyToMonday(weekKey);
                final categoryData = _getCategoryTotals(_currentWeekRecords);
                final emotionData = _getEmotionCounts(_currentWeekRecords);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 300),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('lib/assets/report_receipt.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _weekLabel(monday),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _weekRange(monday),
                                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _selectedReportText ?? '',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      if (categoryData.isNotEmpty) ...[
                        const Text('카테고리별 소비', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(categoryData, categoryColors),
                              centerSpaceRadius: 60,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailList('카테고리별 소비 내역', categoryData, categoryColors),
                      ],
                      const SizedBox(height: 32),
                      if (emotionData.isNotEmpty) ...[
                        const Text('감정별 소비', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: _buildPieSections(emotionData, emotionColors),
                              centerSpaceRadius: 60,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailList('감정별 소비 내역', emotionData, emotionColors),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar get _appBar => AppBar(
    title: const Text('주간 리포트', style: TextStyle(color: Colors.black)),
    backgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: Colors.black),
    centerTitle: true,
    elevation: 0,
  );

  Widget _buildDetailList(String title, Map<String, int> dataMap, Map<String, Color> colorMap) {
    final totalSum = dataMap.values.fold(0, (a, b) => a + b).toDouble();
    final entries = dataMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
            children: entries.map((e) {
              final color = colorMap[e.key] ?? Colors.grey;
              final percent = totalSum > 0 ? (e.value / totalSum) * 100 : 0;
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
                          Expanded(
                            child: Text(
                              e.key,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
}
