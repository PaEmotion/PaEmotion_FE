import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/test_traits_data.dart';

class TestResultScreen extends StatefulWidget {
  final Map<String, int> scores;

  const TestResultScreen({super.key, required this.scores});

  @override
  _TestResultScreenState createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  late String topTraitKey;

  @override
  void initState() {
    super.initState();
    _calculateTopTrait();
    _saveResult();
  }

  void _calculateTopTrait() {
    final sortedScores = widget.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    topTraitKey = sortedScores.isNotEmpty ? sortedScores.first.key : 'minimal';
  }

  Future<void> _saveResult() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    await prefs.setString('last_test_result_key', topTraitKey);
    await prefs.setString('last_test_result_time', now);
  }

  void _restartTest() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final trait = traitInfos.firstWhere(
          (t) => t.key == topTraitKey,
      orElse: () => traitInfos.last,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('소비성향 테스트 결과'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '당신의 소비 유형은?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 20),

            // 이미지 표시 부분
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                trait.imagePath,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              trait.title,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            Text(
              trait.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.left,
            ),

            const SizedBox(height: 40),

            Text(
              trait.summary,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: Colors.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            ElevatedButton(
              onPressed: _restartTest,
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text(
                '테스트 다시하기',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
    );
  }
}
