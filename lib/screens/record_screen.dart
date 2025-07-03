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
    '쇼핑', '배달음식', '외식', '카페', '취미', '뷰티', '건강', '자기계발', '선물', '여행'
  ];

  final List<String> _emotions = [
    '행복', '사랑', '기대감', '슬픔', '우울', '분노', '스트레스', '피로', '불안', '무료함', '외로움', '자기연민'
  ];

  Future<void> _submitRecord() async {
    final item = _itemController.text.trim();
    final amountStr = _amountController.text.trim();
    final amount = int.tryParse(amountStr) ?? 0;

    if (_selectedCategory == null || item.isEmpty || amount <= 0 || _selectedEmotion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 항목을 정확히 입력해주세요.')),
      );
      return;
    }

    // Record 인스턴스 생성
    final record = Record(
      id: const Uuid().v4(),
      date: _selectedDate.toIso8601String(),
      category: _selectedCategory!,
      item: item,
      amount: amount,
      emotion: _selectedEmotion!,
    );

    final prefs = await SharedPreferences.getInstance();
    final List<String> existingRecords = prefs.getStringList('records') ?? [];

    // toJson으로 변환 후 저장
    existingRecords.add(jsonEncode(record.toJson()));
    await prefs.setStringList('records', existingRecords);

    // 저장 직후
    await prefs.setStringList('records', existingRecords);
    final savedRecords = prefs.getStringList('records') ?? [];
    print('저장된 records 수: ${savedRecords.length}');
    print('첫번째 record json: ${savedRecords.isNotEmpty ? savedRecords[0] : "없음"}');


    // 기록 성공 화면으로 이동
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RecordSuccessScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('소비기록 작성')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('날짜를 선택해주세요'),
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
            const SizedBox(height: 10),

            const Text('무엇을 소비했나요?'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('카테고리를 선택하세요'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _itemController,
              decoration: const InputDecoration(labelText: '소비한 품목'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: '금액을 적어주세요'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 10),

            const Text('어떤 감정이었나요?'),
            DropdownButton<String>(
              isExpanded: true,
              value: _selectedEmotion,
              hint: const Text('감정을 선택하세요'),
              items: _emotions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
    );
  }
}

