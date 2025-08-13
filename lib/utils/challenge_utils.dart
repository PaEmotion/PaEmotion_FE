import 'package:dio/dio.dart';
import '../models/challenge.dart';
import '../api/api_client.dart';

class ChallengeService {
  // 현재 참여중인 챌린지 ID 조회
  static Future<int?> getCurrentChallengeId() async {
    try {
      final response = await ApiClient.dio.get(
        '/challenges/current',
        options: Options(validateStatus: (status) => true),
      );

      if (response.data is! Map<String, dynamic>) return null;

      final rawData = response.data as Map<String, dynamic>;
      final data = rawData['data'] as Map<String, dynamic>? ?? {};
      final challengeId = data['challenge_id'] ?? data['challengeId'];

      if (challengeId != null) {
        return (challengeId as num).toInt();
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 챌린지 생성
  static Future<Response?> createChallenge({
    required String name,
    required bool challengeType,
    required bool publicityType,
    String? password,
    required int goalCount,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'publicityType': publicityType,
        'challengeType': challengeType,
        'goalCount': goalCount,
      };
      if (!publicityType && password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      final response = await ApiClient.dio.post('/challenges/create', data: body);
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  // 챌린지 참여
  static Future<Response?> joinChallenge({
    required int challengeId,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{'challengeId': challengeId};
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }
      final response = await ApiClient.dio.post('/challenges/join', data: body);
      final responseData = response.data['data'];
      return responseData;
    } on DioException catch (e) {
      return e.response;
    }
  }

  // 챌린지 검색
  static Future<List<Challenge>?> searchChallenge(String keyword) async {
    try {
      final response = await ApiClient.dio.get(
        '/challenges/search',
        queryParameters: {'name': keyword},
      );

      final Map<String, dynamic> rawData = response.data;
      final data = rawData['data'];

      if (data is List) {
        return data.map((json) => Challenge.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  // 챌린지 목록 조회
  static Future<List<Challenge>> getChallengeList() async {
    try {
      final response = await ApiClient.dio.get('/challenges');
      final Map<String, dynamic> rawData = response.data;
      final data = rawData['data'];

      if (data is List) {
        return data.map((e) => Challenge.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 챌린지 단건 조회
  static Future<Challenge?> getChallengeById(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/$challengeId');
      final Map<String, dynamic> rawData = response.data;

      if (rawData['success'] != true) {
        return null;
      }

      final data = rawData['data'];
      if (data is! Map<String, dynamic>) {
        return null;
      }

      return Challenge.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // 챌린지 상세 조회
  static Future<Map<String, dynamic>?> getChallengeDetail(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/detail/$challengeId');
      final Map<String, dynamic> rawData = response.data;
      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // 현재 참여중인 챌린지 전체 정보 조회
  static Future<Challenge?> getCurrentChallenge() async {
    final id = await getCurrentChallengeId();
    if (id == null) return null;
    return await getChallengeById(id);
  }
}
