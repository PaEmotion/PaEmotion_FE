import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../utils/record_storage.dart';

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

  final List<String> _categories = [
    '식비', '교통', '쇼핑', '기타', '외식', '배달음식', '카페', '취미', '뷰티', '건강', '자기계발', '선물', '여행', '모임'
  ];

  final List<String> _emotions = [
    '행복', '사랑', '기대감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움', '기회감'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.record.category;
    _itemController = TextEditingController(text: widget.record.spendItem);
    _amountController = TextEditingController(text: widget.record.spendCost.toInt().toString());
    _selectedEmotion = widget.record.emotion;
  }

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final updatedRecord = Record(
        spendId: widget.record.spendId,
        spendDate: widget.record.spendDate,
        category: _selectedCategory,
        spendItem: _itemController.text.trim(),
        spendCost: int.parse(_amountController.text),
        emotion: _selectedEmotion,
      );

      // 저장
      await RecordStorage.updateRecord(updatedRecord);

      //true 반환
      Navigator.pop(context, true);
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

    if (shouldDelete == true) {
      await RecordStorage.deleteRecord(widget.record.spendId);
      Navigator.pop(context, true); // 삭제 성공 시 true 반환
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 기록 수정하기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '무엇을 소비했나요? (카테고리)',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
                validator: (value) =>
                value == null || value.isEmpty ? '카테고리를 선택해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemController,
                decoration: const InputDecoration(
                  labelText: '품목 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.trim().isEmpty ? '품목 이름을 입력해주세요.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: '금액',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return '금액을 입력해주세요.';
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) return '유효한 금액을 입력해주세요.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedEmotion,
                decoration: const InputDecoration(
                  labelText: '어떤 감정이었나요?',
                  border: OutlineInputBorder(),
                ),
                items: _emotions
                    .map((emotion) => DropdownMenuItem(value: emotion, child: Text(emotion)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedEmotion = value;
                    });
                  }
                },
                validator: (value) =>
                value == null || value.isEmpty ? '감정을 선택해주세요.' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  '수정하기',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _confirmDelete,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                ),
                child: const Text(
                  '삭제하기',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

