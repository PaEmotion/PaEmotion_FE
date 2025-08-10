import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';

class BudgetStorage {
  static const _key = 'budgets';

  static Future<void> saveBudget(Budget budget) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];

    // 기존 리스트 불러오기
    List<Budget> budgets = raw.map((e) => Budget.fromJson(jsonDecode(e))).toList();

    // 같은 month + category 존재 시 업데이트
    final index = budgets.indexWhere((b) => b.month == budget.month && b.category == budget.category);
    if (index != -1) {
      budgets[index] = budget;
    } else {
      budgets.add(budget);
    }

    final updatedRaw = budgets.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_key, updatedRaw);
  }

  static Future<List<Budget>> loadBudgets(String month) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) => Budget.fromJson(jsonDecode(e)))
        .where((b) => b.month == month)
        .toList();
  }

  static Future<int> getBudgetAmount(String month, String category) async {
    final budgets = await loadBudgets(month);
    return budgets
        .firstWhere(
          (b) => b.category == category,
      orElse: () => Budget(month: month, category: category, amount: 0),
    )
        .amount;
  }

  // 여기서 삭제 함수 추가
  static Future<void> deleteBudget(String month, String category) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> raw = prefs.getStringList(_key) ?? [];

    List<Budget> budgets = raw.map((e) => Budget.fromJson(jsonDecode(e))).toList();

    budgets.removeWhere((b) => b.month == month && b.category == category);

    final updatedRaw = budgets.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList(_key, updatedRaw);
  }
}
