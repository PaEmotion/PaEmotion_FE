import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../api/api_client.dart';

const Map<int, String> categoryMap = {
  1: '쇼핑',
  2: '배달음식',
  3: '외식',
  4: '카페',
  5: '취미',
  6: '뷰티',
  7: '건강',
  8: '자기계발',
  9: '선물',
  10: '여행',
  11: '모임',
};
final Map<String, int> categoryReverseMap =
categoryMap.map((key, value) => MapEntry(value, key));

const Map<int, String> emotionMap = {
  1: '행복',
  2: '사랑',
  3: '기대감',
  4: '슬픔',
  5: '우울',
  6: '분노',
  7: '스트레스',
  8: '피로',
  9: '불안',
  10: '무료함',
  11: '외로움',
  12: '기회감',
};
final Map<String, int> emotionReverseMap =
emotionMap.map((key, value) => MapEntry(value, key));

class RecordEditScreen extends StatefulWidget {
  final Record record;

  const RecordEditScreen({super.key, required this.record});

  @override
  State<RecordEditScreen> createState() => _RecordEditScreenState();
}

class _RecordEditScreenState extends State<RecordEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late TextEditingController _itemController;
  late TextEditingController _amountController;
  late String _selectedEmotion;

  late bool _isToday;

  late List<String> _categories;
  late List<String> _emotions;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();

    _selectedCategory = categoryMap[widget.record.spend_category] ?? '';

    _itemController = TextEditingController(text: widget.record.spendItem);
    _amountController =
        TextEditingController(text: widget.record.spendCost.toString());

    _selectedEmotion = emotionMap[widget.record.emotion_category] ?? '';

    _categories = categoryMap.values.toList();
    _emotions = emotionMap.values.toList();

    final recordDate = DateTime.parse(widget.record.spendDate);
    final now = DateTime.now();
    _isToday = recordDate.year == now.year &&
        recordDate.month == now.month &&
        recordDate.day == now.day;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCategoryId = categoryReverseMap[_selectedCategory];
    final selectedEmotionId = emotionReverseMap[_selectedEmotion];

    if (selectedCategoryId == null || selectedEmotionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 또는 감정을 올바르게 선택해주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await ApiClient.dio.put(
        '/records/me/${widget.record.spendId}',
        data: {
          "spendItem": _itemController.text.trim(),
          "spendCost": int.parse(_amountController.text.trim()),
          "spendCategoryId": selectedCategoryId,
          "emotionCategoryId": selectedEmotionId,
        },
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('수정 중 오류 발생: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정말 삭제하시겠어요?'),
        content: const Text('이 소비기록은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);

    try {
      final response =
      await ApiClient.dio.delete('/records/me/${widget.record.spendId}');

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 중 오류 발생: $e')),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 12),
      child: Row(
        children: [
          const Text('•', style: TextStyle(fontSize: 20, color: Colors.black87)),
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
    final width = MediaQuery.of(context).size.width;
    double maxWidth = width < 400 ? width * 0.95 : 400;
    double fontSize = width < 350 ? 14 : 16;
    double paddingHorizontal = width < 350 ? 12 : 16;

    final recordDateStr =
    DateFormat('yyyy년 M월 d일').format(DateTime.parse(widget.record.spendDate));

    return Scaffold(
      appBar: AppBar(title: const Text('소비 기록 수정하기')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding:
            EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  _buildLabel('기록 일자'),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1A1A1A)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      recordDateStr,
                      style: TextStyle(fontSize: fontSize),
                    ),
                  ),
                  _buildLabel('무엇을 소비했나요?'),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    value: _selectedCategory,
                    items: _categories
                        .map((cat) => DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: TextStyle(fontSize: fontSize)),
                    ))
                        .toList(),
                    onChanged: _isToday
                        ? (value) => setState(() {
                      if (value != null) _selectedCategory = value;
                    })
                        : null,
                  ),
                  _buildLabel('소비한 품목'),
                  TextFormField(
                    controller: _itemController,
                    enabled: _isToday,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    style: TextStyle(fontSize: fontSize),
                    validator: (value) =>
                    value == null || value.trim().isEmpty ? '품목을 입력하세요.' : null,
                  ),
                  _buildLabel('금액을 적어주세요'),
                  TextFormField(
                    controller: _amountController,
                    enabled: _isToday,
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(fontSize: fontSize),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '금액을 입력하세요.';
                      }
                      final number = int.tryParse(value);
                      if (number == null || number <= 0) {
                        return '유효한 금액을 입력하세요.';
                      }
                      return null;
                    },
                  ),
                  _buildLabel('어떤 감정이었나요?'),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: const UnderlineInputBorder(),
                      isDense: true,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    value: _selectedEmotion,
                    items: _emotions
                        .map((emotion) => DropdownMenuItem(
                      value: emotion,
                      child: Text(emotion, style: TextStyle(fontSize: fontSize)),
                    ))
                        .toList(),
                    onChanged: _isToday
                        ? (value) => setState(() {
                      if (value != null) _selectedEmotion = value;
                    })
                        : null,
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
                    onPressed: _isToday && !_isSaving ? _saveRecord : null,
                    child: _isSaving
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      '수정하기',
                      style: TextStyle(
                          fontSize: fontSize, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _isToday && !_isDeleting ? _confirmDelete : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.red,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      '삭제하기',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
