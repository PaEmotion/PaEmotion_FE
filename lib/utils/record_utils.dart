import 'package:intl/intl.dart';
import '../models/record.dart';
import '../api/api_client.dart';

Future<List<Record>> fetchRecordsInRange(DateTime start, DateTime end) async {
  final dio = ApiClient.dio;

  try {
    final res = await dio.get('/records/me', queryParameters: {
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


