import 'package:flutter/widgets.dart';

/// 기준 디자인 사이즈: 너비 1080, 높이 2400 (
const double _baseWidth = 1080;
const double _baseHeight = 2400;

/// 화면 너비 비례 계산
double rWidth(BuildContext context, double base) {
  final w = MediaQuery.of(context).size.width;
  return base * (w / _baseWidth);
}

/// 화면 높이 비례 계산
double rHeight(BuildContext context, double base) {
  final h = MediaQuery.of(context).size.height;
  return base * (h / _baseHeight);
}

/// 폰트 크기 비례 (텍스트 스케일과 너비 기준 반영)
double rFont(BuildContext context, double base) {
  final scale = MediaQuery.of(context).textScaleFactor;
  final w = MediaQuery.of(context).size.width;
  return base * scale * (w / _baseWidth);
}

/// 최소/최대 제한을 함께 쓸 수 있는 헬퍼
double clampWidth(BuildContext context, double base, {double? min, double? max}) {
  final val = rWidth(context, base);
  if (min != null && val < min) return min;
  if (max != null && val > max) return max;
  return val;
}
