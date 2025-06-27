import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';  // 이 파일을 따로 만들어야 함 (아래 참고)


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 2. 플러터 바인딩 초기화
  await Firebase.initializeApp(); // 3. 파이어베이스 초기화
  runApp(const MyApp()); // 4. 앱 실행
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '감정소비 트래커',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),  // 여기서 SplashScreen 호출
    );
  }
}
