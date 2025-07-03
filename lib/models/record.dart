class Record {
  final String id;  // 고유 아이디 필드 추가
  final String date;
  final String category;
  final String item;
  final int amount;
  final String emotion;

  Record({
    required this.id,
    required this.date,
    required this.category,
    required this.item,
    required this.amount,
    required this.emotion,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'category': category,
    'item': item,
    'amount': amount,
    'emotion': emotion,
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    id: json['id'],
    date: json['date'],
    category: json['category'],
    item: json['item'],
    amount: (json['amount'] as num).toInt(),
    emotion: json['emotion'],
  );
}