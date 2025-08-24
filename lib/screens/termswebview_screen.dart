import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsWebViewPage extends StatelessWidget {
  final String url;
  const TermsWebViewPage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('약관 보기')),
      body: WebViewWidget(controller: WebViewController()..loadRequest(Uri.parse(url))),
    );
  }
}