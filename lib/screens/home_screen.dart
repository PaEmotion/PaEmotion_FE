import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../api/api_client.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import 'report_screen.dart';
import 'budget_screen.dart';
import 'challenge_screen.dart';
import 'challenge_search_screen.dart';
import 'mypage_screen.dart';
import 'record_screen.dart';
import 'record_list_screen.dart';
import '../models/record.dart';

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
  4: '슬픔',
  5: '우울',
  6: '분노',
  7: '스트레스',
  8: '피로',
  9: '불안',
  10: '무료함',
  11: '외로움',
  12: '기회감',
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
  String _username = '사용자';
  String _randomGreeting = '';

  final List<String> _greetingMessages = [
    '오늘도 당신을 응원할게요! 💪',
    '햇살처럼 따뜻한 하루 되세요 ☀️',
    '소소한 행복이 가득하길 바라요 🍀',
    '멋진 하루, 당신 몫이에요! ✨',
    '오늘도 잘하고 있어요 👍',
    '마음이 평온한 하루 되시길 바라요 🌿',
    '웃음 가득한 하루 보내세요 😄',
    '무엇이든 할 수 있는 하루예요 💫',
    '행운이 당신을 따라갈 거예요 🍀',
    '오늘 하루도 당신 편이에요 🤗',
    '하늘도 당신을 응원하고 있어요 🌈',
    '힘들 땐 잠깐 쉬어가도 괜찮아요 🫶',
    '오늘도 반짝이는 하루가 되길! ✨',
    '당신의 하루에 기쁨이 가득하길 바라요 ☁️',
    '당신이 웃을 수 있는 일이 생기길 바라요 😊',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserFromApi();
    _loadTodayRecords();
    _pickRandomGreeting();
  }

  void _pickRandomGreeting() {
    final random = Random();
    _randomGreeting = _greetingMessages[random.nextInt(_greetingMessages.length)];
  }

  Future<void> _loadUserFromApi() async {
    try {
      final response = await ApiClient.dio.get('/users/me');

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body['data'] ?? {};
        final name = data['name'] as String? ?? '사용자';
        if (!mounted) return;
        setState(() {
          _username = name.isNotEmpty ? name : '사용자';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadTodayRecords() async {
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final response = await ApiClient.dio.get(
        '/records/me',
        queryParameters: {
          'startDate': DateFormat('yyyy-MM-dd').format(today),
          'endDate': DateFormat('yyyy-MM-dd').format(tomorrow),
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final allRecords = data.map((e) => Record.fromJson(e)).toList();
        if (!mounted) return;
        setState(() {
          _todaysRecords = allRecords;
        });
      } else {
        SnackBar(
          content: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          duration: Duration(seconds: 3),
        );
      }
    } catch (e) {
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

  Widget _buildPieChartWithEmotionIcon(double screenWidth) {
    final categoryTotals = <int, double>{};
    for (var record in _todaysRecords) {
      categoryTotals.update(
        record.spend_category,
            (v) => v + record.spendCost,
        ifAbsent: () => record.spendCost.toDouble(),
      );
    }

    final sections = categoryTotals.entries.map((entry) {
      final color = categoryColors[categoryMap[entry.key] ?? '기타'] ?? Colors.grey;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: screenWidth * 0.08,
      );
    }).toList();

    final positiveEmotions = {'사랑', '행복', '기대감'};
    final negativeEmotions = {
      '기회감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움',
    };

    int positiveCount = 0;
    int negativeCount = 0;

    for (var record in _todaysRecords) {
      final emotion = emotionMap[record.emotion_category];
      if (emotion != null) {
        if (positiveEmotions.contains(emotion)) {
          positiveCount++;
        } else if (negativeEmotions.contains(emotion)) {
          negativeCount++;
        }
      }
    }

    final isPositiveDominant = positiveCount >= negativeCount;
    final centerEmoji = isPositiveDominant ? '😊' : '😢';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenWidth * 0.012),
      child: SizedBox(
        height: screenWidth * 0.7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(PieChartData(
              sections: sections,
              centerSpaceRadius: screenWidth * 0.2,
              sectionsSpace: 4,
              startDegreeOffset: -90,
            )),
            Text(centerEmoji, style: TextStyle(fontSize: screenWidth * 0.12)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth * 0.06;
    final bodyFontSize = screenWidth * 0.040;
    final numberFormat = NumberFormat('#,###');
    final totalAmount = _todaysRecords.fold(0, (sum, r) => sum + r.spendCost);
    final topCategory = _getTopCategory(_todaysRecords);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: screenWidth * 0.05),
        Text(
          '$_username님, 안녕하세요! 😊\n$_randomGreeting',
          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
        ),
        if (_todaysRecords.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.03, bottom: screenWidth * 0.06),
            child: Text(
              '오늘의 소비 기록이 없습니다. 기록을 추가해보세요!',
              style: TextStyle(fontSize: bodyFontSize, color: Colors.grey),
            ),
          )
        else ...[
          _buildPieChartWithEmotionIcon(screenWidth),
          if (topCategory.isNotEmpty)
            Center(
              child: Text(
                '오늘은 $topCategory에 소비가 많았어요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.w500),
              ),
            ),
        ],
        SizedBox(height: screenWidth * 0.05),
        Row(children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RecordScreen()))
                  .then((_) => _loadTodayRecords()),
              child: Text(
                '소비기록 추가하기',
                style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const RecordListScreen()))
                  .then((_) => _loadTodayRecords()),
              child: Text(
                '소비기록 수정하기',
                style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ]),
        SizedBox(height: screenWidth * 0.08),
        if (_todaysRecords.isNotEmpty) ...[
          Text('📝 오늘의 소비 기록',
              style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold)),
          SizedBox(height: screenWidth * 0.02),
          ..._todaysRecords.map((record) {
            final emotionId = record.emotion_category;
            final emotionName = emotionMap[emotionId] ?? '';
            final dotColor = emotionColors[emotionName] ?? Colors.grey;
            final backgroundColor = dotColor.withOpacity(0.1);
            final catName = categoryMap[record.spend_category] ?? '';

            return Container(
              margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: screenWidth * 0.025,
                    height: screenWidth * 0.025,
                    margin: EdgeInsets.only(right: screenWidth * 0.015),
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  Text('$emotionName 소비',
                      style:
                      TextStyle(fontSize: screenWidth * 0.032, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: screenWidth * 0.015),
                Text('$catName - ${record.spendItem}', style: TextStyle(fontSize: screenWidth * 0.04)),
                SizedBox(height: screenWidth * 0.015),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text('${numberFormat.format(record.spendCost)}원',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.04)),
                ),
              ]),
            );
          }).toList(),
          SizedBox(height: screenWidth * 0.03),
          Text('오늘 총 ${numberFormat.format(totalAmount)}원을 소비했어요.',
              style: TextStyle(fontSize: bodyFontSize, fontWeight: FontWeight.bold)),
        ],
        SizedBox(height: screenWidth * 0.05),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SafeArea(
          child: SingleChildScrollView(
            child: _buildHomeContent(context),
          ),
        );
      case 1:
        return const SafeArea(child: ReportScreen());
      case 2:
        return const SafeArea(child: BudgetScreen());
      case 3:
        return const SafeArea(child: ChallengeScreen());
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Image.asset(
            'lib/assets/paemotion_logo.png',
            height: 32,
            fit: BoxFit.contain,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (_selectedIndex == 3)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengeSearchScreen()),
                );
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPageScreen()),
              ),
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
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: '예산'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '챌린지'),
        ],
      ),
    );
  }
}
