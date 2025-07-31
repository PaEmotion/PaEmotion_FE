import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../models/reportrequest.dart';
import '../utils/report_utils.dart';

import 'monthly_report_screen.dart';
import 'weekly_report_screen.dart';
import 'daily_report_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>  {
  @override
  void initState() {
    super.initState();
    _fetchAndCacheReports();
  }


  Future<void> _fetchAndCacheReports() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return;

    final user = User.fromJson(jsonDecode(userJson));

    // 임시 전체 기간 설정, 출시 임박 시 변경 예정 (2025년 4월 1일 ~ 2025년 7월 31일)
    final startDate = DateTime(2025, 4, 1);
    final endDate = DateTime(2025, 7, 31);
    final userId = user.id;


    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(endDate);

    final reports = await ReportUtils.fetchReportsFromApi(
      userId: userId,
      startDate: startDateStr,
      endDate: endDateStr,
    );
    print('📡 API 호출 시작: userId=$userId, startDate=$startDateStr, endDate=$endDateStr');

    await ReportUtils.saveReportsSmartly(reports);

    print('✅ 전체 기간 리포트 받아와서 캐시에 저장 완료');
    print('받아온 리포트 개수: ${reports.length}');
    for (var r in reports) {
      print('리포트 - 타입: ${r.reportType}, 날짜: ${r.reportDate}, 제목: ${r.reportText ?? "내용없음"}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "AI가 분석한\n나만의 소비 리포트를\n확인해보세요.",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 50),
              _buildReportButton(
                context,
                title: '월간 리포트',
                subtitle: 'AI가 월별로 분석한 감정에 따른 나의 소비 패턴 확인하기',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildReportButton(
                context,
                title: '주간 리포트',
                subtitle: 'AI가 요약해주는 주별 나의 소비 확인하기',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                ),
              ),
              const SizedBox(height: 20),
              _buildReportButton(
                context,
                title: '일간 리포트',
                subtitle: '하루동안의 소비내역 확인하기',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
