import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MpPwResetScreen extends StatefulWidget {
  const MpPwResetScreen({super.key});

  @override
  State<MpPwResetScreen> createState() => _MpPwResetScreenState();
}

class _MpPwResetScreenState extends State<MpPwResetScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 상태가 아닙니다.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: _currentPasswordController.text.trim(),
    );

    try {
      // 재인증
      await user.reauthenticateWithCredential(cred);

      // 비밀번호 업데이트
      await user.updatePassword(_newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 성공적으로 변경되었습니다.')),
      );

      Navigator.pop(context); // 변경 후 뒤로 가기
    } on FirebaseAuthException catch (e) {
      String message = '비밀번호 변경 실패';

      if (e.code == 'wrong-password') {
        message = '현재 비밀번호가 틀렸습니다.';
      } else if (e.code == 'weak-password') {
        message = '새 비밀번호가 너무 약합니다.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 변경')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: '현재 비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureCurrent = !_obscureCurrent;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value != null && value.length >= 6 ? null : '현재 비밀번호를 입력하세요',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: '새 비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureNew = !_obscureNew;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value != null && value.length >= 6 ? null : '비밀번호는 6자 이상이어야 합니다',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: '새 비밀번호 확인',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirm = !_obscureConfirm;
                      });
                    },
                  ),
                ),
                validator: (value) => value == _newPasswordController.text
                    ? null
                    : '비밀번호가 일치하지 않습니다',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('비밀번호 변경'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

