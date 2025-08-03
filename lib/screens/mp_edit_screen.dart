import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/user_storage.dart';
import 'mypage_screen.dart';

class MpEditScreen extends StatefulWidget {
  const MpEditScreen({super.key});

  @override
  State<MpEditScreen> createState() => _MpEditScreenState();
}

class _MpEditScreenState extends State<MpEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentNickname();
  }

  Future<void> _loadCurrentNickname() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');

    if (jsonString == null) return;

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);

    setState(() {
      _nicknameController.text = user.nickname ?? '';
    });
  }

  String? _validateNickname(String? value) {
    if (value == null || value.isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (value.length < 1 || value.length > 7) {
      return '닉네임은 1자 이상 7자 이하만 가능합니다.';
    }
    if (value.contains(' ')) {
      return '닉네임에 띄어쓰기는 허용되지 않습니다.';
    }
    return null;
  }

  Future<void> _saveNickname() async {
    if (!_formKey.currentState!.validate()) return;

    final newNickname = _nicknameController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user');
      if (jsonString == null) throw Exception('사용자 정보가 없습니다.');

      final userMap = jsonDecode(jsonString);
      final user = User.fromJson(userMap);


      final response = await ApiClient.dio.put(
        '/users/nickname',
        data: {'new_nickname': newNickname},
      );

      if (response.statusCode == 200) {

        final msg = response.data['message'] ?? '닉네임이 변경되었습니다.';

        final updatedUser = User(
          id: user.id,
          email: user.email,
          accessToken: user.accessToken,
          name: user.name,
          nickname: newNickname,
          refreshToken: user.refreshToken,
        );

        await UserStorage.saveUser(updatedUser);


        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MyPageScreen()),
              (route) => false,
        );
        Navigator.pop(context);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('닉네임 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: '변경할 닉네임',
                  hintText: '1자 이상 7자 이하, 공백 및 띄어쓰기 불가',
                  border: OutlineInputBorder(),
                ),
                validator: _validateNickname,
                maxLength: 7,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveNickname,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
