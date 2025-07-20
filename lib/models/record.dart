class Record {
  final int spendId;
  final int userId;
  final String spendDate;
  final int spend_category;
  final String spendItem;
  final int spendCost;
  final int emotion_category;

  Record({
    required this.spendId,
    required this.userId,
    required this.spendDate,
    required this.spend_category,
    required this.spendItem,
    required this.spendCost,
    required this.emotion_category,
  });

  Map<String, dynamic> toJson() => {
    'spendId': spendId,
    'userId': userId,
    'spendDate': spendDate,
    'spendCategoryId': spend_category,
    'spendItem': spendItem,
    'spendCost': spendCost,
    'emotionCategoryId': emotion_category,
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    spendId: (json['spendId'] as num).toInt(),
    userId: json['userId'],
    spendDate: json['spendDate'],
    spend_category: (json['spendCategoryId'] as num).toInt(),
    spendItem: json['spendItem'],
    spendCost: (json['spendCost'] as num).toInt(),
    emotion_category: (json['emotionCategoryId'] as num).toInt(),
  );
}

