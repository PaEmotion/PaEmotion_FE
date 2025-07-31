import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'utils/user_manager.dart';
import 'utils/authutils.dart'; // TokenCheckerWidget 등을 여기서 쓴다면 유지
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'api/api_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 사용자/토큰 로컬 초기화
  await UserManager().init();

  // 인터셉터 장착 (navigatorKey 넘겨서 401 시 다이얼로그/네비 지원)
  ApiClient.initInterceptor(navigatorKey);

  // ✅ 앱 시작 시 한 번 선제 토큰 갱신 (만료/임박 시만)
  await ApiClient.ensureValidAccessToken();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLoggedIn;

  @override
  void initState() {
    super.initState();
    _initLoginState();
  }

  /// 앱 첫 빌드 직전에 로그인 상태 확인 + 선제 리프레시 1회 더(로그인 상태일 때만)
  Future<void> _initLoginState() async {
    final loggedIn = UserManager().isLoggedIn;

    if (loggedIn) {
      try {
        // ✅ 초기 진입 타이밍 이슈 방지용으로 한 번 더 선제 refresh
        await ApiClient.ensureValidAccessToken();
      } catch (_) {
        // 실패해도 인터셉터에서 401 자동 처리됨
      }
    }

    if (!mounted) return;
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  void _handleLogout() async {
    await UserManager().logout();
    if (!mounted) return;
    setState(() {
      isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoggedIn == null) {
      // 초기화 중 로딩
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Colors.black.withOpacity(0.85),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      title: 'PaEmotion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,

      // ===== Light Theme =====
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
        ).copyWith(
          surface: Colors.white,
          surfaceBright: Colors.white,
          surfaceDim: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Colors.white,
          surfaceContainer: Colors.white,
          surfaceContainerHigh: Colors.white,
          surfaceContainerHighest: Colors.white,
          surfaceTint: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        textTheme: GoogleFonts.ibmPlexSansKrTextTheme(
          ThemeData.light().textTheme,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.black),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
      ),

      // ===== Dark Theme =====
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ).copyWith(
          surfaceTint: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: GoogleFonts.ibmPlexSansKrTextTheme(
          ThemeData.dark().textTheme,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Colors.white),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
      ),

      // 홈 위젯: 로그인 여부에 따라 분기
      home: TokenCheckerWidget(
        onLogout: _handleLogout,
        child: isLoggedIn! ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
