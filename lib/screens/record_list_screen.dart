import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import 'record_edit_screen.dart';
import '../api/api_client.dart';
import '../constants/api_endpoints/record_api.dart';

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
  final String? selectedDate;

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
    try {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      final response = await ApiClient.dio.get(
        RecordApi.list,
        queryParameters: {
          'startDate': DateFormat('yyyy-MM-dd').format(today),
          'endDate': DateFormat('yyyy-MM-dd').format(tomorrow),
        },
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

  double _clampFont(double size, BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = size * scale;
    return computed.clamp(12.0, 24.0);
  }

  EdgeInsets _responsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width < 360 ? 12.0 : 20.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 8);
  }

  @override
  Widget build(BuildContext context) {
    final titleFontSize = _clampFont(18, context);
    final bodyFontSize = _clampFont(14, context);
    final listFontSize = _clampFont(16, context);
    final buttonRadius = 12.0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '오늘 소비기록 수정',
            style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, size: 24),
            onPressed: () => _onWillPop(),
          ),
          toolbarHeight: 56,
          titleSpacing: 0,
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Padding(
            padding: _responsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  '수정하고 싶은 내역을 선택해주세요.',
                  style: TextStyle(
                    fontSize: listFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Expanded(
                  child: _dateRecords.isEmpty
                      ? Center(
                    child: Text(
                      '오늘 소비 기록이 없습니다.',
                      style: TextStyle(fontSize: bodyFontSize),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : ListView.builder(
                    itemCount: _dateRecords.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) {
                      final record = _dateRecords[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 56),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(buttonRadius),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => _onRecordTap(record),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${categoryMap[record.spend_category] ?? record.spend_category.toString()} - ${record.spendItem}',
                                    style: TextStyle(
                                      fontSize: listFontSize,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${NumberFormat('#,###').format(record.spendCost)}원',
                                  style: TextStyle(
                                    fontSize: listFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}