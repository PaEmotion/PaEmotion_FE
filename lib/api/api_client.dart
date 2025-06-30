// lib/api/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );
}
