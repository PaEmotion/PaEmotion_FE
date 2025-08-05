import 'package:flutter/material.dart';

class RecordSuccessScreen extends StatelessWidget {
  const RecordSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double iconSize;
    double titleFontSize;
    double subtitleFontSize;
    EdgeInsetsGeometry buttonPadding;
    double buttonFontSize;

    if (width < 350) {
      iconSize = 70;
      titleFontSize = 18;
      subtitleFontSize = 12;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      buttonFontSize = 14;
    } else if (width < 600) {
      iconSize = 100;
      titleFontSize = 20;
      subtitleFontSize = 14;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14);
      buttonFontSize = 16;
    } else {
      iconSize = 140;
      titleFontSize = 24;
      subtitleFontSize = 16;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 40, vertical: 16);
      buttonFontSize = 18;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('기록 완료'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: iconSize),
            SizedBox(height: iconSize * 0.2),
            Text(
              '기록이 저장되었어요!',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: iconSize * 0.1),
            Text(
              '홈화면에서 소비 기록을 확인할 수 있어요.',
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: iconSize * 0.3),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: buttonPadding,
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text(
                '홈으로 돌아가기',
                style: TextStyle(fontSize: buttonFontSize),
              ),
            ),
          ],
        ),
      ),
    );
  }
}