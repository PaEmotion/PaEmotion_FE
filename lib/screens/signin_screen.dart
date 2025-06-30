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

  bool _hasEnglish(String input) => RegExp(r'[A-Za-z]').hasMatch(input);
  bool _hasDigit(String input) => RegExp(r'\d').hasMatch(input);
  bool _hasSpecialChar(String input) => RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input);
  bool _hasNoWhitespace(String input) => !RegExp(r'\s').hasMatch(input);

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

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

      if (response.statusCode == 200) {
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
              // 이메일
              TextFormField(
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

              // 비밀번호 확인
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

              // 이름
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

              // 닉네임
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

              ElevatedButton(
                onPressed: _signUp,
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
