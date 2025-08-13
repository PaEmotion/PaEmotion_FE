class CategoryBudget {
  final int spendCategoryId;
  final int amount;

  CategoryBudget({
    required this.spendCategoryId,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'spendCategoryId': spendCategoryId,
    'amount': amount,
  };

  factory CategoryBudget.fromJson(Map<String, dynamic> json) => CategoryBudget(
    spendCategoryId: json['spendCategoryId'],
    amount: json['amount'],
  );
}
