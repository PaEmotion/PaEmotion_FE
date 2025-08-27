import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_endpoints/user_api.dart';

class MpPwResetScreen extends StatefulWidget {
  const MpPwResetScreen({super.key});

  @override
  State<MpPwResetScreen> createState() => _MpPwResetScreenState();
}

class _MpPwResetScreenState extends State<MpPwResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  bool _isLoading = false;

  bool _obscureCurrentPw = true;
  bool _obscureNewPw = true;

  double _responsiveFont(double base) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.85, base * 1.4);
  }

  EdgeInsets _responsivePadding() {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  double _buttonHeight() {
    final height = MediaQuery.of(context).size.height;
    return (height < 600) ? 44 : 52;
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.dio.put(
        UserApi.updatePassword,
        data: {
          'current_password': _currentPwController.text.trim(),
          'new_password': _newPwController.text.trim(),
        },
      );

      if (response.statusCode == 200) {
        final msg = response.data['message'] ?? '비밀번호가 변경되었습니다.';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.of(context).pop();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호 변경 실패')),
        );
      }
    } on DioError catch (e) {
      String msg = '오류가 발생했습니다. 다시 시도해주세요.';
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        if (data['detail'] != null) msg = data['detail'];
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelFontSize = _responsiveFont(16);
    final buttonFontSize = _responsiveFont(16);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '비밀번호 변경',
          style: TextStyle(fontSize: _responsiveFont(20), fontWeight: FontWeight.w600),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _responsivePadding(),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _currentPwController,
                  obscureText: _obscureCurrentPw,
                  decoration: InputDecoration(
                    labelText: '현재 비밀번호',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPw ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrentPw = !_obscureCurrentPw;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '현재 비밀번호를 입력하세요';
                    }
                    return null;
                  },
                  style: TextStyle(fontSize: labelFontSize),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPwController,
                  obscureText: _obscureNewPw,
                  decoration: InputDecoration(
                    labelText: '새 비밀번호',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPw ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPw = !_obscureNewPw;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '새 비밀번호를 입력하세요';
                    }
                    return null;
                  },
                  style: TextStyle(fontSize: labelFontSize),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: _buttonHeight(),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      '변경하기',
                      style: TextStyle(color: Colors.white, fontSize: buttonFontSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}