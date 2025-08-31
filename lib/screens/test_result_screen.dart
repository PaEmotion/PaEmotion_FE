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
    return computed.clamp(baseSize * 0.75, baseSize * 1.2);
  }

  double _responsiveWidth(BuildContext context, double baseWidth) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return baseWidth * 0.7;
    if (width < 480) return baseWidth * 0.85;
    if (width > 700) return baseWidth * 1.0;
    return baseWidth;
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 20, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 28);
  }

  double _responsiveButtonHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 44;
    if (width < 600) return 50;
    return 54;
  }

  @override
  Widget build(BuildContext context) {
    final trait = traitInfos.firstWhere(
          (t) => t.key == topTraitKey,
      orElse: () => traitInfos.last,
    );

    final padding = _responsivePadding(context);
    final imageSize = _responsiveWidth(context, 220);
    final titleFontSize = _responsiveFontSize(context, 24);
    final descFontSize = _responsiveFontSize(context, 14);
    final summaryFontSize = _responsiveFontSize(context, 18);
    final buttonHeight = _responsiveButtonHeight(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '소비성향 테스트 결과',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
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
                  fontSize: _responsiveFontSize(context, 20),
                  fontWeight: FontWeight.w700,
                  color: Colors.deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: padding.vertical),

              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
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
              SizedBox(height: padding.vertical * 0.7),

              Text(
                trait.description,
                style: TextStyle(
                  fontSize: descFontSize,
                  height: 1.5,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: padding.vertical * 1.0),

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
              SizedBox(height: padding.vertical * 1.5),

              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: _restartTest,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.deepPurple),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    )),
                    elevation: MaterialStateProperty.all(4),
                    shadowColor: MaterialStateProperty.all(
                        Colors.deepPurple.withOpacity(0.4)),
                  ),
                  child: Text(
                    '테스트 다시하기',
                    style: TextStyle(
                      fontSize: summaryFontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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