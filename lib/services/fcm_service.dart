import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../utils/user_storage.dart';
import '../api/api_client.dart';
import '../constants/api_endpoints/user_api.dart';
import '../screens/report_screen.dart';
import '../main.dart';

class FCMService {
  /// FCM 초기화
  static Future<void> initFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // iOS 권한 요청
    //NotificationSettings settings = await messaging.requestPermission(
      //alert: true,
      //badge: true,
      ///sound: true,
    //);

    //if (settings.authorizationStatus == AuthorizationStatus.denied) {
      //print("⚠FCM 권한 거부됨");
      //return;
    //}

    String? token = await messaging.getToken();
    print("📲 내 기기 FCM 토큰: $token");

    if (token != null) await _sendTokenToServer(token);

    messaging.onTokenRefresh.listen((newToken) async {
      print("🔄 토큰 갱신: $newToken");
      await _sendTokenToServer(newToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 포그라운드 알림: ${message.notification?.title}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final userMap = await UserStorage.loadProfileJson();
      if (userMap == null) {
        print("로그인 정보 없음, 서버에 토큰 전송 불가");
        return;
      }

      final userId = userMap['userId'];

      final response = await ApiClient.dio.post(
        UserApi.alarm,
        data: {
          "userId": userId,
          "fcmToken": token,
        },
      );

      if (response.statusCode == 200) {
        print("토큰 서버에 저장 성공");
      } else {
        print("서버 응답 문제: ${response.statusCode}");
      }
    } catch (e) {
      print("토큰 서버 저장 실패: $e");
    }
  }

  /// 알림 클릭 처리
  static void _handleNotificationClick(RemoteMessage message) {
    print("알림 클릭 데이터: ${message.data}");

    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ReportScreen()),
    );
  }
}
