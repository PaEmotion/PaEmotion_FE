class ChallengeDetail {
  final int challengeId;
  final String name;
  final bool challengeType;
  final bool publicityType;
  final DateTime endDate;
  final int goalCount;
  final int guineaFeedCurrent;
  final double teamProgressRate;
  final List<ParticipantInfo> participantsInfo;

  ChallengeDetail({
    required this.challengeId,
    required this.name,
    required this.challengeType,
    required this.publicityType,
    required this.endDate,
    required this.goalCount,
    required this.guineaFeedCurrent,
    required this.teamProgressRate,
    required this.participantsInfo,
  });

  factory ChallengeDetail.fromJson(Map<String, dynamic> json) {
    return ChallengeDetail(
      challengeId: json['challengeId'],
      name: json['name'],
      challengeType: json['challengeType'],
      publicityType: json['publicityType'],
      endDate: DateTime.parse(json['endDate']),
      goalCount: json['goalCount'],
      guineaFeedCurrent: json['guineaFeedCurrent'],
      teamProgressRate: (json['teamProgressRate'] as num).toDouble(),
      participantsInfo: (json['participantsInfo'] as List<dynamic>)
          .map((e) => ParticipantInfo.fromJson(e))
          .toList(),
    );
  }
}

class ParticipantInfo {
  final int userId;
  final bool isMost;
  final double contributionRate;

  ParticipantInfo({
    required this.userId,
    required this.isMost,
    required this.contributionRate,
  });

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['userId'],
      isMost: json['isMost'] ?? false, // null일 경우 false 처리
      contributionRate: (json['contributionRate'] as num).toDouble(),
    );
  }
}
