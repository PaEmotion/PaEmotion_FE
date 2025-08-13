import 'package:flutter/material.dart';

class WhiteLoadingFallbackApp extends StatelessWidget {
  const WhiteLoadingFallbackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
