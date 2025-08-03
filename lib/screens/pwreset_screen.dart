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
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: '이메일을 입력하세요',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _sendResetRequest,
              child: _loading
                  ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('재설정 이메일 전송'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: TextStyle(color: _status!.startsWith('실패') ? Colors.red : Colors.green),
              ),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed('/deeplink-failed-password');
              },
              child: const Text(
                '이메일에 온 링크를 눌렀을 때 앱으로 연결이 되지 않은 경우',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
