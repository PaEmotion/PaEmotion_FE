import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

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

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.dio.put(
        '/users/password',
        data: {
          'current_password': _currentPwController.text.trim(),
          'new_password': _newPwController.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final msg = response.data['message'] ?? '비밀번호가 변경되었습니다.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비밀번호 변경 실패: ${response.statusCode}')),
        );
      }
    } on DioError catch (e) {
      String msg = '오류가 발생했습니다.';
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        if (data['detail'] != null) msg = data['detail'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('알 수 없는 오류: $e')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 변경'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                      _obscureCurrentPw
                          ? Icons.visibility_off
                          : Icons.visibility,
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
                      _obscureNewPw
                          ? Icons.visibility_off
                          : Icons.visibility,
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
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    '변경하기',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}