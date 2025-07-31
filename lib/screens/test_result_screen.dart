import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/test_traits_data.dart';
import 'test_main_screen.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => TestMainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trait = traitInfos.firstWhere(
          (t) => t.key == topTraitKey,
      orElse: () => traitInfos.last,
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('소비성향 테스트 결과'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '당신의 소비 유형은?',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 28),

              // 이미지 + 그림자 박스
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    trait.imagePath,
                    width: 260,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                trait.title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Text(
                trait.description,
                style: TextStyle(
                  fontSize: 17,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 36),

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

              const SizedBox(height: 52),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _restartTest,
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all(Colors.deepPurple),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    )),
                    elevation: MaterialStateProperty.all(6),
                    shadowColor: MaterialStateProperty.all(
                        Colors.deepPurple.withOpacity(0.5)),
                  ),
                  child: const Text(
                    '테스트 다시하기',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
