import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'recordsuccess_screen.dart';
import '../api/api_client.dart';
import '../utils/user_storage.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _categories = [
    '쇼핑', '배달음식', '외식', '카페', '취미', '뷰티', '건강', '자기계발', '선물', '여행', '모임'
  ];

  final List<String> _emotions = [
    '행복', '사랑', '기대감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움', '기회감'
  ];

  int? _selectedCategoryIndex;
  int? _selectedEmotionIndex;

  Future<void> _submitRecord() async {
    final userMap = await UserStorage.loadProfileJson();
    if (userMap == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인 해주세요.')),
      );
      return;
    }

    final userId = userMap['userId'];
    final spendItem = _itemController.text.trim();
    final amountStr = _amountController.text.trim();
    final spendCost = int.tryParse(amountStr) ?? 0;

    if (_selectedCategoryIndex == null ||
        spendItem.isEmpty ||
        spendCost <= 0 ||
        _selectedEmotionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 정확히 입력해주세요.')),
      );
      return;
    }

    final recordData = {
      "userId": userId,
      "emotionCategoryId": _selectedEmotionIndex,
      "spendCategoryId": _selectedCategoryIndex,
      "spendItem": spendItem,
      "spendCost": spendCost,
      "spendDate": DateTime
          .now()
          .toIso8601String()
          .split('.')
          .first,
    };

    try {
      final response = await ApiClient.dio.post(
          '/records/create', data: recordData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RecordSuccessScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기록 저장이 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Row(
        children: [
          const Text(
              '•', style: TextStyle(fontSize: 20, color: Colors.black87)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery
        .of(context)
        .size
        .width;

    double maxWidth = width < 400 ? width * 0.95 : 400;
    double fontSize = width < 350 ? 14 : 16;
    double paddingHorizontal = width < 350 ? 12 : 16;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final inputDecoration = InputDecoration(
      border: const UnderlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('소비기록 작성')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal, vertical: 16),
            child: ListView(
              children: [
                _buildLabel('기록 일자'),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1A1A1A)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    todayStr,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
                _buildLabel('무엇을 소비했나요?'),
                DropdownButtonFormField<int>(
                  decoration: inputDecoration.copyWith(hintText: '카테고리를 선택하세요'),
                  value: _selectedCategoryIndex,
                  items: List.generate(_categories.length, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_categories[index], style: TextStyle(
                          fontSize: fontSize)),
                    );
                  }),
                  onChanged: (val) =>
                      setState(() => _selectedCategoryIndex = val),
                ),
                _buildLabel('소비한 품목'),
                TextField(
                  controller: _itemController,
                  decoration: inputDecoration.copyWith(
                      hintText: '소비한 품목을 입력하세요'),
                  style: TextStyle(fontSize: fontSize),
                ),
                _buildLabel('금액을 적어주세요'),
                TextField(
                  controller: _amountController,
                  decoration: inputDecoration.copyWith(
                      hintText: '금액을 숫자로 입력하세요'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(fontSize: fontSize),
                ),
                _buildLabel('어떤 감정이었나요?'),
                DropdownButtonFormField<int>(
                  decoration: inputDecoration.copyWith(hintText: '감정을 선택하세요'),
                  value: _selectedEmotionIndex,
                  items: List.generate(_emotions.length, (index) {
                    return DropdownMenuItem(
                      value: index + 1,
                      child: Text(_emotions[index], style: TextStyle(
                          fontSize: fontSize)),
                    );
                  }),
                  onChanged: (val) =>
                      setState(() => _selectedEmotionIndex = val),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _submitRecord,
                  child: Text(
                    '작성 완료',
                    style: TextStyle(
                        fontSize: fontSize, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}










