import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../api/api_client.dart';
import 'signinsuccess_screen.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  bool _isEmailVerified = false; // 이메일 인증 여부

  bool _hasEnglish(String input) => RegExp(r'[A-Za-z]').hasMatch(input);
  bool _hasDigit(String input) => RegExp(r'\d').hasMatch(input);
  bool _hasSpecialChar(String input) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input);
  bool _hasNoWhitespace(String input) => !RegExp(r'\s').hasMatch(input);

  // 이메일 인증 요청 함수 (백엔드 링크 받고 수정 필요)
  Future<void> _verifyEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력하세요')),
      );
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 이메일 형식이 아닙니다')),
      );
      return;
    }

    try {
      final response = await ApiClient.dio.post('/users/send-verification-email', data: {
        'email': email,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 메일이 발송되었습니다. 이메일을 확인하세요')),
        );
        setState(() {
          _isEmailVerified = false; // 인증 전 상태로 유지
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 요청 실패: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 요청 중 오류 발생: $e')),
      );
    }
  }

  // 이메일 인증 상태 확인 함수 (백엔드 링크 받고 수정 필요)
  Future<void> _checkEmailVerification() async {
    final email = _emailController.text.trim();
    try {
      final response = await ApiClient.dio.get('/users/check-email-verification', queryParameters: {
        'email': email,
      });

      if (response.statusCode == 200 && response.data['verified'] == true) {
        setState(() {
          _isEmailVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증이 완료되었습니다.')),
        );
      } else {
        setState(() {
          _isEmailVerified = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증이 아직 완료되지 않았습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 상태 확인 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 먼저 완료하세요')),
      );
      return;
    }

    try {
      final response = await ApiClient.dio.post(
        '/users/signup',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'name': _nameController.text.trim(),
          'nickname': _nicknameController.text.trim(),
        },
      );

      if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignInSuccessScreen()),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 존재하는 이메일입니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return '이메일을 입력하세요';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return '유효한 이메일 형식이 아닙니다';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          setState(() {
                            _isEmailVerified = false; // 이메일 변경 시 인증 초기화
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: double.infinity, // 부모 높이에 꽉차게
                      child: ElevatedButton(
                        onPressed: _verifyEmail,
                        child: const Text('인증하기'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(70, 48), // 필요에 따라 조절 가능
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Icon(
                    _isEmailVerified ? Icons.check_circle : Icons.error,
                    color: _isEmailVerified ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(_isEmailVerified ? '인증 완료' : '인증 필요'),
                  const SizedBox(width: 20),
                  if (!_isEmailVerified)
                    TextButton(
                      onPressed: _checkEmailVerification,
                      child: const Text('인증 상태 확인'),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // 이하 기존 비밀번호, 이름, 닉네임 폼 필드들...
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return '비밀번호를 입력하세요';
                  if (value.length < 8) return '8자 이상이어야 합니다';
                  if (!_hasEnglish(value)) return '영문자를 포함해야 합니다';
                  if (!_hasDigit(value)) return '숫자를 포함해야 합니다';
                  if (!_hasSpecialChar(value)) return '특수문자를 포함해야 합니다';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return '이름을 입력하세요';
                  if (value.length < 1 || value.length > 7) return '이름은 1자 이상 7자 이하입니다';
                  if (!_hasNoWhitespace(value)) return '띄어쓰기는 사용할 수 없습니다';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) return '닉네임을 입력하세요';
                  if (value.length < 1 || value.length > 7) return '닉네임은 1자 이상 7자 이하입니다';
                  if (!_hasNoWhitespace(value)) return '띄어쓰기는 사용할 수 없습니다';
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _signUp,
                  child: const Text('회원가입'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
