import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import 'dart:convert';
import 'record_edit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';

class RecordListScreen extends StatefulWidget {
  final String? selectedDate; // yyyy-MM-dd 형식, null이면 오늘 날짜

  const RecordListScreen({super.key, this.selectedDate});

  @override
  State<RecordListScreen> createState() => _RecordListScreenState();
}

class _RecordListScreenState extends State<RecordListScreen> {
  List<Record> _dateRecords = [];
  bool _hasUpdated = false;

  @override
  void initState() {
    super.initState();
    _loadRecordsForDate();
  }

  Future<void> _loadRecordsForDate() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('user');

    if (jsonString == null) {
      print('[WARN] SharedPreferences에 user 정보 없음');
      setState(() {
        _dateRecords = [];
      });
      return;
    }

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final userId = user.id;
    //디버그용
    print('불러온 userId: $userId');

    final targetDate = widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    //디버그용
    print('📅 조회 대상 날짜: $targetDate');

    try {
      final response = await ApiClient.dio.get(
        '/records/$userId/',
        queryParameters: {'spendDate': targetDate},
      );

      //디버그용
      print('statusCode: ${response.statusCode}');
      print('response.data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        final List<Record> records = data.map((json) {
          print('📄 record json: $json');
          return Record.fromJson(json);
        }).toList();

        setState(() {
          _dateRecords = records;
        });
      } else {
        print('서버 응답 상태 오류: ${response.statusCode}');
        setState(() {
          _dateRecords = [];
        });
      }
    } catch (e, stack) {
      print('API 호출 예외 발생: $e');
      print('Stack trace: $stack');
      setState(() {
        _dateRecords = [];
      });
    }
  }


  void _onRecordTap(Record record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordEditScreen(record: record),
      ),
    ).then((result) {
      if (result == true) {
        _hasUpdated = true;
        _loadRecordsForDate();
      }
    });
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _hasUpdated);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                              '${NumberFormat('#,###').format(record.spendCost)}원',
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
