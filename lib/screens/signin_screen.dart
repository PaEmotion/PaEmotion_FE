import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import 'signinsuccess_screen.dart';
import '../utils/email_verification_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

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

  bool _isEmailVerified = false;

  bool _hasEnglish(String input) => RegExp(r'[A-Za-z]').hasMatch(input);
  bool _hasDigit(String input) => RegExp(r'\d').hasMatch(input);
  bool _hasSpecialChar(String input) =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(input);
  bool _hasNoWhitespace(String input) => !RegExp(r'\s').hasMatch(input);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = Provider.of<EmailVerificationProvider>(context);
    final token = provider.token;

    if (token != null && !_isEmailVerified) {
      setState(() {
        _isEmailVerified = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 인증이 완료되었습니다!')),
        );
      });

      provider.clearToken();
    }
  }

  // 이메일 인증 요청
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
      final response = await ApiClient.dio.post('/request-email-verification',
          data: {'email': email});

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증 메일이 발송되었습니다. 이메일을 확인하세요')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 요청에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증 요청에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  // 인증 완료 후, 회원가입
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SignInSuccessScreen(),
          ),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final errorMessage = e.response?.data['message'] ?? '요청 오류가 발생했습니다.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 600;
          double formWidth = isWide ? 500 : double.infinity;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formWidth),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      isWide
                          ? IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(child: _buildEmailField()),
                            const SizedBox(width: 10),
                            _buildVerifyButton(),
                          ],
                        ),
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildEmailField(),
                          const SizedBox(height: 10),
                          _buildVerifyButton(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildEmailStatus(),

                      const SizedBox(height: 20),
                      _buildPasswordField(),
                      const SizedBox(height: 20),
                      _buildConfirmPasswordField(),
                      const SizedBox(height: 20),
                      _buildNameField(),
                      const SizedBox(height: 20),
                      _buildNicknameField(),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration:
      const InputDecoration(labelText: '이메일', border: OutlineInputBorder()),
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
          _isEmailVerified = false;
        });
      },
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: _verifyEmail,
        child: const Text('인증하기'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(70, 48)),
      ),
    );
  }

  Widget _buildEmailStatus() {
    return Row(
      children: [
        Icon(
          _isEmailVerified ? Icons.check_circle : Icons.email,
          color: _isEmailVerified ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(_isEmailVerified ? '인증 메일 발송 완료' : '이메일 인증 필요'),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
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
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
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
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration:
      const InputDecoration(labelText: '이름', border: OutlineInputBorder()),
      validator: (value) {
        if (value == null || value.isEmpty) return '이름을 입력하세요';
        if (value.length < 1 || value.length > 7) {
          return '이름은 1자 이상 7자 이하입니다';
        }
        if (!_hasNoWhitespace(value)) return '띄어쓰기는 사용할 수 없습니다';
        return null;
      },
    );
  }

  Widget _buildNicknameField() {
    return TextFormField(
      controller: _nicknameController,
      decoration: const InputDecoration(
          labelText: '닉네임', border: OutlineInputBorder()),
      validator: (value) {
        if (value == null || value.isEmpty) return '닉네임을 입력하세요';
        if (value.length < 1 || value.length > 7) {
          return '닉네임은 1자 이상 7자 이하입니다';
        }
        if (!_hasNoWhitespace(value)) return '띄어쓰기는 사용할 수 없습니다';
        return null;
      },
    );
  }
}