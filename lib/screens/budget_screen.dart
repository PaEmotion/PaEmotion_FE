import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'budget_ai_screen.dart';
import 'budget_creating_screen.dart';
import 'budget_edit_screen.dart';
import '../utils/record_storage.dart';  // RecordStorage 임포트 경로 맞춰서 조정 필요

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int? _currentBudget;
  int? _currentSpending;
  late String _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    _loadBudgetAndSpending();
  }

  Future<void> _loadBudgetAndSpending() async {
    final prefs = await SharedPreferences.getInstance();
    final budget = prefs.getInt('budget_$_currentMonth');

    final spending = await RecordStorage.getMonthlySpending(_currentMonth);

    setState(() {
      _currentBudget = budget;
      _currentSpending = spending;
    });
  }

  String _feedbackMessage() {
    if (_currentBudget == null || _currentSpending == null) return '';
    final percent = _currentSpending! / _currentBudget!;

    if (percent < 0.5) return '아직 넉넉해요 😊 계획적인 소비 아주 좋아요!';
    if (percent < 0.8) return '조금만 더 신경 써볼까요? 😌 아직 괜찮아요!';
    if (percent <= 1.0) return '예산이 거의 다 닳았어요! ⚠️ 살짝 조심해볼까요?';
    return '예산 초과! 😱 다음 달엔 더 잘해볼 수 있어요!';
  }

  @override
  Widget build(BuildContext context) {
    final spendingPercent = (_currentBudget != null &&
        _currentSpending != null && _currentBudget! > 0)
        ? (_currentSpending! / _currentBudget!).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 텍스트 분기 처리
              Text(
                (_currentBudget != null && _currentSpending != null)
                    ? '이번 달 예산입니다.'
                    : '예산을 설정하고\n소비를 관리해보세요',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 12),

              // 예산/소비 안내 텍스트 (예산이 있을 때만)
              if (_currentBudget != null && _currentSpending != null)
                Text(
                  '이번달 예산은 ${_currentBudget!.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원\n'
                      '총 ${_currentSpending!.toString().replaceAllMapped(
                      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (
                      m) => '${m[1]},')}원을 소비했어요.',
                  style: const TextStyle(fontSize: 16),
                ),

              const SizedBox(height: 70),

              // 퍼센트 차트
              if (_currentBudget != null && _currentSpending != null)
                Center(
                  child: CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 20.0,
                    percent: spendingPercent,
                    center: Text(
                      "${(spendingPercent * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    progressColor:
                    spendingPercent > 1.0 ? Colors.red : Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    animation: true,
                    animationDuration: 600,
                  ),
                ),

              const SizedBox(height: 20),

              // 피드백 메시지
              if (_currentBudget != null && _currentSpending != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 32),
                  child: Center(
                    child: Text(
                      _feedbackMessage(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color:
                        spendingPercent > 1.0 ? Colors.red : Colors.black,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // AI 예산 설정 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetAiScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'AI에게 예산 설정 도움받기',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 예산 설정/수정 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    if (_currentBudget != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetEditScreen(),
                        ),
                      ).then((_) => _loadBudgetAndSpending());
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BudgetSettingScreen(),
                        ),
                      ).then((_) => _loadBudgetAndSpending());
                    }
                  },
                  child: Text(
                    _currentBudget != null
                        ? '예산 수정하기'
                        : '이번달 예산 설정하기',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
