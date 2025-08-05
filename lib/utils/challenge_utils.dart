import 'package:dio/dio.dart';
import '../models/challenge.dart';
import '../api/api_client.dart';

class ChallengeService {
  /// 현재 참여중인 챌린지 ID 조회
  static Future<int?> getCurrentChallengeId() async {
    try {
      print('[DEBUG] /challenges/current 요청 시작');
      final response = await ApiClient.dio.get(
        '/challenges/current',
        options: Options(validateStatus: (status) => true),
      );
      print('상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.data}');

      if (response.data is! Map<String, dynamic>) return null;

      final rawData = response.data as Map<String, dynamic>;
      final data = rawData['data'] as Map<String, dynamic>? ?? {};
      final challengeId = data['challenge_id'] ?? data['challengeId'];

      if (challengeId != null) {
        print('[DEBUG] challengeId 발견: $challengeId');
        return (challengeId as num).toInt();
      }
      print('[DEBUG] challengeId 없음, null 반환');
      return null;
    } on DioException catch (e) {
      print('[DEBUG] DioException 발생 - 상태 코드: ${e.response?.statusCode}');
      if (e.response?.statusCode == 404) {
        print('[DEBUG] 404 Not Found - 참여중인 챌린지 없음');
        return null;
      }
      print('현재 참여중인 챌린지 조회 오류: ${e.message}');
      return null;
    } catch (e) {
      print('[DEBUG] 기타 예외 발생: $e');
      return null;
    }
  }

  /// 챌린지 생성
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
      print('[DEBUG] createChallenge 응답 상태: ${response.statusCode}');
      print('[DEBUG] createChallenge 응답 데이터: ${response.data}');
      return response;
    } on DioException catch (e) {
      print('[DEBUG] createChallenge DioException 상태: ${e.response?.statusCode}');
      print('[DEBUG] createChallenge DioException 응답 데이터: ${e.response?.data}');
      return e.response;
    }
  }

  /// 챌린지 참여
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
      print('[DEBUG] joinChallenge 응답 상태: ${response.statusCode}');
      print('[DEBUG] joinChallenge 응답 데이터: ${response.data}');
      final responseData = response.data['data'];
      return responseData;
    } on DioException catch (e) {
      print('[DEBUG] joinChallenge DioException 상태: ${e.response?.statusCode}');
      print('[DEBUG] joinChallenge DioException 응답 데이터: ${e.response?.data}');
      return e.response;
    }
  }

  /// 챌린지 검색
  static Future<List<Challenge>?> searchChallenge(String keyword) async {
    try {
      final response = await ApiClient.dio.get(
        '/challenges/search',
        queryParameters: {'name': keyword},
      );

      print('[DEBUG] searchChallenge 응답 상태: ${response.statusCode}');
      print('[DEBUG] searchChallenge 응답 데이터: ${response.data}');

      final Map<String, dynamic> rawData = response.data;

      // success 체크
      if (rawData['success'] != true) {
        print('[ERROR] 서버에서 실패 응답: ${rawData['message']}');
        return null;
      }

      final data = rawData['data'];

      if (data is List) {
        return data.map((json) => Challenge.fromJson(json)).toList();
      }

      print('[ERROR] 예상하지 못한 데이터 형식');
      return null;
    } catch (e, stackTrace) {
      print('챌린지 검색 오류: $e');
      print(stackTrace);
      return null;
    }
  }


  /// 챌린지 목록 조회
  static Future<List<Challenge>> getChallengeList() async {
    try {
      final response = await ApiClient.dio.get('/challenges');

      print('[DEBUG] getChallengeList 응답 상태: ${response.statusCode}');
      print('[DEBUG] getChallengeList 응답 데이터: ${response.data}');

      final Map<String, dynamic> rawData = response.data;

      // success 체크
      if (rawData['success'] != true) {
        print('[ERROR] 실패 응답: ${rawData['message']}');
        return [];
      }

      final data = rawData['data'];

      if (data is List) {
        return data.map((e) => Challenge.fromJson(e)).toList();
      } else {
        print('[ERROR] data가 List 타입이 아님: $data');
        return [];
      }
    } catch (e, stackTrace) {
      print('챌린지 목록 조회 오류: $e');
      print(stackTrace);
      return [];
    }
  }

  /// 챌린지 단건 조회
  static Future<Challenge?> getChallengeById(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/$challengeId');
      print('[DEBUG] getChallengeById 응답 상태: ${response.statusCode}');
      print('[DEBUG] getChallengeById 응답 데이터: ${response.data}');

      final Map<String, dynamic> rawData = response.data;

      // 응답 성공 여부 확인
      if (rawData['success'] != true) {
        print('[ERROR] 실패 응답: ${rawData['message']}');
        return null;
      }

      final data = rawData['data'];
      if (data is! Map<String, dynamic>) {
        print('[ERROR] data 필드가 객체가 아님: $data');
        return null;
      }

      return Challenge.fromJson(data);
    } catch (e, stackTrace) {
      print('챌린지 단건 조회 오류: $e');
      print(stackTrace);
      return null;
    }
  }

  /// 챌린지 상세 조회
  static Future<Map<String, dynamic>?> getChallengeDetail(int challengeId) async {
    try {
      final response = await ApiClient.dio.get('/challenges/detail/$challengeId');
      print('[DEBUG] getChallengeDetail 응답 상태: ${response.statusCode}');
      print('[DEBUG] getChallengeDetail 응답 데이터: ${response.data}');

      final Map<String, dynamic> rawData = response.data;

      // success 필드 확인
      if (rawData['success'] != true) {
        print('[ERROR] 실패 응답: ${rawData['message']}');
        return null;
      }

      final data = rawData['data'];
      if (data is Map<String, dynamic>) {
        return data;
      } else {
        print('[ERROR] data 필드가 객체가 아님: $data');
        return null;
      }
    } catch (e, stackTrace) {
      print('챌린지 상세 조회 오류: $e');
      print(stackTrace);
      return null;
    }
  }

  /// 현재 참여중인 챌린지 전체 정보
  static Future<Challenge?> getCurrentChallenge() async {
    final id = await getCurrentChallengeId();
    if (id == null) return null;
    return await getChallengeById(id);
  }
}
