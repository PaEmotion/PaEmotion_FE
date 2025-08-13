import 'dart:convert';

class ReportRequest {
  final String period;
  final String tone;
  final String reportDate;

  ReportRequest({
    required this.period,
    required this.tone,
    required this.reportDate,
  });

  Map<String, dynamic> toJson() => {
    'period': period,
    'tone': tone,
    'reportDate': reportDate,
  };

  String toJsonString() => jsonEncode(toJson());
}
