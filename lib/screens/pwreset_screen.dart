import 'package:flutter/material.dart';
import '../api/api_client.dart';

class PwResetScreen extends StatefulWidget {
  const PwResetScreen({super.key});

  @override
  State<PwResetScreen> createState() => _MpPwResetScreenState();
}

class _MpPwResetScreenState extends State<PwResetScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _status;

  Future<void> _sendResetRequest() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _status = '이메일을 입력하세요.');
      return;
    }

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final response = await ApiClient.dio.post(
        '/request-password-reset',
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        setState(() => _status = '비밀번호 재설정 이메일을 보냈습니다. 메일함을 확인하세요.');
      } else {
        final msg = response.data?['message'] ?? '알 수 없는 오류가 발생했습니다.';
        setState(() => _status = '실패: $msg');
      }
    } catch (e) {
      setState(() => _status = '네트워크 오류가 발생했습니다. 다시 시도하세요.');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    double fontSize;
    double buttonHeight;
    EdgeInsetsGeometry padding;

    if (width < 350) {
      fontSize = 14;
      buttonHeight = 40;
      padding = const EdgeInsets.symmetric(horizontal: 12);
    } else if (width < 600) {
      fontSize = 16;
      buttonHeight = 48;
      padding = const EdgeInsets.symmetric(horizontal: 24);
    } else {
      fontSize = 18;
      buttonHeight = 56;
      padding = const EdgeInsets.symmetric(horizontal: 40);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: Padding(
        padding: padding,
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: '이메일을 입력하세요',
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: fontSize),
            SizedBox(
              height: buttonHeight,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendResetRequest,
                child: _loading
                    ? SizedBox(
                  width: buttonHeight / 2,
                  height: buttonHeight / 2,
                  child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : Text(
                  '재설정 이메일 전송',
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            ),
            if (_status != null) ...[
              SizedBox(height: fontSize * 0.75),
              Text(
                _status!,
                style: TextStyle(
                  color: _status!.startsWith('실패') ? Colors.red : Colors.green,
                  fontSize: fontSize * 0.9,
                ),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/deeplink-failed-password');
              },
              child: Text(
                '이메일에 온 링크를 눌렀을 때 앱으로 연결이 되지 않은 경우',
                style: TextStyle(
                  fontSize: fontSize * 0.7,
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: fontSize * 0.9),
          ],
        ),
      ),
    );
  }
}