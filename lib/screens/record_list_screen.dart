import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../utils/record_storage.dart';
import 'record_edit_screen.dart';

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

class RecordListScreen extends StatefulWidget {
  final String? selectedDate; // yyyy-MM-dd 형식, null이면 오늘 날짜

  const RecordListScreen({super.key, this.selectedDate});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<Record> _dateRecords = [];
  bool _hasUpdated = false; // 수정, 삭제 여부 추적

  @override
  void initState() {
    super.initState();
    _loadRecordsForDate();
  }

  Future<void> _loadRecordsForDate() async {
    final allRecords = await RecordStorage.loadRecords();
    final targetDate = widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    final filteredRecords = allRecords.where((record) {
      final dt = DateTime.parse(record.spendDate);
      final recordDateStr = DateFormat('yyyy-MM-dd').format(dt);
      return recordDateStr == targetDate;
    }).toList();

    setState(() {
      _dateRecords = filteredRecords;
    });
  }

  void _onRecordTap(Record record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordEditScreen(record: record),
      ),
    ).then((result) {
      if (result == true) {
        _hasUpdated = true; // 수정됨 표시
        _loadRecordsForDate(); // 리스트 갱신
      }
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _hasUpdated); // 상태 반환
    return false; // 기존 pop block
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // 뒤로가기 감지
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.selectedDate ?? '오늘'} 소비기록 수정'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _onWillPop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                '수정하고 싶은 내역을 선택해주세요.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _dateRecords.isEmpty
                    ? Center(child: Text('${widget.selectedDate ?? '오늘'}의 소비 기록이 없습니다.'))
                    : ListView.builder(
                  itemCount: _dateRecords.length,
                  itemBuilder: (context, index) {
                    final record = _dateRecords[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _onRecordTap(record),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${categoryMap[record.spend_category] ?? record.spend_category.toString()} - ${record.spendItem}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${NumberFormat('#,###').format(record.spendCost.toInt())}원',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
