import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://d6e1eb659c9b.ngrok-free.app',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..options.followRedirects = true
    ..options.maxRedirects = 5// 리다이렉션 허용
    ..options.validateStatus = (status) {
      return status != null && status < 500; // 500 미만 상태는 정상으로 간주
    };
}

