import 'package:dio/dio.dart';
import '../models/challenge.dart';
import '../api/api_client.dart';

class ChallengeService {
  static Future<int?> getCurrentChallengeId() async {
    try {
      final response = await ApiClient.dio.get(
        '/challenges/current',
        options: Options(validateStatus: (status) => true),
      );
      print('상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.data}');
      final data = response.data;
      if (data is Map<String, dynamic> && data['challengeId'] != null) {
        return (data['challengeId'] as num).toInt();
      }
      return null;
    } on DioException catch (e) {
      print('[DEBUG] DioException 발생 - 상태 코드: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        return null;
      }
      print('현재 참여중인 챌린지 조회 오류: ${e.message}');
      return null;
    } catch (e) {
      return null;
    }
  }





  static Future<Response?> createChallenge({
    required String name,
    required bool challengeType, // true: feed, false: protect
    required bool publicityType, // true: 공개, false: 비공개
    String? password,
    required int goalCount,
  }) async {
    try {
      final data = <String, dynamic>{
        'name': name,
        'publicityType': publicityType,
        'challengeType': challengeType,
        'goalCount': goalCount,
      };
      if (!publicityType && password != null && password.isNotEmpty) {
        data['password'] = password;
      }
      final response = await ApiClient.dio.post('/challenges/create', data: data);
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  static Future<Response?> joinChallenge({
    required int challengeId,
    String? password,
  }) async {
    try {
      final data = <String, dynamic>{ 'challengeId': challengeId };
      if (password != null && password.isNotEmpty) {
        data['password'] = password;
      }
      final response = await ApiClient.dio.post('/challenges/join', data: data);
      return response;
    } on DioException catch (e) {
      return e.response;
    }
  }

  static Future<List<Challenge>?> searchChallenge(String keyword) async {
    try {
      final response = await ApiClient.dio.get(
        '/challenges/search',
        queryParameters: {'name': keyword},
      );

      final data = response.data;

      if (data is List) {
        return data.map((json) => Challenge.fromJson(json)).toList();
      }

      if (data is Map<String, dynamic> && data.containsKey('challengeId')) {
        return [Challenge.fromJson(data)];
      }

      return null;
    } catch (e) {
      print('챌린지 검색 오류: $e');
      return null;
    }
  }

  static Future<List<Challenge>> getChallengeList() async {
    try {
      final response = await ApiClient.dio.get('/challenges');
      final List<dynamic> data = response.data;
      return data.map((e) => Challenge.fromJson(e)).toList();
    } catch (e) {
      print('챌린지 목록 조회 오류: $e');
      return [];
    }
  }

  static Future<Challenge?> getChallengeById(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/$challengeId');
      return Challenge.fromJson(response.data);
    } catch (e) {
      print('챌린지 단건 조회 오류: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getChallengeDetail(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/detail/$challengeId');
      return response.data;
    } catch (e) {
      print('챌린지 상세 조회 오류: $e');
      return null;
    }
  }

  static Future<Challenge?> getCurrentChallenge() async {
    final id = await getCurrentChallengeId();
    if (id == null) return null;
    return await getChallengeById(id);
  }
}
