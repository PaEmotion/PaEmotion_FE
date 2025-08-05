import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/record.dart';
import '../models/report.dart';
import '../utils/report_utils.dart';
import '../utils/record_utils.dart';

final Map<String, Color> categoryColors = {
  '쇼핑': Colors.purple,
  '배달음식': Colors.orange,
  '외식': Colors.deepOrange,
  '카페': Colors.brown,
  '취미': Colors.teal,
  '뷰티': Colors.pink,
  '건강': Colors.green,
  '자기계발': Colors.blue,
  '선물': Colors.amber,
  '여행': Colors.cyan,
  '모임': Colors.indigo,
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
    final weeklyReports = allReports.where((r) => r.reportType == 'weekly')
        .toList();

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
    final sunday = monday.add(const Duration(days: 6));
    final records = await fetchRecordsInRange(
        monday, sunday.add(const Duration(days: 1)));
    setState(() {
      _currentWeekRecords = records;
    });
  }

  DateTime _parseWeekKeyToMonday(String weekKey) {
    final thursday = DateTime.parse(weekKey);
    return thursday.subtract(const Duration(days: 3));
  }

  Map<String, int> _getCategoryTotals(List<Record> records) {
    final map = <String, int>{};
    for (final r in records) {
      if (r.spend_category > 0 && r.spend_category <= allCategories.length) {
        final name = allCategories[r.spend_category - 1];
        map[name] = (map[name] ?? 0) + r.spendCost;
      }
    }
    return map;
  }

  Map<String, int> _getEmotionCounts(List<Record> records) {
    final map = <String, int>{};
    for (final r in records) {
      if (r.emotion_category > 0 && r.emotion_category <= allEmotions.length) {
        final name = allEmotions[r.emotion_category - 1];
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    return map;
  }

  List<PieChartSectionData> _buildPieSections(Map<String, int> dataMap,
      Map<String, Color> colorMap) {
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
    return ReportUtils.formatToThursdayBasedWeekTitle(
        DateFormat('yyyy-MM-dd').format(monday));
  }

  String _weekRange(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    return '${DateFormat('yyyy.MM.dd').format(monday)} ~ ${DateFormat(
        'yyyy.MM.dd').format(sunday)}';
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
    final size = MediaQuery
        .of(context)
        .size;
    final padding = size.width * 0.04;
    final chartHeight = size.height * 0.25;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_validWeeks.isEmpty) {
      return Scaffold(
        appBar: _appBar,
        body: const Center(child: Text('조회 가능한 리포트가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: _appBar,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _validWeeks[_currentPageIndex],
              items: _validWeeks.map((weekKey) {
                return DropdownMenuItem<String>(
                  value: weekKey,
                  child: Text(
                      ReportUtils.formatToThursdayBasedWeekTitle(weekKey)),
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
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReceiptCard(monday, size),
                      SizedBox(height: padding * 2),
                      if (categoryData.isNotEmpty) _buildChartBlock(
                          '카테고리별 소비', categoryData, categoryColors,
                          chartHeight),
                      SizedBox(height: padding * 2),
                      if (emotionData.isNotEmpty) _buildChartBlock(
                          '감정별 소비', emotionData, emotionColors, chartHeight),
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

  Widget _buildReceiptCard(DateTime monday, Size size) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: size.height * 0.3),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/report_receipt.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: EdgeInsets.all(size.width * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_weekLabel(monday), style: TextStyle(
              fontSize: size.width * 0.05, fontWeight: FontWeight.bold)),
          SizedBox(height: size.height * 0.005),
          Text(_weekRange(monday), style: TextStyle(
              fontSize: size.width * 0.035, color: Colors.black54)),
          SizedBox(height: size.height * 0.02),
          Text(_selectedReportText ?? '',
              style: TextStyle(fontSize: size.width * 0.035, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildChartBlock(String title, Map<String, int> data,
      Map<String, Color> colors, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        SizedBox(
          height: height,
          child: PieChart(
            PieChartData(
              sections: _buildPieSections(data, colors),
              centerSpaceRadius: height * 0.3,
              sectionsSpace: 2,
            ),
          ),
        ),
        SizedBox(height: 12),
        _buildDetailList('$title 내역', data, colors),
      ],
    );
  }

  AppBar get _appBar =>
      AppBar(
        title: const Text('주간 리포트', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        elevation: 0,
      );

  Widget _buildDetailList(String title, Map<String, int> dataMap,
      Map<String, Color> colorMap) {
    final totalSum = dataMap.values.fold(0, (a, b) => a + b).toDouble();
    final entries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            // 한 줄에 두 개씩 배치 (spacing 고려)
            final double spacing = 16;
            final double itemWidth = (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: 8,
              children: entries.map((e) {
                final color = colorMap[e.key] ?? Colors.grey;
                final percent = totalSum > 0 ? (e.value / totalSum) * 100 : 0;

                return SizedBox(
                  width: itemWidth,
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
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}