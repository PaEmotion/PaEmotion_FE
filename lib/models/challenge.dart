class Challenge {
  final int challengeId;
  final String name;
  final bool challengeType;     // true: feed, false: protect
  final bool publicityType;     // true: 공개, false: 비공개
  final DateTime endDate;
  final int goalCount;
  final int participantCount;

  Challenge({
    required this.challengeId,
    required this.name,
    required this.challengeType,
    required this.publicityType,
    required this.endDate,
    required this.goalCount,
    required this.participantCount,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      challengeId: json['challengeId'],
      name: json['name'],
      challengeType: json['challengeType'],
      publicityType: json['publicityType'],
      endDate: DateTime.parse(json['endDate']),
      goalCount: json['goalCount'],
      participantCount: json['participantCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'challengeId': challengeId,
      'name': name,
      'challengeType': challengeType,
      'publicityType': publicityType,
      'endDate': endDate,
      'goalCount': goalCount,
      'participantCount': participantCount,
    };
  }
}
