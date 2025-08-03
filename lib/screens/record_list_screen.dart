import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import 'dart:convert';
import 'record_edit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/reactive_utils.dart';

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
      setState(() {
        _dateRecords = [];
      });
      return;
    }

    final userMap = jsonDecode(jsonString);
    final user = User.fromJson(userMap);
    final userId = user.id;

    final targetDate =
        widget.selectedDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final response = await ApiClient.dio.get(
        '/records/$userId/',
        queryParameters: {'spendDate': targetDate},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final List<Record> records =
        data.map((json) => Record.fromJson(json)).toList();

        setState(() {
          _dateRecords = records;
        });
      } else {
        setState(() {
          _dateRecords = [];
        });
      }
    } catch (e) {
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
    final titleFont = rFont(context, 18);
    final bodyFont = rFont(context, 14);
    final listFont = rFont(context, 16);
    final paddingH = rWidth(context, 16);
    final paddingV = rHeight(context, 14);
    final sectionGap = rHeight(context, 12);
    final buttonRadius = rWidth(context, 10);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.selectedDate ?? '오늘'} 소비기록 수정',
            style: TextStyle(fontSize: titleFont),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: rWidth(context, 22)),
            onPressed: () => _onWillPop(),
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sectionGap),
              Text(
                '수정하고 싶은 내역을 선택해주세요.',
                style: TextStyle(
                  fontSize: listFont,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: sectionGap),
              Expanded(
                child: _dateRecords.isEmpty
                    ? Center(
                  child: Text(
                    '${widget.selectedDate ?? '오늘'}의 소비 기록이 없습니다.',
                    style: TextStyle(fontSize: bodyFont),
                  ),
                )
                    : ListView.builder(
                  itemCount: _dateRecords.length,
                  itemBuilder: (context, index) {
                    final record = _dateRecords[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: rHeight(context, 6)),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: paddingV,
                            horizontal: paddingH,
                          ),
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(buttonRadius),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => _onRecordTap(record),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                '${categoryMap[record.spend_category] ?? record.spend_category.toString()} - ${record.spendItem}',
                                style: TextStyle(
                                  fontSize: listFont,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: rWidth(context, 8)),
                            Text(
                              '${NumberFormat('#,###').format(record.spendCost)}원',
                              style: TextStyle(
                                fontSize: listFont,
                                fontWeight: FontWeight.bold,
                              ),
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
