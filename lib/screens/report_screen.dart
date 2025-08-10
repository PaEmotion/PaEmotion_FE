import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/report_utils.dart';
import '../utils/user_storage.dart';

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
    final userProfile = await UserStorage.loadProfileJson();
    if (userProfile == null) return;

    final userId = userProfile['userId'] as int?;
    if (userId == null) {
      debugPrint('❌ userId가 null입니다. 사용자 정보를 확인하세요: $userProfile');
      return;
    }

    final startDate = DateTime(2025, 4, 1);
    final endDate = DateTime(2025, 7, 31);

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
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;

          double titleFontSize;
          double subtitleFontSize;
          double verticalSpacing;
          double buttonHeight;
          double horizontalPadding;

          if (width < 350) {
            titleFontSize = 20;
            subtitleFontSize = 12;
            verticalSpacing = 24;
            buttonHeight = 80;
            horizontalPadding = 12;
          } else if (width < 600) {
            titleFontSize = 24;
            subtitleFontSize = 14;
            verticalSpacing = 28;
            buttonHeight = 90;
            horizontalPadding = 16;
          } else {
            titleFontSize = 28;
            subtitleFontSize = 16;
            verticalSpacing = 32;
            buttonHeight = 100;
            horizontalPadding = 24;
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalSpacing,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI가 분석한\n나만의 소비 리포트를\n확인해보세요.",
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: verticalSpacing),
                _buildReportButton(
                  context,
                  title: '월간 리포트',
                  subtitle: '월별 소비 유형, 감정 카테고리 분석, 지출 순위 확인',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MonthlyReportScreen()),
                  ),
                  titleFontSize: titleFontSize - 4,
                  subtitleFontSize: subtitleFontSize,
                  height: buttonHeight,
                ),
                SizedBox(height: verticalSpacing * 0.6),
                _buildReportButton(
                  context,
                  title: '주간 리포트',
                  subtitle: '주별 소비, 감정 분석과 다음주 지출 예측',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WeeklyReportScreen()),
                  ),
                  titleFontSize: titleFontSize - 4,
                  subtitleFontSize: subtitleFontSize,
                  height: buttonHeight,
                ),
                SizedBox(height: verticalSpacing * 0.6),
                _buildReportButton(
                  context,
                  title: '일간 리포트',
                  subtitle: '하루동안의 소비내역 확인하기',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyReportScreen()),
                  ),
                  titleFontSize: titleFontSize - 4,
                  subtitleFontSize: subtitleFontSize,
                  height: buttonHeight,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildReportButton(
      BuildContext context, {
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required double titleFontSize,
        required double subtitleFontSize,
        required double height,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(builder: (context, inner) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: inner.maxHeight * 0.15),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.black87,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
