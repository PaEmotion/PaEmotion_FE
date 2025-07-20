import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../api/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/user.dart';
import 'aichat_screen.dart';
import 'report_screen.dart';
import 'budget_screen.dart';
import 'challenge_screen.dart';
import 'mypage_screen.dart';
import 'record_screen.dart';
import 'record_list_screen.dart';
import '../models/record.dart';
// import '../utils/record_storage.dart';

final Map<int, String> categoryMap = {
  1: '쇼핑',
  2: '배달음식',
  3: '외식',
  4: '카페',
  5: '취미',
  6: '뷰티',
  7: '건강',
  8: '자기계발',
  9: '선물',
  10: '여행',
  11: '모임',
};

final Map<int, String> emotionMap = {
  1: '행복',
  2: '사랑',
  3: '기대감',
  4: '기회감',
  5: '슬픔',
  6: '우울',
  7: '분노',
  8: '스트레스',
  9: '피로',
  10: '불안',
  11: '무료함',
  12: '외로움',
};


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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Record> _todaysRecords = [];
  String _username = '.'; // error 방지용

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadTodayRecords();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString != null) {
      final userMap = jsonDecode(jsonString);
      final user = User.fromJson(userMap);
      if (!mounted) return;
      setState(() {
        _username = user.name.isNotEmpty ? user.name : '사용자님';
      });
    }
  }

  Future<void> _loadTodayRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');
    if (jsonString == null) {
      setState(() {
        _todaysRecords = [];
      });
      return;
    }
    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final userId = user.id;

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await ApiClient.dio.get(
        '/records/$userId/',
        queryParameters: {
          'spendDate': today,
        },
      );

      // 디버그용
      print('API 응답 상태: ${response.statusCode}');
      print('API 응답 데이터 타입: ${response.data.runtimeType}');
      print('API 응답 데이터 내용: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final allRecords = data.map((e) => Record.fromJson(e)).toList();

        setState(() {
          _todaysRecords = allRecords;
        });
      } else {
        throw Exception('API 호출 실패: 상태코드 ${response.statusCode}');
      }
    } catch (e) {

      print('API 호출 에러: $e');
      setState(() {
        _todaysRecords = [];
      });
    }
  }


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _loadTodayRecords();
  }


  String _getTopCategory(List<Record> records) {
    final totals = <int, int>{};
    for (var r in records) {
      totals[r.spend_category] = (totals[r.spend_category] ?? 0) + r.spendCost;
    }
    if (totals.isEmpty) return '';
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return categoryMap[sorted.first.key] ?? '기타';
  }


  Widget _buildPieChartWithEmotionIcon() {
    final categoryTotals = <int, double>{};
    for (var record in _todaysRecords) {
      categoryTotals.update(record.spend_category, (v) => v + record.spendCost, ifAbsent: () => record.spendCost.toDouble());
    }
    final sections = categoryTotals.entries.map((entry) {
      final color = categoryColors[categoryMap[entry.key] ?? '기타'] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 32,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
      child: SizedBox(
        height: 300,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: 90,
              sectionsSpace: 4,
              startDegreeOffset: -90,
            )),
            const Text('😊', style: TextStyle(fontSize: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final numberFormat = NumberFormat('#,###');
    final totalAmount = _todaysRecords.fold(0, (sum, r) => sum + r.spendCost);
    final topCategory = _getTopCategory(_todaysRecords);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 25),

        Text('$_username님, 안녕하세요! 😊\n행운 가득한 하루 보내세요.',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),

        if (_todaysRecords.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 24),
            child: Text('오늘의 소비 기록이 없습니다. 기록을 추가해보세요!',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          )
        else ...[
          _buildPieChartWithEmotionIcon(),
          if (topCategory.isNotEmpty)
            Center(
              child: Text(
                '오늘은 $topCategory에 소비가 많았어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordScreen()))
                  .then((_) => _loadTodayRecords()),
              child: const Text('소비기록 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecordListScreen()))
                  .then((_) => _loadTodayRecords()),
              child: const Text('소비기록 수정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),

        const SizedBox(height: 36),

        if (_todaysRecords.isNotEmpty) ...[
          const Text('📝 오늘의 소비 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          ..._todaysRecords.map((record) {
            final emotionId = record.emotion_category;
            final emotionName = emotionMap[emotionId] ?? '감정없음';
            final dotColor = emotionColors[emotionName] ?? Colors.grey;
            final backgroundColor = dotColor.withOpacity(0.1);
            final catName = categoryMap[record.spend_category] ?? '기타';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  Text('$emotionName 소비', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 6),
                Text('$catName - ${record.spendItem}', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text('${numberFormat.format(record.spendCost)}원',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ]),
            );
          }).toList(),

          const SizedBox(height: 12),
          Text('오늘 총 ${numberFormat.format(totalAmount)}원을 소비했어요.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],

        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SafeArea(child: SingleChildScrollView(child: _buildHomeContent()));
      case 1:
        return const SafeArea(child: AIChatScreen());
      case 2:
        return const SafeArea(child: ReportScreen());
      case 3:
        return const SafeArea(child: BudgetScreen());
      case 4:
        return const SafeArea(child: ChallengeScreen());
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PaEmotion',
            style: TextStyle(fontFamily: 'Roboto', fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPageScreen())),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '판단 도움 AI'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: '예산'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '챌린지'),
        ],
      ),
    );
  }
}



