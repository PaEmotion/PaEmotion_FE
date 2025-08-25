import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_screen.dart';
import '../api/api_client.dart';
import '../models/user.dart';
import '../utils/user_manager.dart';
import 'mp_edit_screen.dart';
import 'mp_pwreset_screen.dart';
import 'test_main_screen.dart';
import 'termswebview_screen.dart';
import '../constants/api_endpoints/user_api.dart';


class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final alltermsUrl = dotenv.env['ALLTERMS_URL'] ?? '';

  String? _nickname = '사용자';
  bool _isLoading = true;

  double _responsiveFont(double base, BuildContext context) {
    final scale = MediaQuery.of(context).textScaleFactor;
    final computed = base * scale;
    return computed.clamp(base * 0.9, base * 1.3);
  }

  EdgeInsets _contentPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return const EdgeInsets.symmetric(horizontal: 12, vertical: 16);
    if (width < 600) return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
  }

  double _iconSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 48;
    if (width < 600) return 56;
    return 64;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await ApiClient.dio.get(
        UserApi.me,
      );

      if (response.statusCode == 200) {
        final body = response.data;
        final data = body['data'] ?? {};
        final nicknameFromApi = data['nickname'] as String?;
        if (!mounted) return;
        setState(() {
          _nickname = (nicknameFromApi != null && nicknameFromApi.isNotEmpty)
              ? nicknameFromApi
              : _nickname;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await UserManager().logout();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void openWebLink(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TermsWebViewPage(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: _responsiveFont(24, context),
      fontWeight: FontWeight.bold,
    );
    final sectionTitleStyle = TextStyle(
      fontSize: _responsiveFont(18, context),
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = TextStyle(
      fontSize: _responsiveFont(16, context),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            padding: _contentPadding(context),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: _iconSize(context),
                          color: Colors.grey,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _nickname ?? '사용자',
                            style: titleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: '닉네임 수정',
                          onPressed: () async {
                            final updatedUser = await Navigator.push<User?>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MpEditScreen(),
                              ),
                            );

                            if (updatedUser != null) {
                              setState(() {
                                _nickname = updatedUser.nickname;
                              });
                            } else {
                              await _fetchUserInfo();
                            }
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Text('개인정보', style: sectionTitleStyle),
                    SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.lock_reset),
                      title: Text('비밀번호 변경', style: bodyStyle),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MpPwResetScreen()),
                        );
                      },
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 40),
                    Text('기타', style: sectionTitleStyle),
                    SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.psychology_alt),
                      title: Text('소비성향 테스트', style: bodyStyle),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TestMainScreen()),
                        );
                      },
                      trailing: const Icon(Icons.chevron_right),
                    ),
                    const Divider(height: 40),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.edit_note_outlined),
                      title: Text('이용약관 및 개인정보처리방침'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => openWebLink(context, alltermsUrl),
                    ),
                    const Divider(height: 40),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.logout),
                      title: Text('로그아웃'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
