import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api_client.dart';

class DeepLinkPasswordScreen extends StatefulWidget {
  @override
  State<DeepLinkPasswordScreen> createState() => _DeepLinkPasswordScreenState();
}

class _DeepLinkPasswordScreenState extends State<DeepLinkPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _status;
  bool _loading = false;

  bool _containsSpecial(String s) {
    const special = '!@#\$%^&*()_+-={}[]:;\"\'<>,.?/\\|`~';
    for (var ch in s.split('')) {
      if (special.contains(ch)) return true;
    }
    return false;
  }

  String? _validatePassword(String pwd) {
    if (pwd.length < 8) return '비밀번호는 최소 8자 이상이어야 합니다.';
    if (!RegExp(r'[A-Za-z]').hasMatch(pwd)) return '영문자 최소 1개가 포함되어야 합니다.';
    if (!RegExp(r'\d').hasMatch(pwd)) return '숫자 최소 1개가 포함되어야 합니다.';
    if (!_containsSpecial(pwd)) return '특수문자 최소 1개가 포함되어야 합니다.';
    return null;
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _tokenController.text = data.text!.trim();
      });
    }
  }

  Future<void> _submit() async {
    final token = _tokenController.text.trim();
    final newPassword = _passwordController.text;

    if (token.isEmpty) {
      setState(() => _status = '이메일에서 복사한 토큰을 입력하거나 붙여넣으세요.');
      return;
    }
    if (newPassword.isEmpty) {
      setState(() => _status = '새 비밀번호를 입력하세요.');
      return;
    }
    final validationError = _validatePassword(newPassword);
    if (validationError != null) {
      setState(() => _status = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _status = null;
    });

    try {
      final response = await ApiClient.dio.post(
        '/users/reset-password',
        data: {
          'token': token,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        setState(() => _status = '비밀번호가 성공적으로 변경되었습니다. 로그인 화면으로 이동합니다.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        });
      } else {
        final msg = response.data?['message'] ?? response.statusMessage;
        setState(() => _status = '실패: $msg\n(토큰이 만료됐거나 잘못된 경우 다시 요청하세요.)');
      }
    } catch (e) {
      setState(() => _status = '요청 중 오류가 발생했습니다. 네트워크를 확인하거나 다시 시도하세요.');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 재설정 (수동)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이메일에서 받은 토큰을 복사해서 아래에 붙여넣고 새 비밀번호를 설정하세요.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: '복사한 토큰',
                      hintText: '예: ABC123...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: _pasteFromClipboard, child: const Text('붙여넣기')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                hintText: '영문 + 숫자 + 특수문자 포함, 8자 이상',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('변경하기'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            TextButton(
              onPressed: _goToLogin,
              child: const Text('로그인 화면으로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}
