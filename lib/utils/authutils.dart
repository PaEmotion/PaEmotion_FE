import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../utils/user_manager.dart';

class TokenCheckerWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onLogout;

  const TokenCheckerWidget({
    required this.child,
    required this.onLogout,
    Key? key,
  }) : super(key: key);

  @override
  State<TokenCheckerWidget> createState() => _TokenCheckerWidgetState();
}

class _TokenCheckerWidgetState extends State<TokenCheckerWidget> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    // 현재 로그인 상태 확인
    final user = UserManager().currentUser;
    if (user == null) {
      widget.onLogout();
      return;
    }

    try {
      // ApiClient 내부에서 만료 임박이면 refresh 처리해주고 실패하면 예외가 날 수 있으니 잡아서 로그아웃
      await ApiClient.ensureValidAccessToken();
      // 이후 현재 User가 여전히 존재하면 세션 유지
      if (UserManager().currentUser == null) {
        widget.onLogout();
      }
    } catch (_) {
      // refresh 실패 또는 다른 문제
      await UserManager().logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
