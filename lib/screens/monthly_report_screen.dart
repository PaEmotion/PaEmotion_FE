import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../utils/record_utils.dart';
import '../utils/report_utils.dart';
import '../models/report.dart';

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
  '행복', '사랑', '기대감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움', '기회감'
];

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  List<String> _validMonths = [];
  int _currentPageIndex = 0;
  String? _selectedReportText;
  List<Record> _currentMonthRecords = [];
  bool _loading = true;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final allReports = await ReportUtils.loadCachedReports();
    final monthlyReports = allReports.where((r) => r.reportType == 'monthly').toList();

    final monthKeys = monthlyReports.map((r) {
      final date = DateTime.parse(r.reportDate);
      final firstDay = DateTime(date.year, date.month, 1);
      return DateFormat('yyyy-MM-dd').format(firstDay);
    }).toSet().toList();

    monthKeys.sort((a, b) => b.compareTo(a));

    setState(() {
      _validMonths = monthKeys;
      _currentPageIndex = 0;
      _loading = false;
    });

    if (_validMonths.isNotEmpty) {
      final firstMonth = _parseMonthKey(_validMonths.first);
      await _loadReportTextForMonth(_validMonths.first);
      await _loadRecordsForMonth(firstMonth);
    }
  }

  Future<void> _loadReportTextForMonth(String selectedMonthKey) async {
    final allReports = await ReportUtils.loadCachedReports();
    Report? target;

    for (final r in allReports) {
      if (r.reportType != 'monthly') continue;
      final firstDay = DateTime.parse(r.reportDate);
      final monthKey = DateFormat('yyyy-MM-dd').format(DateTime(firstDay.year, firstDay.month, 1));
      if (monthKey == selectedMonthKey) {
        target = r;
        break;
      }
    }

    setState(() {
      _selectedReportText = target?.reportText ?? '';
    });
  }

  Future<void> _loadRecordsForMonth(DateTime monthStart) async {
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
    final records = await fetchRecordsInRange(monthStart, nextMonth);
    setState(() {
      _currentMonthRecords = records;
    });
  }

  DateTime _parseMonthKey(String monthKey) => DateTime.parse(monthKey);

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

  List<PieChartSectionData> _buildPieSections(
      Map<String, int> dataMap,
      Map<String, Color> colorMap,
      ) {
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

  void _onMonthChanged(String? newKey) async {
    if (newKey == null) return;
    final idx = _validMonths.indexOf(newKey);
    if (idx == -1) return;

    final monthStart = _parseMonthKey(newKey);
    setState(() => _currentPageIndex = idx);
    _pageController.jumpToPage(idx);
    await _loadReportTextForMonth(newKey);
    await _loadRecordsForMonth(monthStart);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.04;
    final chartHeight = size.height * 0.25;
    final cardMinHeight = size.height * 0.3;
    final cardPadding = size.width * 0.06;
    final titleFontSize = size.width * 0.05;
    final subTitleFontSize = size.width * 0.035;
    final reportFontSize = size.width * 0.035;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_validMonths.isEmpty) {
      return Scaffold(appBar: _appBar, body: Center(child: Text('조회 가능한 리포트가 없습니다.')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _validMonths[_currentPageIndex],
              items: _validMonths.map((monthKey) {
                final label = ReportUtils.formatMonthlyReportTitle(monthKey);
                return DropdownMenuItem(value: monthKey, child: Text(label));
              }).toList(),
              onChanged: _onMonthChanged,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _validMonths.length,
              reverse: true,
              onPageChanged: (idx) async {
                final monthKey = _validMonths[idx];
                final monthStart = _parseMonthKey(monthKey);
                setState(() => _currentPageIndex = idx);
                await _loadReportTextForMonth(monthKey);
                await _loadRecordsForMonth(monthStart);
              },
              itemBuilder: (context, idx) {
                final monthKey = _validMonths[idx];
                final monthStart = _parseMonthKey(monthKey);
                final categoryData = _getCategoryTotals(_currentMonthRecords);
                final emotionData = _getEmotionCounts(_currentMonthRecords);

                return SingleChildScrollView(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(minHeight: cardMinHeight),
                        decoration: BoxDecoration(
                          image: const DecorationImage(
                            image: AssetImage('lib/assets/report_receipt.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ReportUtils.formatMonthlyReportTitle(monthKey),
                              style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: cardMinHeight * 0.02),
                            Text(
                              '${DateFormat('yyyy.MM.01').format(monthStart)} ~ ${DateFormat('yyyy.MM.dd').format(DateTime(monthStart.year, monthStart.month + 1, 0))}',
                              style: TextStyle(fontSize: subTitleFontSize, color: Colors.black54),
                            ),
                            SizedBox(height: cardMinHeight * 0.06),
                            Text(
                              _selectedReportText ?? '',
                              style: TextStyle(fontSize: reportFontSize, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: padding * 2),
                      if (categoryData.isNotEmpty) _buildChartBlock('카테고리별 소비', categoryData, categoryColors, chartHeight),
                      SizedBox(height: padding * 2),
                      if (emotionData.isNotEmpty) _buildChartBlock('감정별 소비', emotionData, emotionColors, chartHeight),
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

  Widget _buildChartBlock(String title, Map<String, int> data, Map<String, Color> colors, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  AppBar get _appBar => AppBar(
    title: const Text('월간 리포트', style: TextStyle(color: Colors.black)),
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
        SizedBox(height: 8),
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
}