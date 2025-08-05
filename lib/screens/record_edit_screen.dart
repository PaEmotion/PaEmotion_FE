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

  double _responsiveFont(double base, BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.9, base * 1.3);
  }

  EdgeInsets _formPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width < 360 ? 12.0 : 20.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 12);
  }

  Size _buttonSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Size(double.infinity, width < 360 ? 48 : 56);
  }

  @override
  Widget build(BuildContext context) {
    final recordDateStr =
    DateFormat('yyyy년 M월 d일').format(DateTime.parse(widget.record.spendDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '소비 기록 수정하기',
          style: TextStyle(
            fontSize: _responsiveFont(18, context),
            fontWeight: FontWeight.w600,
          ),
        ),
        toolbarHeight: 56,
      ),
      body: Padding(
        padding: _formPadding(context),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                '기록 일자: $recordDateStr',
                style: TextStyle(
                  fontSize: _responsiveFont(16, context),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!_isToday) ...[
                const SizedBox(height: 8),
                Text(
                  '※ 과거 기록은 수정하거나 삭제할 수 없습니다.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: _responsiveFont(14, context),
                  ),
                ),
              ],
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: '무엇을 소비했나요? (카테고리)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(
                    cat,
                    style: TextStyle(fontSize: _responsiveFont(14, context)),
                  ),
                ))
                    .toList(),
                onChanged: _isToday
                    ? (value) => setState(() {
                  if (value != null) _selectedCategory = value;
                })
                    : null,
                validator: (value) =>
                value == null || value.isEmpty ? '카테고리를 선택해주세요.' : null,
                style: TextStyle(fontSize: _responsiveFont(14, context), color: Colors.black),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                enabled: _isToday,
                decoration: InputDecoration(
                  labelText: '품목 이름',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '품목 이름을 입력해주세요.'
                    : null,
                style: TextStyle(fontSize: _responsiveFont(14, context)),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                enabled: _isToday,
                decoration: InputDecoration(
                  labelText: '금액',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return '금액을 입력해주세요.';
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) return '유효한 금액을 입력해주세요.';
                  return null;
                },
                style: TextStyle(fontSize: _responsiveFont(14, context)),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmotion,
                decoration: InputDecoration(
                  labelText: '어떤 감정이었나요?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                ),
                items: _emotions
                    .map((emotion) => DropdownMenuItem(
                  value: emotion,
                  child: Text(
                    emotion,
                    style: TextStyle(fontSize: _responsiveFont(14, context)),
                  ),
                ))
                    .toList(),
                onChanged: _isToday
                    ? (value) => setState(() {
                  if (value != null) _selectedEmotion = value;
                })
                    : null,
                validator: (value) =>
                value == null || value.isEmpty ? '감정을 선택해주세요.' : null,
                style: TextStyle(fontSize: _responsiveFont(14, context), color: Colors.black),
              ),
              SizedBox(height: 32),
              SizedBox(
                width: _buttonSize(context).width,
                height: _buttonSize(context).height,
                child: ElevatedButton(
                  onPressed: _isToday && !_isSaving ? _saveRecord : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
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
                      fontSize: _responsiveFont(18, context),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: _buttonSize(context).width,
                height: _buttonSize(context).height,
                child: OutlinedButton(
                  onPressed: _isToday && !_isDeleting ? _confirmDelete : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
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
                      fontSize: _responsiveFont(16, context),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
