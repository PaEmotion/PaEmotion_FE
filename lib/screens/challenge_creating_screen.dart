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

  // 반응형 너비
  double rWidth(double base) {
    final w = MediaQuery.of(context).size.width;
    return base * (w / 390);
  }

  // 반응형 높이
  double rHeight(double base) {
    final h = MediaQuery.of(context).size.height;
    return base * (h / 844);
  }

  // 반응형 폰트 크기
  double rFont(double base) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final w = MediaQuery.of(context).size.width;
    return base * scale * (w / 390);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = rWidth(20);
    final spacingSmall = rHeight(8);
    final spacingMedium = rHeight(12);
    final spacingLarge = rHeight(24);
    final buttonHeight = rHeight(50);
    final borderRadius = rWidth(12);
    final buttonRadius = rWidth(8);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '챌린지 생성하기',
          style: TextStyle(fontSize: rFont(18), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: spacingMedium),
            Text(
              '챌린지 유형을 선택해주세요.',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: rFont(16),
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacingSmall),
            Row(
              children: [
                _buildRadio('공개', 'public', _challengeType, (val) {
                  setState(() => _challengeType = val);
                }),
                SizedBox(width: rWidth(16)),
                _buildRadio('비공개 (프라이빗)', 'private', _challengeType, (val) {
                  setState(() => _challengeType = val);
                }),
              ],
            ),
            SizedBox(height: spacingLarge),
            Text(
              '챌린지의 컨셉을 선택해주세요.',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: rFont(16),
                color: Colors.black87,
              ),
            ),
            SizedBox(height: spacingSmall),
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
              fontSizeLabel: rFont(16),
              fontSizeDesc: rFont(12),
              descPadding: rWidth(40),
            ),
            SizedBox(height: spacingSmall),
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
              fontSizeLabel: rFont(16),
              fontSizeDesc: rFont(12),
              descPadding: rWidth(40),
            ),
            if (_challengeType != null && _concept != null) _buildDetailsForm(borderRadius, spacingLarge, spacingSmall),
            SizedBox(height: rHeight(40)),
            if (_challengeType != null && _concept != null)
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(buttonRadius)),
                  ),
                  onPressed: _handleCreate,
                  child: Text(
                    '챌린지 생성하기',
                    style: TextStyle(fontSize: rFont(16), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(
      String label,
      String value,
      String? groupValue,
      ValueChanged<String?> onChanged, {
        double fontSize = 16,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
        ),
      ],
    );
  }

  Widget _buildRadioWithDesc(
      String label,
      String value,
      String description,
      String? groupValue,
      ValueChanged<String?> onChanged, {
        double fontSizeLabel = 16,
        double fontSizeDesc = 12,
        double descPadding = 40,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Radio<String>(value: value, groupValue: groupValue, onChanged: onChanged),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSizeLabel),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: descPadding),
          child: Text(description, style: TextStyle(fontSize: fontSizeDesc, color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildDetailsForm(double borderRadius, double spacingLarge, double spacingSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: spacingLarge),
        Text(
          '챌린지 제목을 입력해주세요.',
          style: TextStyle(fontSize: rFont(16), fontWeight: FontWeight.w500),
        ),
        SizedBox(height: spacingSmall),
        TextField(
          controller: _titleController,
          maxLength: 30,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.shade400,
                width: 3.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.shade600,
                width: 3.0,
              ),
            ),
            hintText: '예: 주간 감정소비 조절하기',
            contentPadding: EdgeInsets.symmetric(horizontal: rWidth(12), vertical: rHeight(14)),
          ),
          style: TextStyle(fontSize: rFont(16)),
        ),
        SizedBox(height: spacingLarge),
        Text(
          '챌린지의 목표를 입력해주세요.',
          style: TextStyle(fontSize: rFont(16), fontWeight: FontWeight.w500),
        ),
        SizedBox(height: spacingSmall),
        Text(
          _concept == 'feed'
              ? '긍정적 감정으로 인한 소비를'
              : '부정적 감정으로 인한 소비를',
          style: TextStyle(fontSize: rFont(16), color: Colors.black87),
        ),
        SizedBox(height: spacingSmall),
        Row(
          children: [
            Flexible(
              flex: 3,
              child: TextField(
                controller: _countController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: rWidth(12), vertical: rHeight(14)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: Colors.grey.shade400,
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide(
                      color: Colors.black87,
                      width: 2.0,
                    ),
                  ),
                  hintText: '숫자',
                ),
                style: TextStyle(fontSize: rFont(16)),
              ),
            ),
            SizedBox(width: rWidth(8)),
            Flexible(
              flex: 5,
              child: Text(
                _concept == 'feed' ? '개 하기' : '개 이하로 하기',
                style: TextStyle(fontSize: rFont(16)),
              ),
            ),
          ],
        ),
        if (_challengeType == 'private') ...[
          SizedBox(height: spacingLarge),
          Text(
            '챌린지 입장 비밀번호를 지정해주세요',
            style: TextStyle(fontSize: rFont(16), fontWeight: FontWeight.w500),
          ),
          SizedBox(height: spacingSmall),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1.8,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: Colors.black87,
                  width: 2.0,
                ),
              ),
              hintText: '영문, 숫자, 특수문자 포함 8자 이상',
              contentPadding: EdgeInsets.symmetric(horizontal: rWidth(12), vertical: rHeight(14)),
            ),
            style: TextStyle(fontSize: rFont(16)),
          ),
        ],
      ],
    );
  }
}
