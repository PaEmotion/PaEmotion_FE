import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'login_screen.dart';
import 'aichat_screen.dart';
import 'report_screen.dart';
import 'budget_screen.dart';
import 'challenge_screen.dart';

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

    // 첫 화면에서는 하단바 visible
    _controller.reverse(from: 1.0);

    _scrollController.addListener(() {
      final direction = _scrollController.position.userScrollDirection;

      if (direction == ScrollDirection.reverse) {
        // 스크롤 내릴 때 하단바 invisible
        if (_controller.status != AnimationStatus.forward && _controller.status != AnimationStatus.completed) {
          _controller.forward();
        }
      } else if (direction == ScrollDirection.forward) {
        // 스크롤 올릴 때 하단바 visible
        if (_controller.status != AnimationStatus.reverse && _controller.status != AnimationStatus.dismissed) {
          _controller.reverse();
        }
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // 페이지 전환 시 스크롤 위치 초기화
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PaEmotion',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: _pages[_selectedIndex],
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
