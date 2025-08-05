import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../models/reportrequest.dart';
import '../api/api_client.dart';
class ReportUtils {
  static const _cacheKey = 'cached_reports';
  static const _lastUpdatedKey = 'last_report_update';

  /// 저장된 리포트 불러오기
  static Future<List<Report>> loadCachedReports() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_cacheKey) ?? [];
    return jsonList
        .map((str) => Report.fromJson(jsonDecode(str)))
        .toList();
  }

  /// 새 리포트 리스트를 받아 중복(reportType + reportDate) 제거 후 저장
  static Future<void> saveReportsSmartly(List<Report> newReports) async {
    final prefs = await SharedPreferences.getInstance();
    final existingJson = prefs.getStringList(_cacheKey) ?? [];

    List<Report> existingReports = existingJson
        .map((str) => Report.fromJson(jsonDecode(str)))
        .toList();

    // (reportType + reportDate) 키를 기준으로 Map 생성
    Map<String, Report> reportMap = {
      for (var r in existingReports)
        '${r.reportType}_${r.reportDate}': r,
    };

    // 새 리포트로 덮어쓰기
    for (var newReport in newReports) {
      final key = '${newReport.reportType}_${newReport.reportDate}';
      reportMap[key] = newReport;
    }

    // 다시 JSON 리스트 변환 후 저장
    final updatedJsonList = reportMap.values
        .map((report) => jsonEncode(report.toJson()))
        .toList();

    await prefs.setStringList(_cacheKey, updatedJsonList);
  }

  /// 특정 타입(weekly, monthly) 리포트만 필터링하여 반환
  static Future<List<Report>> loadReportsByType(String reportType) async {
    final allReports = await loadCachedReports();
    return allReports.where((r) => r.reportType == reportType).toList();
  }

  /// 저장된 모든 리포트를 삭제 (캐시 초기화용)
  static Future<void> clearCachedReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_lastUpdatedKey);
  }

  static Future<List<Report>> fetchReportsFromApi({
    required int userId,
    required String startDate, // yyyy-MM-dd
    required String endDate,
  }) async {
    final dio = ApiClient.dio;
    try {
      print('🌐 요청 전송 중...');

      final response = await dio.get(
        '/reports',
        queryParameters: {
          'userId': userId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );

      print('🌐 응답 상태코드: ${response.statusCode}');
      print('🌐 응답 데이터: ${response.data}');

      final data = response.data;

      if (data is! List) {
        print('❌ 서버 응답이 List 형식이 아님: $data');
        return [];
      }

      return data.map((e) => Report.fromJson(e)).toList();
    } on DioException catch (e) {
      print('❌ 리포트 API 호출 실패');
      print('statusCode: ${e.response?.statusCode}');
      print('response: ${e.response?.data}');
      print('message: ${e.message}');
      return [];
    } catch (e, stackTrace) {
      print('❌ 알 수 없는 에러 발생: $e');
      print(stackTrace);
      return [];
    }
  }

  /// 마지막 갱신 시간 저장
  static Future<void> setLastUpdated(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUpdatedKey, time.toIso8601String());
  }

  /// 마지막 갱신 시간 불러오기
  static Future<DateTime?> getLastUpdated() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lastUpdatedKey);
    return str != null ? DateTime.tryParse(str) : null;
  }

  /// 필요 시 서버에서 갱신하기 (예: 1시간 이상 경과 시)
  static Future<void> refreshReportsIfNeeded({
    required int userId,
    required String startDate,
    required String endDate,
  }) async {
    final lastUpdated = await getLastUpdated();
    final now = DateTime.now();

    if (lastUpdated == null || now.difference(lastUpdated).inMinutes > 60) {
      final freshReports = await fetchReportsFromApi(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );
      await saveReportsSmartly(freshReports);
      await setLastUpdated(now);
    }
  }


  /// 주어진 날짜가 속한 주의 목요일 날짜를 반환
  static DateTime getThursdayBasedDate(DateTime date) {
    int daysToThursday = DateTime.thursday - date.weekday;
    return date.add(Duration(days: daysToThursday));
  }

  /// 목요일 기준 주차 번호 계산 (1월 1일 기준)
  static int weekNumber(DateTime date) {
    final beginningOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(beginningOfYear);
    return ((diff.inDays + beginningOfYear.weekday + 3) / 7).floor() + 1;
  }

  /// 목요일 기준 주차 키 생성 (예: 2025-W29)
  static String getThursdayBasedWeekKey(DateTime date) {
    final thursday = getThursdayBasedDate(date);
    final year = thursday.year;
    final weekOfYear = weekNumber(thursday);
    return '$year-W${weekOfYear.toString().padLeft(2, '0')}';
  }

  static String formatToThursdayBasedWeekTitle(String dateStr) {
    final monday = DateTime.parse(dateStr); // reportDate는 주의 월요일
    final thursday = monday.add(const Duration(days: 3)); // 목요일로 보정

    final year = thursday.year;
    final month = thursday.month;

    // 그 달의 첫째 날
    final firstDayOfMonth = DateTime(year, month, 1);

    // 첫 주의 목요일이 무슨 요일인지 확인
    final firstThursday = firstDayOfMonth.add(Duration(days: (4 - firstDayOfMonth.weekday + 7) % 7));
    final diff = thursday.difference(firstThursday).inDays;

    final weekInMonth = (diff / 7).floor() + 1;

    return '$year년 ${month}월 ${weekInMonth}주차 소비 리포트';
  }

  /// 월간 리포트 제목 생성 (예: "2025년 7월 리포트")
  static String formatMonthlyReportTitle(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final year = date.year;
      final month = date.month;
      return '$year년 ${month}월 소비 리포트';
    } catch (e) {
      return '잘못된 날짜';
    }
  }

  static Future<Report?> createMonthlyReport({
    required int userId,
    required String tone,
    required DateTime monthFirstDay,
  }) async {
    final dio = ApiClient.dio;
    final request = ReportRequest(
      period: 'monthly',
      tone: tone,
      reportDate: DateFormat('yyyy-MM-dd').format(monthFirstDay),
    );

    try {
      final response = await dio.post(
        '/reports/create',
        queryParameters: {'userId': userId},
        data: request.toJson(),
      );
      print('생성 응답 데이터: ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null) {
          return Report.fromJson(data);
        }
      }
      print('리포트 생성 실패: statusCode=${response.statusCode}');
    } catch (e, stacktrace) {
      print('리포트 생성 API 호출 중 예외 발생: $e');
      print(stacktrace);
    }
    return null;
  }

  static Future<Report?> createWeeklyReport({
    required int userId,
    required String tone,
    required DateTime weekMonday,
  }) async {
    final dio = ApiClient.dio;
    final request = ReportRequest(
      period: 'weekly',
      tone: tone,
      reportDate: DateFormat('yyyy-MM-dd').format(weekMonday),
    );

    try {
      final response = await dio.post(
        '/reports/create',
        queryParameters: {'userId': userId},
        data: request.toJson(),
      );
      print('생성 응답 데이터: ${response.data}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data != null) {
          return Report.fromJson(data);
        }

      }
      print('리포트 생성 실패: statusCode=${response.statusCode}');
    } catch (e, stacktrace) {
      print('리포트 생성 API 호출 중 예외 발생: $e');
      print(stacktrace);
    }
    return null;
  }
}
