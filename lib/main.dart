import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'utils/user_manager.dart';
import 'utils/authutils.dart';
import 'screens/login_screen.dart';
import 'screens/pwreset_screen.dart';
import 'screens/home_screen.dart';
import 'screens/deeplinkpasswordscreen.dart';
import 'api/api_client.dart';
import 'screens/onboarding.dart';
import 'utils/email_verification_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  var connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    runApp(const OfflineApp());
    return;
  }

  await UserManager().init();
  ApiClient.initInterceptor(navigatorKey);
  await ApiClient.ensureValidAccessToken();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmailVerificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
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
  bool? _hasSeenOnboarding;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription? _sub;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Uri? _initialUri;
  String? _deepLinkToken;
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
    if (!mounted) return;
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
        _processDeepLink(uri);
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen(
          (Uri? uri) {
        if (uri != null) {
          _processDeepLink(uri);
        }
      },
      onError: (_) {},
    );
  }

  void _processDeepLink(Uri uri) {
    if (!mounted) return;

    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushNamed(
            '/reset-password',
            arguments: token,
          );
        });
      }
    } else if (uri.path == '/verify-email') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        final provider = Provider.of<EmailVerificationProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        provider.setToken(token);
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          const SnackBar(content: Text('이메일 인증 완료! 계속 회원가입을 진행해주세요.')),
        );
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

    String initialRoute = '/home';

    if (_deepLinkToken != null) {
      initialRoute = '/reset-password';
    } else if (_hasSeenOnboarding == false) {
      initialRoute = '/onboarding';
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PaEmotion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      onGenerateRoute: (settings) {
        // 딥링크로 들어온 경우
        if (_deepLinkToken != null && settings.name == '/reset-password') {
          return MaterialPageRoute(
            builder: (_) => DeepLinkResetPasswordScreen(initialToken: _deepLinkToken),
          );
        }

        // 온보딩을 아직 안 본 경우
        if (_hasSeenOnboarding == false) {
          return MaterialPageRoute(
            builder: (_) => const OnboardingScreen(),
          );
        }

        // 로그인 상태에 따라 분기
        if (isLoggedIn == true) {
          return MaterialPageRoute(
            builder: (_) => TokenCheckerWidget(
              onLogout: _handleLogout,
              child: const HomeScreen(),
            ),
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          );
        }
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/pw-reset': (context) => const PwResetScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        // '/reset-password'는 onGenerateRoute에서 처리하므로 생략 가능
      },
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
