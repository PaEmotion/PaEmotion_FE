class Record {
  final String spendId;
  final String userId;
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
    'spend_category': spend_category,
    'spendItem': spendItem,
    'spendCost': spendCost,
    'emotion_category': emotion_category,
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    spendId: json['spendId'],
    userId: json['userId'],
    spendDate: json['spendDate'],
    spend_category: (json['spend_category'] as num).toInt(),
    spendItem: json['spendItem'],
    spendCost: (json['spendCost'] as num).toInt(),
    emotion_category: (json['emotion_category'] as num).toInt(),
  );
}

