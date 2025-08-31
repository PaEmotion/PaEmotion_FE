import 'package:flutter/material.dart';
import 'test_question_screen.dart';

class TestMainScreen extends StatelessWidget {
  const TestMainScreen({super.key});

  double _responsiveFont(BuildContext context, double base) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.75, base * 1.2);
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 14, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 24);
  }

  double _buttonHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height < 600) ? 44 : 50;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = _responsivePadding(context);
    final headlineFontSize = _responsiveFont(context, 20);
    final bodyFontSize = _responsiveFont(context, 12);
    final buttonFontSize = _responsiveFont(context, 16);
    final buttonHeight = _buttonHeight(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '소비성향 테스트',
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '나의 소비 스타일은 무엇일까?\n소비성향 테스트',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: headlineFontSize,
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade900,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding.vertical / 2),
            Text(
              '당신의 소비 습관, 알아보고 싶지 않으신가요?\n'
                  '커피 한 잔, 충동구매, 탕진잼, 덕질, 계획소비까지—\n'
                  '우리가 매일 하는 “소비” 속엔 성향이 숨어 있어요.\n'
                  '10문항으로 나만의 소비 스타일을 알아보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: bodyFontSize,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: padding.vertical),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TestQuestionScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '테스트 시작하기',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}