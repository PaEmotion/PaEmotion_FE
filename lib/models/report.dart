class Report {
  final String reportDate;   // 2025-07-20
  final String reportType;   // daily, weekly, monthly
  final String reportText;

  Report({
    required this.reportDate,
    required this.reportType,
    required this.reportText,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportDate: json['reportDate'],
      reportType: json['reportType'],
      reportText: json['reportText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reportDate': reportDate,
      'reportType': reportType,
      'reportText': reportText,
    };
  }
}
