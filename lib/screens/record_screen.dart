import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'recordsuccess_screen.dart';
import 'package:uuid/uuid.dart';
import '../models/record.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory;
  String? _selectedEmotion;

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  final List<String> _categories = [
    '쇼핑', '배달음식', '외식', '카페', '취미', '뷰티', '건강', '자기계발', '선물', '여행', '모임'
  ];

  final List<String> _emotions = [
    '행복', '사랑', '기대감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움', '기회감',
  ];

  Future<void> _submitRecord() async {
    final spendItem = _itemController.text.trim();
    final amountStr = _amountController.text.trim();
    final spendCost = int.tryParse(amountStr) ?? 0;

    if (_selectedCategory == null || spendItem.isEmpty || spendCost <= 0 || _selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 정확히 입력해주세요.')),
      );
      return;
    }

    final record = Record(
      spendId: const Uuid().v4(),
      spendDate: _selectedDate.toIso8601String(),
      category: _selectedCategory!,
      spendItem: spendItem,
      spendCost: spendCost,
      emotion: _selectedEmotion!,
    );

    final prefs = await SharedPreferences.getInstance();
    final List<String> existingRecords = prefs.getStringList('records') ?? [];
    existingRecords.add(jsonEncode(record.toJson()));
    await prefs.setStringList('records', existingRecords);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RecordSuccessScreen()),
    );
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
    final maxWidth = 400.0;

    final inputDecoration = const InputDecoration(
      border: UnderlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('소비기록 작성')),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: ListView(
              children: [
                _buildLabel('날짜를 선택해주세요'),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF1A1A1A)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),

                _buildLabel('무엇을 소비했나요?'),
                DropdownButtonFormField<String>(
                  decoration: inputDecoration.copyWith(
                    hintText: '카테고리를 선택하세요',
                  ),
                  value: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),

                _buildLabel('소비한 품목'),
                TextField(
                  controller: _itemController,
                  decoration: inputDecoration.copyWith(
                    hintText: '소비한 품목을 입력하세요',
                  ),
                ),

                _buildLabel('금액을 적어주세요'),
                TextField(
                  controller: _amountController,
                  decoration: inputDecoration.copyWith(
                    hintText: '금액을 숫자로 입력하세요',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                _buildLabel('어떤 감정이었나요?'),
                DropdownButtonFormField<String>(
                  decoration: inputDecoration.copyWith(
                    hintText: '감정을 선택하세요',
                  ),
                  value: _selectedEmotion,
                  items: _emotions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedEmotion = val),
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
                  child: const Text(
                    '작성 완료',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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




