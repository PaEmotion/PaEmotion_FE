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
      MaterialPageRoute(builder: (context) => const TestMainScreen()),
    );
  }

  double _responsiveFontSize(BuildContext context, double baseSize) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = baseSize * scale;
    return computed.clamp(baseSize * 0.8, baseSize * 1.5);
  }

  double _responsiveWidth(BuildContext context, double baseWidth) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseWidth * 0.7;
    if (width < 480) return baseWidth * 0.85;
    if (width > 700) return baseWidth * 1.1;
    return baseWidth;
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 24, vertical: 32);
    return const EdgeInsets.symmetric(horizontal: 28, vertical: 36);
  }

  double _responsiveButtonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 44;
    if (width < 600) return 52;
    return 60;
  }

  @override
  Widget build(BuildContext context) {
    final trait = traitInfos.firstWhere(
          (t) => t.key == topTraitKey,
      orElse: () => traitInfos.last,
    );

    final padding = _responsivePadding(context);
    final imageSize = _responsiveWidth(context, 260);
    final titleFontSize = _responsiveFontSize(context, 30);
    final descFontSize = _responsiveFontSize(context, 15);
    final summaryFontSize = _responsiveFontSize(context, 20);
    final buttonHeight = _responsiveButtonHeight(context);

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
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '당신의 소비 유형은?',
                style: TextStyle(
                  fontSize: _responsiveFontSize(context, 24),
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: padding.vertical),

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
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: padding.vertical),

              Text(
                trait.title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: padding.vertical * 0.85),

              Text(
                trait.description,
                style: TextStyle(
                  fontSize: descFontSize,
                  height: 1.6,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: padding.vertical * 1.2),

              Text(
                trait.summary,
                style: TextStyle(
                  fontSize: summaryFontSize,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: padding.vertical * 1.8),

              SizedBox(
                width: double.infinity,
                height: buttonHeight,
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
                  child: Text(
                    '테스트 다시하기',
                    style: TextStyle(
                      fontSize: summaryFontSize,
                      fontWeight: FontWeight.w600,
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