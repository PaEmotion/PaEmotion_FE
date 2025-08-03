import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/record.dart';
import '../api/api_client.dart';

Future<List<Record>> fetchRecordsInRange(DateTime start, DateTime end) async {
  final prefs = await SharedPreferences.getInstance();
  final userJson = prefs.getString('user');
  if (userJson == null) throw Exception('로그인 정보 없음');
  final userMap = jsonDecode(userJson);
  final user = User.fromJson(userMap);
  final userId = user.id;
  final dio = ApiClient.dio;

  try {
    final res = await dio.get('/records/$userId', queryParameters: {
      'startDate': DateFormat('yyyy-MM-dd').format(start),
      'endDate': DateFormat('yyyy-MM-dd').format(end),
    });
    final data = res.data;
    if (data is List && data.isNotEmpty) {
      return data.map<Record>((e) => Record.fromJson(e)).toList();
    } else {
      return <Record>[];
    }
  } catch (e) {
    print('기록 불러오기 실패 ($start ~ $end): $e');
    return <Record>[];
  }
}


