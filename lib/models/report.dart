class Report {
  final String reportDate;   // 2025-07-20
  final String reportType;   // daily, weekly, monthly
  final String reportText;
  final int reportId;
  final int userId;

  Report({
    required this.reportDate,
    required this.reportType,
    required this.reportText,
    required this.reportId,
    required this.userId
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportDate: json['reportDate'],
      reportType: json['reportType'],
      reportText: json['reportText'],
      reportId: (json['reportId'] as num).toInt(),
      userId: (json['userId'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportDate': reportDate,
      'reportType': reportType,
      'reportText': reportText,
      'reportId': reportId,
      'userId': userId
    };
  }
}
