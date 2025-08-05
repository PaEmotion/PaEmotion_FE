import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'home_screen.dart';
import 'signin_screen.dart';
import 'pwreset_screen.dart';
import '../utils/user_manager.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSubmitting = false;

  double _responsiveFont(double base, BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.9, base * 1.3);
  }

  EdgeInsets _horizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 60);
  }

  double _logoHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 40;
    if (width < 600) return 60;
    return 80;
  }

  Future<void> _signIn() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiClient.dio.post(
        '/users/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );

      debugPrint('[Login] statusCode: ${response.statusCode}');
      debugPrint('[Login] full response.data: ${response.data}');

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body['data'] ?? {};

        final accessToken = (data['access_token'] ?? '').toString();
        final refreshToken = (data['refresh_token'] ?? '').toString();

        if (accessToken.isEmpty || refreshToken.isEmpty) {
          throw Exception('토큰이 응답에 없습니다.');
        }

        final userJson = {
          'userId': data['userId'],
          'email': data['email'],
          'name': data['name'],
          'nickname': data['nickname'],
        };

        final user = User.fromJson(
          userJson,
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        await UserManager().setUser(user);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
      else {
        debugPrint('[Login] login failed with code ${response.statusCode}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${response.statusCode}')),
        );
      }
    } on DioException catch (e) {
      debugPrint('[Login] DioException: ${e.response?.statusCode} / ${e.response?.data} / ${e.message}');
      if (!mounted) return;
      if (e.response?.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 또는 비밀번호 오류')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러: ${e.message}')),
        );
      }
    } catch (e) {
      debugPrint('[Login] Exception: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('요청 실패: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final fontLarge = _responsiveFont(22, context);
    final fontNormal = _responsiveFont(16, context);
    final buttonHeight = 50.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          double horizontalPadding = 16;
          double fontSize = 16;

          if (width >= 600) {
            horizontalPadding = 60;
            fontSize = 20;
          } else if (width >= 360) {
            horizontalPadding = 32;
            fontSize = 18;
          }

          return Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 40,
              left: horizontalPadding,
              right: horizontalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                Center(
                  child: Image.asset(
                    'lib/assets/paemotion_logo.png',
                    height: width < 360
                        ? 40
                        : width < 600
                        ? 60
                        : 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: fontSize),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    border: const OutlineInputBorder(),
                    isDense: true,
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
                  style: TextStyle(fontSize: fontSize),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                        );
                      },
                      child: Text(
                        '회원가입',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PwResetScreen()),
                        );
                      },
                      child: Text(
                        '비밀번호 찾기',
                        style: TextStyle(fontSize: fontSize),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}
