import 'package:flutter/material.dart';

class ChallengeCreatingSuccessScreen extends StatelessWidget {
  final String message;

  const ChallengeCreatingSuccessScreen({super.key, required this.message});


  double rWidth(BuildContext context, double base) {
    final w = MediaQuery.of(context).size.width;
    return base * (w / 390);
  }


  double rHeight(BuildContext context, double base) {
    final h = MediaQuery.of(context).size.height;
    return base * (h / 844);
  }


  double rFont(BuildContext context, double base) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final w = MediaQuery.of(context).size.width;
    return base * scale * (w / 390);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = rWidth(context, 24);
    final buttonHeight = rHeight(context, 50);
    final buttonRadius = rWidth(context, 8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: rFont(context, 22),
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: rHeight(context, 60)),
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 성공 화면 닫고
                    Navigator.pop(context); // 챌린지 생성 화면 닫음
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonRadius),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    '챌린지 홈으로 돌아가기',
                    style: TextStyle(
                      fontSize: rFont(context, 16),
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
