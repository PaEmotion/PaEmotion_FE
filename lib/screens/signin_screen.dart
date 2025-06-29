import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Firebase Auth import

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 1) 회원가입 함수
  Future<void> _signUp() async {

    if (_formKey.currentState!.validate()) {
      try {
        // 이메일/비밀번호로 회원가입 시도
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 닉네임은 User 프로필에 저장 가능 (optional)
        await userCredential.user!.updateDisplayName(_nicknameController.text.trim());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 완료!')),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );

      } on FirebaseAuthException catch (e) {
        // 여기서 에러 코드랑 메시지 출력
        print('FirebaseAuthException code: ${e.code}');
        print('FirebaseAuthException message: ${e.message}');

        String message = '회원가입 실패';
        if (e.code == 'weak-password') {
          message = '비밀번호가 너무 약합니다.';
        } else if (e.code == 'email-already-in-use') {
          message = '이미 가입된 이메일입니다.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      resizeToAvoidBottomInset: true,

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 이메일
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                value != null && value.contains('@') ? null : '올바른 이메일을 입력하세요',
              ),
              const SizedBox(height: 20),

              // 비밀번호
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value != null && value.length >= 6 ? null : '비밀번호는 6자 이상이어야 합니다',
              ),
              const SizedBox(height: 20),

              // 비밀번호 확인
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                value == _passwordController.text ? null : '비밀번호가 일치하지 않습니다',
              ),
              const SizedBox(height: 20),

              // 닉네임
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '닉네임을 입력하세요';
                  if (value.length > 6) return '닉네임은 6자 이하로 입력해주세요';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // 회원가입 버튼
              ElevatedButton(
                onPressed: _signUp, // 여기에 함수 연결
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}