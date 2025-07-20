import 'package:flutter/material.dart';
import 'test_question_screen.dart';

class TestMainScreen extends StatelessWidget {
  const TestMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '소비성향 테스트',
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 제목 (큰 글씨)
            Text(
              '나의 소비 스타일은 무엇일까?\n소비성향 테스트',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.deepPurple.shade900,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // 설명 (작은 글씨)
            Text(
              '당신의 소비 습관, 알아보고 싶지 않으신가요?\n'
                  '커피 한 잔, 충동구매, 탕진잼, 덕질, 계획소비까지—\n'
                  '우리가 매일 하는 “소비” 속엔 성향이 숨어 있어요.\n'
                  '10문항으로 나만의 소비 스타일을 알아보세요.',

              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // 시작 버튼 (검은색 기다란 버튼)
            SizedBox(
              width: double.infinity,
              height: 54,
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
                child: const Text(
                  '테스트 시작하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
    );
  }
}
