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
    final user = UserManager().currentUser;
    if (user == null) {
      widget.onLogout();
      return;
    }

    try {
      await ApiClient.ensureValidAccessToken();

      if (UserManager().currentUser == null) {
        widget.onLogout();
      }
    } catch (_) {
      await UserManager().logout();
      widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
