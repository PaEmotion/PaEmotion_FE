class Record {
  final String spendId;
  final String spendDate;
  final String category;
  final String spendItem;
  final int spendCost;
  final String emotion;

  Record({
    required this.spendId,
    required this.spendDate,
    required this.category,
    required this.spendItem,
    required this.spendCost,
    required this.emotion,
  });

  Map<String, dynamic> toJson() => {
    'spendId': spendId,
    'spendDate': spendDate,
    'category': category,
    'spendItem': spendItem,
    'spendCost': spendCost,
    'emotion': emotion,
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    spendId: json['spendId'],
    spendDate: json['spendDate'],
    category: json['category'],
    spendItem: json['spendItem'],
    spendCost: (json['spendCost'] as num).toInt(),
    emotion: json['emotion'],
  );
}
