class Record {
  final String spendid;
  final String date;
  final String category;
  final String item;
  final int amount;
  final String emotion;

  Record({
    required this.spendid,
    required this.date,
    required this.category,
    required this.item,
    required this.amount,
    required this.emotion,
  });

  Map<String, dynamic> toJson() => {
    'spendid': spendid,
    'date': date,
    'category': category,
    'item': item,
    'amount': amount,
    'emotion': emotion,
  };

  factory Record.fromJson(Map<String, dynamic> json) => Record(
    spendid: json['spendid'],
    date: json['date'],
    category: json['category'],
    item: json['item'],
    amount: (json['amount'] as num).toInt(),
    emotion: json['emotion'],
  );
}
