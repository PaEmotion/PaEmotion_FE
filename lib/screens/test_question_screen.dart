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

  double _responsiveFontSize(BuildContext context, double baseSize) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = baseSize * scale;
    return computed.clamp(baseSize * 0.75, baseSize * 1.2);
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
  }

  double _maxChoiceWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 700) return 600;
    if (width > 500) return 450;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    final question = testQuestions[currentIndex];
    final padding = _responsivePadding(context);
    final questionNumberFontSize = _responsiveFontSize(context, 18);
    final questionTextFontSize = _responsiveFontSize(context, 16);
    final choiceTextFontSize = _responsiveFontSize(context, 14);
    final maxChoiceWidth = _maxChoiceWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '소비성향 테스트',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Q${currentIndex + 1}.',
              style: TextStyle(
                fontSize: questionNumberFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple[700],
              ),
            ),
            SizedBox(height: padding.vertical / 5),

            Text(
              question.questionText,
              style: TextStyle(
                fontSize: questionTextFontSize,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: padding.vertical / 1.5),

            Expanded(
              child: ListView.builder(
                itemCount: question.choices.length,
                itemBuilder: (context, idx) {
                  final choice = question.choices[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => selectChoice(choice.traitKey),
                      splashColor: Colors.deepPurple.withOpacity(0.2),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxChoiceWidth),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          choice.text,
                          style: TextStyle(
                            fontSize: choiceTextFontSize,
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
    );
  }
}