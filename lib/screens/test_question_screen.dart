import 'package:flutter/material.dart';
import '../data/test_questions_data.dart';
import 'test_result_screen.dart';

class TestQuestionScreen extends StatefulWidget {
  const TestQuestionScreen({super.key});

  @override
  State<TestQuestionScreen> createState() => _TestQuestionScreenState();
}

class _TestQuestionScreenState extends State<TestQuestionScreen> {
  int currentIndex = 0;
  final Map<String, int> scores = {};

  void selectChoice(String traitKey) {
    setState(() {
      scores.update(traitKey, (value) => value + 1, ifAbsent: () => 1);

      if (currentIndex < testQuestions.length - 1) {
        currentIndex++;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TestResultScreen(scores: scores),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final question = testQuestions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '소비성향 테스트',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 질문 번호 + 총 개수
            Text(
              'Q${currentIndex + 1}.',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[700],
              ),
            ),
            const SizedBox(height: 8),

            // 질문 텍스트
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 20,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // 선택지
            Expanded(
              child: ListView.builder(
                itemCount: question.choices.length,
                itemBuilder: (context, idx) {
                  final choice = question.choices[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => selectChoice(choice.traitKey),
                      splashColor: Colors.deepPurple.withOpacity(0.2),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          choice.text,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}