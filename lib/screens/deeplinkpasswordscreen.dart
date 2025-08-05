import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import '../api/api_client.dart';
import '../utils/reactive_utils.dart';

class DeepLinkResetPasswordScreen extends StatefulWidget {
  final String? initialToken;

  const DeepLinkResetPasswordScreen({Key? key, this.initialToken}) : super(key: key);

  @override
  State<DeepLinkResetPasswordScreen> createState() => _DeepLinkResetPasswordScreenState();
}

class _DeepLinkResetPasswordScreenState extends State<DeepLinkResetPasswordScreen> {
  late final AppLinks _appLinks;
  StreamSubscription? _sub;
  String? _token;
  final _passwordController = TextEditingController();
  String? _status;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _token = widget.initialToken;
    _appLinks = AppLinks();
    _initInitialLink();
    _sub = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _handleUri(uri);
    }, onError: (_) {});
  }

  Future<void> _initInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleUri(uri);
    } catch (_) {}
  }

  void _handleUri(Uri uri) {
    final token = uri.queryParameters['token'];
    if (token != null && token.isNotEmpty) {
      setState(() {
        _token = token;
      });
    }
  }

  bool _containsSpecial(String s) {
    const special = '!@#\$%^&*()_+-={}[]:;\"\'<>,.?/\\|`~';
    for (var ch in s.split('')) {
      if (special.contains(ch)) return true;
    }
    return false;
  }

  String? _validatePassword(String pwd) {
    if (pwd.length < 8) return '비밀번호는 최소 8자 이상이어야 합니다.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(pwd);
    if (!hasLetter) return '영문자 최소 1개가 포함되어야 합니다.';
    final hasDigit = RegExp(r'\d').hasMatch(pwd);
    if (!hasDigit) return '숫자 최소 1개가 포함되어야 합니다.';
    if (!_containsSpecial(pwd)) return '특수문자 최소 1개가 포함되어야 합니다.';
    return null;
  }

  Future<void> _submit() async {
    if (_token == null) {
      setState(() => _status =
      '유효한 토큰이 감지되지 않았습니다. 비밀번호 재설정 이메일을 다시 요청해 주세요.');
      return;
    }
    final newPassword = _passwordController.text;
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
          'token': _token,
          'new_password': newPassword,
        },
      );

      if (response.statusCode == 200) {
        setState(() =>
        _status = '비밀번호가 성공적으로 변경되었습니다. 로그인 화면으로 이동합니다.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        });
      } else {
        final msg = response.data?['message'] ?? response.statusMessage;
        setState(() =>
        _status = '실패: $msg\n(링크가 만료되었거나 잘못된 경우 다시 요청하세요.)');
      }
    } catch (e) {
      setState(() =>
      _status = '요청 중 오류가 발생했습니다. 네트워크를 확인하거나 다시 시도하세요.');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _goRequestAgain() {
    Navigator.of(context).pushNamed('/pw-reset');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasToken = _token != null;
    final horizontalPadding = rWidth(context, 16);
    final spacingSmall = rHeight(context, 12);
    final spacingMedium = rHeight(context, 20);
    final inputRadius = rWidth(context, 10);
    final buttonHeight = rHeight(context, 48);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비밀번호 재설정',
          style: TextStyle(fontSize: rFont(context, 18), fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: spacingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasToken) ...[
              Text(
                '링크에서 토큰을 감지했습니다. 새 비밀번호를 입력하세요.',
                style: TextStyle(fontSize: rFont(context, 14)),
              ),
            ] else ...[
              Text(
                '유효한 재설정 링크가 감지되지 않았습니다.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rFont(context, 16),
                ),
              ),
              SizedBox(height: rHeight(context, 8)),
              Text(
                '링크가 만료됐거나 잘못 열렸을 수 있습니다. 아래 버튼을 눌러 비밀번호 재설정 이메일을 다시 요청하세요.',
                style: TextStyle(fontSize: rFont(context, 14)),
              ),
              SizedBox(height: rHeight(context, 8)),
              TextButton(
                onPressed: _goRequestAgain,
                child: Text(
                  '비밀번호 재설정 이메일 다시 요청',
                  style: TextStyle(fontSize: rFont(context, 14)),
                ),
              ),
              Divider(height: rHeight(context, 32)),
            ],
            SizedBox(height: spacingSmall / 2),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '새 비밀번호',
                hintText: '영문 + 숫자 + 특수문자 포함, 8자 이상',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(inputRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: rWidth(context, 14),
                  vertical: rHeight(context, 14),
                ),
              ),
              obscureText: true,
              style: TextStyle(fontSize: rFont(context, 14)),
            ),
            SizedBox(height: spacingMedium),
            SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(rWidth(context, 8)),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                  width: rWidth(context, 18),
                  height: rWidth(context, 18),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  '변경하기',
                  style: TextStyle(fontSize: rFont(context, 16)),
                ),
              ),
            ),
            if (_status != null) ...[
              SizedBox(height: rHeight(context, 12)),
              Text(
                _status!,
                style: TextStyle(color: Colors.red, fontSize: rFont(context, 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
