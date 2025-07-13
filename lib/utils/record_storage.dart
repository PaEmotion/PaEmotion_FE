import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/record.dart';

class RecordStorage {
  static const String _key = 'records';

  // 저장
  static Future<void> saveRecord(Record record) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> records = prefs.getStringList(_key) ?? [];
    records.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, records);
  }

  // 불러오기
  static Future<List<Record>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> records = prefs.getStringList(_key) ?? [];
    return records.map((e) => Record.fromJson(jsonDecode(e))).toList();
  }

  // 전체 삭제 (테스트용)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // 수정하기 (id가 같은 레코드를 찾아서 업데이트)
  static Future<void> updateRecord(Record updatedRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> records = prefs.getStringList(_key) ?? [];

    // JSON 문자열을 Record 객체로 변환
    List<Record> recordList = records.map((e) => Record.fromJson(jsonDecode(e))).toList();

    // id가 같은 레코드 인덱스 찾기
    final index = recordList.indexWhere((r) => r.spendId == updatedRecord.spendId);
    if (index != -1) {
      recordList[index] = updatedRecord;  // 수정
      // 다시 문자열 리스트로 변환해서 저장
      final updatedRecords = recordList.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList(_key, updatedRecords);
    }
  }

  // 소비한 총액 계산
  static Future<int> getMonthlySpending(String yearMonth) async {
    final records = await loadRecords();
    final filtered = records.where((record) => record.spendDate.startsWith(yearMonth));
    int total = 0;
    for (final record in filtered) {
      total += record.spendCost;
    }
    return total;
  }



  // 삭제하기 (id 기준)
  static Future<void> deleteRecord(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> records = prefs.getStringList(_key) ?? [];

    List<Record> recordList = records.map((e) => Record.fromJson(jsonDecode(e))).toList();

    recordList.removeWhere((r) => r.spendId == id);

    final updatedRecords = recordList.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, updatedRecords);
  }

  // 월별-카테고리별 소비금액
  static Future<int> getCategorySpending(String yearMonth, String category) async {
    final records = await loadRecords();
    final filtered = records.where((record) =>
    record.spendDate.startsWith(yearMonth) && record.category == category
    );
    int total = 0;
    for (final record in filtered) {
      total += record.spendCost;
    }
    return total;
  }

}