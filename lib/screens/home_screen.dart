import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'aichat_screen.dart';
import 'report_screen.dart';
import 'budget_screen.dart';
import 'challenge_screen.dart';
import 'mypage_screen.dart';

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

  final List<Widget> _pages = [
    const Center(child: Text('홈 화면입니다.')),
    const AIChatScreen(),
    const ReportScreen(),
    const BudgetScreen(),
    const ChallengeScreen(),
  ];

  String? _userName;
  bool _isLoadingName = true;

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
        'http://localhost:8080/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
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


  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _scrollController.jumpTo(0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isHomeTab = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PaEmotion',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoadingName
                    ? const CircularProgressIndicator()
                    : (_userName != null
                    ? Text(
                  '${_userName!}님, 안녕하세요!',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                )
                    : const SizedBox()),
              ),
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