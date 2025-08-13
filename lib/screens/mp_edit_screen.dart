import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/user_storage.dart';

class MpEditScreen extends StatefulWidget {
  const MpEditScreen({super.key});

  @override
  State<MpEditScreen> createState() => _MpEditScreenState();
}

class _MpEditScreenState extends State<MpEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  bool _isLoading = false;

  double _responsiveFont(double base, BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.85, base * 1.4);
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 40, vertical: 24);
  }

  double _buttonHeight(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return (height < 600) ? 44 : 52;
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentNickname();
  }

  Future<void> _loadCurrentNickname() async {
    final profileJson = await UserStorage.loadProfileJson();
    if (profileJson == null) {
      return;
    }
    final nickname = profileJson['nickname'] as String?;

    if (!mounted) return;
    setState(() {
      _nicknameController.text = nickname ?? '';
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
    final newNickname = _nicknameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final profileJson = await UserStorage.loadProfileJson();
      if (profileJson == null) {
        return;
      }
      final user = User.fromJson(profileJson);

      final response = await ApiClient.dio.put(
        '/users/nickname',
        data: {'new_nickname': newNickname},
      );

      if (response.statusCode == 200) {
        final msg = response.data['message'] ?? '닉네임이 변경되었습니다.';

        final updatedUser = user.copyWith(
          nickname: newNickname,
        );

        await UserStorage.saveProfile(updatedUser);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );

        Navigator.pop(context, updatedUser);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
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
    final titleFont = _responsiveFont(20, context);
    final labelFont = _responsiveFont(16, context);
    final hintFont = _responsiveFont(14, context);
    final buttonFont = _responsiveFont(16, context);
    final verticalGap = 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '닉네임 수정',
          style: TextStyle(fontSize: titleFont, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _responsivePadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.vertical,
            ),
            child: IntrinsicHeight(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '변경할 닉네임을 입력해주세요.',
                    style: TextStyle(fontSize: labelFont, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: verticalGap),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: '닉네임',
                            hintText: '1자 이상 7자 이하, 공백 및 띄어쓰기 불가',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            counterText: '',
                          ),
                          maxLength: 7,
                          style: TextStyle(fontSize: hintFont),
                          validator: _validateNickname,
                        ),
                        SizedBox(height: verticalGap * 1.2),
                        SizedBox(
                          height: _buttonHeight(context),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveNickname,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 0),
                            ),
                            child: Text(
                              '저장',
                              style: TextStyle(
                                fontSize: buttonFont,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
