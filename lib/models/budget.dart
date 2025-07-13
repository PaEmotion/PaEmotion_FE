class Budget {
  final String month; // 예: '2025-07'
  final String category; // 예: '쇼핑'
  final int amount; // 예: 100000

  Budget({
    required this.month,
    required this.category,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'month': month,
    'category': category,
    'amount': amount,
  };

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    month: json['month'],
    category: json['category'],
    amount: json['amount'],
  );
}