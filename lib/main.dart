import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'utils/user_manager.dart';
import 'utils/authutils.dart';
import 'screens/login_screen.dart';
import 'screens/pwreset_screen.dart';
import 'screens/deeplinkfaliedpasswordscreen.dart';
import 'screens/home_screen.dart';
import 'screens/deeplinkpasswordscreen.dart';
import 'api/api_client.dart';
import 'screens/onboarding.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 네트워크 연결 체크
  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    runApp(const OfflineApp());
    return;
  }

  // 사용자/토큰 로컬 초기화
  await UserManager().init();
  ApiClient.initInterceptor(navigatorKey);
  await ApiClient.ensureValidAccessToken();

  runApp(const MyApp());
}

class OfflineApp extends StatelessWidget {
  const OfflineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: AlertDialog(
            title: const Text('오프라인 상태입니다'),
            content: const Text('인터넷에 연결된 후 앱을 이용해주세요.'),
            actions: [
              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('종료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLoggedIn;
  bool? _hasSeenOnboarding; // onboarding seen check

  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Uri? _initialUri;
  bool _isOfflineDialogShown = false;

  @override
  void initState() {
    super.initState();
    _initLoginState();
    _initDeepLink();
    _listenConnectivityChanges();
    _checkOnboardingSeen();
  }

  Future<void> _checkOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenOnboarding') ?? false;
    setState(() {
      _hasSeenOnboarding = seen;
    });
  }

  Future<void> _initLoginState() async {
    await UserManager().init();
    if (!mounted) return;
    setState(() {
      isLoggedIn = UserManager().isLoggedIn;
    });
    if (isLoggedIn == true) {
      try {
        await ApiClient.ensureValidAccessToken();
      } catch (_) {}
    }
  }

  Future<void> _initDeepLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        setState(() {
          _initialUri = uri;
        });
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(uri);
      }
    }, onError: (_) {});
  }

  void _handleUri(Uri uri) {
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => DeepLinkResetPasswordScreen(initialToken: token),
        ));
      }
    }
  }

  void _handleLogout() async {
    await UserManager().logout();
    if (!mounted) return;
    setState(() {
      isLoggedIn = false;
    });
  }

  void _listenConnectivityChanges() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      final isOffline = (result == ConnectivityResult.none);

      if (isOffline && !_isOfflineDialogShown) {
        _isOfflineDialogShown = true;
        _showOfflineDialog();
      } else if (!isOffline && _isOfflineDialogShown) {
        _isOfflineDialogShown = false;
        // 온라인 복귀 시 다이얼로그 닫기
        if (navigatorKey.currentState?.canPop() ?? false) {
          navigatorKey.currentState?.pop();
        }
      }
    });
  }

  void _showOfflineDialog() {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('오프라인 상태입니다'),
        content: const Text('인터넷에 연결된 후 앱을 이용해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              SystemNavigator.pop();
            },
            child: const Text('종료'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasSeenOnboarding == null || isLoggedIn == null) {
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

    // 딥링크 비밀번호 재설정
    if (_initialUri?.path == '/reset-password') {
      final token = _initialUri!.queryParameters['token'];
      return MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/pw-reset': (context) => const PwResetScreen(),
          '/deeplink-failed-password': (context) => DeepLinkPasswordScreen(),
        },
        title: 'PaEmotion',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: DeepLinkResetPasswordScreen(initialToken: token),
      );
    }

    // 온보딩 안 봤으면 온보딩 화면 먼저
    if (_hasSeenOnboarding == false) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
        title: 'PaEmotion',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: const OnboardingScreen(),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/pw-reset': (context) => const PwResetScreen(),
        '/deeplink-failed-password': (context) => DeepLinkPasswordScreen(),
      },
      title: 'PaEmotion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: TokenCheckerWidget(
        onLogout: _handleLogout,
        child: isLoggedIn! ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
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
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
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
    );
  }
}
