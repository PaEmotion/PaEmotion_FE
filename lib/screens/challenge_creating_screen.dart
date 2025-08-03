import 'package:flutter/material.dart';
import 'package:paemotion/utils/challenge_utils.dart';
import 'challenge_creating_success_screen.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

class ChallengeCreatingScreen extends StatefulWidget {
  const ChallengeCreatingScreen({super.key});

  @override
  State<ChallengeCreatingScreen> createState() => _ChallengeCreatingScreenState();
}

class _ChallengeCreatingScreenState extends State<ChallengeCreatingScreen> {
  String? _challengeType;
  String? _concept;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordValid(String password) {
    final lengthCheck = password.length >= 8;
    final letterCheck = RegExp(r'[A-Za-z]').hasMatch(password);
    final numberCheck = RegExp(r'\d').hasMatch(password);
    final specialCheck = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    return lengthCheck && letterCheck && numberCheck && specialCheck;
  }

  void _handleCreate() async {
    if (_titleController.text.isEmpty || _countController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 필드를 입력해주세요.')),
      );
      return;
    }

    if (_challengeType == 'private') {
      final pwd = _passwordController.text;
      if (!_isPasswordValid(pwd)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호는 8자 이상이며, 영문자, 숫자, 특수문자를 모두 포함해야 합니다.')),
        );
        return;
      }
    }

    final bool challengeTypeBool = _concept == 'feed';
    final bool publicityTypeBool = _challengeType == 'public';
    final int goalCount = _countController.text.isEmpty ? 0 : int.parse(_countController.text);

    final Response? response = await ChallengeService.createChallenge(
      name: _titleController.text,
      challengeType: challengeTypeBool,
      publicityType: publicityTypeBool,
      password: _challengeType == 'private' ? _passwordController.text : null,
      goalCount: goalCount,
    );

    if (response != null) {
      print('=== 챌린지 생성 응답 전체 ===');
      print('statusCode: ${response.statusCode}');
      print('headers: ${response.headers}');
      print('data: ${response.data}');
      print('requestOptions: ${response.requestOptions}');
    } else {
      print('response가 null입니다.');
    }

    if (response == null || (response.statusCode != 201)) {
      String errorMsg = '챌린지 생성에 실패했습니다. 다시 시도해주세요.';
      if (response != null && response.data != null) {
        errorMsg += '\n서버 메시지: ${response.data}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
      return;
    }

    final data = response.data;
    final int? createdChallengeId = data['challengeId'];
    final String message = data['message'] ?? '챌린지가 성공적으로 생성되었습니다!';


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeCreatingSuccessScreen(message: message),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('챌린지 생성하기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '챌린지 유형을 선택해주세요.',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRadio('공개', 'public', _challengeType, (val) {
                  setState(() => _challengeType = val);
                }),
                const SizedBox(width: 16),
                _buildRadio('비공개 (프라이빗)', 'private', _challengeType, (val) {
                  setState(() => _challengeType = val);
                }),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '챌린지의 컨셉을 선택해주세요.',
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            const SizedBox(height: 12),
            _buildRadioWithDesc(
              '기니피그 밥 주기',
              'feed',
              '긍정적 감정으로 인한 소비를 늘리는 목표를 달성하고\n기니피그에게 밥을 주는 챌린지',
              _concept,
                  (val) {
                setState(() {
                  _concept = val;
                });
              },
            ),
            const SizedBox(height: 12),
            _buildRadioWithDesc(
              '기니피그 밥 지켜주기',
              'protect',
              '부정적 감정으로 인한 소비를 줄이는 목표를 달성하고\n기니피그의 밥을 지켜주는 챌린지',
              _concept,
                  (val) {
                setState(() {
                  _concept = val;
                });
              },
            ),
            if (_challengeType != null && _concept != null) _buildDetailsForm(),
            const SizedBox(height: 40),
            if (_challengeType != null && _concept != null)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _handleCreate,
                  child: const Text('챌린지 생성하기', style: TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(String label, String value, String? groupValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRadioWithDesc(String label, String value, String description,
      String? groupValue, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('챌린지 제목을 입력해주세요.'),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          maxLength: 30,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade400,
                width: 3.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey.shade600,
                width: 3.0,
              ),
            ),
            hintText: '예: 주간 감정소비 조절하기',
          ),
        ),

        const SizedBox(height: 24),
        const Text('챌린지의 목표를 입력해주세요.'),
        const SizedBox(height: 12),

        Text(
          _concept == 'feed'
              ? '긍정적 감정으로 인한 소비를'
              : '부정적 감정으로 인한 소비를',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),

        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              flex: 3,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 허용
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.black87,
                      width: 2.0,
                    ),
                  ),
                  hintText: '숫자',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 5,
              child: Text(_concept == 'feed' ? '개 하기' : '개 이하로 하기'),
            ),
          ],
        ),

        if (_challengeType == 'private') ...[
          const SizedBox(height: 24),
          const Text('챌린지 입장 비밀번호를 지정해주세요'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.black87,
                  width: 2.0,
                ),
              ),
              hintText: '영문, 숫자, 특수문자 포함 8자 이상',
            ),
          ),
        ],
      ],
    );
  }

}
