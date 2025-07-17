import 'package:flutter/material.dart';
import 'monthly_report_screen.dart';
import 'weekly_report_screen.dart';
import 'daily_report_screen.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

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
                subtitle: 'AI가 원별로 분석한 감정에 따른 나의 소비 패턴 확인하기',
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
                subtitle: 'AI가 요약해주는 일별 나의 소비, 소비내역 수정하기',
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
        height: 100, // 고정 높이
        width: double.infinity, // 가로는 꽉 차게
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // 수직 가운데 정렬
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15), // 제목과 부제목 사이 간격
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
