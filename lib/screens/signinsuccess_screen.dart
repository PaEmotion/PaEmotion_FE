import 'package:flutter/material.dart';

class SignInSuccessScreen extends StatelessWidget {
  const SignInSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double fontSize;
    EdgeInsets padding;
    double buttonFontSize;
    EdgeInsets buttonPadding;

    if (width < 350) {
      fontSize = 18;
      padding = const EdgeInsets.all(16);
      buttonFontSize = 14;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    } else if (width < 600) {
      fontSize = 22;
      padding = const EdgeInsets.all(24);
      buttonFontSize = 16;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 32, vertical: 14);
    } else {
      fontSize = 26;
      padding = const EdgeInsets.all(32);
      buttonFontSize = 18;
      buttonPadding = const EdgeInsets.symmetric(horizontal: 40, vertical: 16);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 완료')),
      body: Center(
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '회원가입이 완료되었습니다!',
                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: fontSize * 1.5),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: buttonPadding,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  '로그인 하러 가기',
                  style: TextStyle(fontSize: buttonFontSize),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}