import 'package:flutter/material.dart';
import 'dart:async';
import 'start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 2초 후 StartScreen으로 이동
    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StartScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],  // 배경색 조절 가능
      body: Center(
        child: Container(
          width: 277,
          height: 595,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0x3F000000),
                blurRadius: 4,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 72,
                top: 191,
                child: Container(
                  width: 134,
                  height: 134,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 134,
                          height: 134,
                          clipBehavior: Clip.antiAlias,
                          decoration: ShapeDecoration(
                            color: const Color(0xFFEFEFF0),
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                width: 2,
                                color: Color(0xFFAEB0B6),
                              ),
                              borderRadius: BorderRadius.circular(200),
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: 55,
                                top: 55,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    children: const [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        child: SizedBox(width: 24, height: 24),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 58,
                top: 378,
                child: SizedBox(
                  width: 159,
                  height: 48,
                  child: Text(
                    'PaEmotion',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 32,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 0.62,
                      letterSpacing: 0.32,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 23,
                top: 452,
                child: SizedBox(
                  width: 229,
                  height: 54,  // 두 줄이라 높이 늘림
                  child: Text(
                    '소비에 감정을 더하고, \nAI로 돌아보는 소비습관 리마인드 앱',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w500,
                      height: 1.43,
                      letterSpacing: 0.14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
