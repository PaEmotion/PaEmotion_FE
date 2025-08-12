import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = screenHeight * 0.05;

    final pageDecoration = PageDecoration(
      titleTextStyle: const TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold),
      bodyTextStyle: const TextStyle(fontSize: 17.0),
      imageFlex: 3,
      bodyFlex: 1,
      bodyAlignment: Alignment.bottomCenter,
      imageAlignment: Alignment.center,
    );

    Widget buildImage(String assetName) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Image.asset(
          assetName,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      );
    }

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "PaEmotion에 오신 걸 환영합니다!",
          body: "당신의 소비를 감정과 함께 기록해보세요.",
          image: buildImage('lib/assets/onboarding1.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "감정 기반 소비 리포트",
          body: "어떤 감정을 느꼈을 때 지출이 많은지 확인하세요.",
          image: buildImage('lib/assets/onboarding2.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "카테고리별 통계",
          body: "카테고리별 지출 패턴을 쉽게 확인하세요.\n다음주 지출 예측을 확인하고,\n미리 소비 계획을 세워보세요.",
          image: buildImage('lib/assets/onboarding3.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "챌린지 기능",
          body: "친구와 같은 목표를 향하여 소비 챌린지를 즐겨보세요.",
          image: buildImage('lib/assets/onboarding4.png'),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "이제 시작해볼까요?",
          body: "PaEmotion에 오신 걸 환영합니다.",
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      showSkipButton: true,
      skip: const Text("건너뛰기"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("시작하기", style: TextStyle(fontWeight: FontWeight.w600)),
      dotsDecorator: const DotsDecorator(
        activeColor: Colors.blue,
      ),
    );
  }
}
