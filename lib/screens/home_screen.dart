import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'login_screen.dart';
import 'aichat_screen.dart';
import 'report_screen.dart';
import 'budget_screen.dart';
import 'challenge_screen.dart';
import 'mypage_screen.dart';
import 'record_screen.dart';
import 'record_list_screen.dart';
import '../models/record.dart';
import '../utils/record_storage.dart';

final numberFormat = NumberFormat('#,###');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  final ScrollController _scrollController = ScrollController();

  String? _userName;
  bool _isLoadingName = true;
  List<Record> _todaysRecords = [];

  final List<Widget> _pages = [
    const SizedBox(),
    const AIChatScreen(),
    const ReportScreen(),
    const BudgetScreen(),
    const ChallengeScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.reverse(from: 1.0);

    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;
      if (direction == ScrollDirection.reverse) {
        if (_controller.status != AnimationStatus.forward && _controller.status != AnimationStatus.completed) {
          _controller.forward();
        }
      } else if (direction == ScrollDirection.forward) {
        if (_controller.status != AnimationStatus.reverse && _controller.status != AnimationStatus.dismissed) {
          _controller.reverse();
        }
      }
    });

    _loadUserName();
    _loadTodayRecords();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        setState(() {
          _userName = null;
          _isLoadingName = false;
        });
        return;
      }

      final dio = Dio();
      final response = await dio.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        setState(() {
          _userName = data['name'];
          _isLoadingName = false;
        });
      } else {
        print('API 응답 오류: ${response.statusCode}');
        setState(() {
          _userName = null;
          _isLoadingName = false;
        });
      }
    } catch (e) {
      print('사용자 정보 로딩 실패: $e');
      setState(() {
        _userName = null;
        _isLoadingName = false;
      });
    }
  }

  Future<void> _loadTodayRecords() async {
    final allRecords = await RecordStorage.loadRecords();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final todayRecords = allRecords.where((record) {
      final recordDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(record.date));
      return recordDate == today;
    }).toList();

    setState(() {
      _todaysRecords = todayRecords;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _scrollController.jumpTo(0);
    if (index == 0) _loadTodayRecords();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Widget _buildPieChart() {
    final Map<String, double> categoryTotals = {};
    for (var record in _todaysRecords) {
      categoryTotals.update(
        record.category,
            (value) => value + record.amount.toDouble(),
        ifAbsent: () => record.amount.toDouble(),
      );
    }

    final List<PieChartSectionData> sections = categoryTotals.entries.map((entry) {
      final color = Colors.primaries[entry.key.hashCode % Colors.primaries.length];
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: entry.key,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            '오늘의 소비 기록이 없습니다.\n기록을 추가해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 5.0),
      child: SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            sections: sections.map((entry) => entry.copyWith(radius: 32)).toList(),
            centerSpaceRadius: 90,
            sectionsSpace: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final Map<String, List<Record>> groupedRecords = {};
    for (var record in _todaysRecords) {
      groupedRecords.putIfAbsent(record.category, () => []).add(record);
    }

    final int totalAmount = _todaysRecords.fold(0, (sum, r) => sum + r.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoadingName
              ? const CircularProgressIndicator()
              : (_userName != null
              ? Text(
            '${_userName!}님, 안녕하세요! 😊\n행운 가득한 하루 보내세요.',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          )
              : const SizedBox()),
        ),
        _buildPieChart(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecordScreen()),
                    ).then((_) => _loadTodayRecords());
                  },
                  child: const Text('기록 추가하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecordListScreen()),
                    ).then((_) => _loadTodayRecords());
                  },
                  child: const Text('소비기록 수정하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Text('📝 오늘의 소비 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        if (_todaysRecords.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('오늘의 기록이 없습니다.', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        else
          ...groupedRecords.entries.map((entry) {
            final category = entry.key;
            final records = entry.value;
            final categoryTotal = records.fold(0.0, (sum, r) => sum + r.amount);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Container(
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...records.map((record) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${record.item} ${numberFormat.format(record.amount)}원',
                          style: const TextStyle(fontSize: 14)),
                    )),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text('총 ${numberFormat.format(categoryTotal.toInt())}원',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        if (_todaysRecords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('오늘 총 ${numberFormat.format(totalAmount)}원을 소비했어요.',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isHomeTab = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PaEmotion',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPageScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isHomeTab)
              _buildHomeContent()
            else
              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: _pages[_selectedIndex],
              ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.black.withOpacity(0.1),
          highlightColor: Colors.black.withOpacity(0.05),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'AI채팅'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '리포트'),
            BottomNavigationBarItem(icon: Icon(Icons.wallet), label: '예산'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: '챌린지'),
          ],
        ),
      ),
    );
  }
}
