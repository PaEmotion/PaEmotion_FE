import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/challenge.dart';
import '../utils/challenge_utils.dart';

class ChallengeSearchScreen extends StatefulWidget {
  const ChallengeSearchScreen({super.key});

  @override
  State<ChallengeSearchScreen> createState() => _ChallengeSearchScreenState();
}

class _ChallengeSearchScreenState extends State<ChallengeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Challenge> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  bool _hasCurrentChallenge = false;
  bool _isLoadingCurrent = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentChallengeStatus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentChallengeStatus() async {
    setState(() {
      _isLoadingCurrent = true;
    });
    try {
      final id = await ChallengeService.getCurrentChallengeId();
      setState(() {
        _hasCurrentChallenge = id != null;
      });
    } catch (_) {
      setState(() {
        _hasCurrentChallenge = false;
      });
    } finally {
      setState(() {
        _isLoadingCurrent = false;
      });
    }
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      setState(() {
        _searchResults.clear();
        _error = null;
      });
      return;
    }

    _searchFocus.unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _searchResults.clear();
    });

    try {
      final result = await ChallengeService.searchChallenge(keyword);
      if (result == null || result.isEmpty) {
        setState(() {
          _searchResults = [];
          _error = '검색 결과가 없습니다.';
        });
      } else {
        setState(() {
          _searchResults = result;
          _error = null;
        });
      }
    } catch (_) {
      setState(() {
        _searchResults = [];
        _error = '검색 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void _showChallengeDetailDialog(Challenge challenge) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(challenge.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: rHeight(context, 6)),
              Text('챌린지 타입: ${challenge.challengeType ? '기니피그 밥 주기(긍정 소비)' : '기니피그 밥 지키기(부정 소비)'}'),
              SizedBox(height: rHeight(context, 6)),
              Text('공개 여부: ${challenge.publicityType ? '공개' : '비공개'}'),
              SizedBox(height: rHeight(context, 6)),
              Text(
                challenge.challengeType
                    ? '개인별 목표 소비 개수: ${challenge.goalCount}번'
                    : '개인별 목표 소비 개수: ${challenge.goalCount}번 이하',
              ),
              SizedBox(height: rHeight(context, 6)),
              Text('참여자 수: ${challenge.participantCount}명'),
              SizedBox(height: rHeight(context, 6)),
              Text('종료일: ${challenge.endDate.toIso8601String().split('T').first}'),
              SizedBox(height: rHeight(context, 6)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showJoinChallengeDialog(challenge);
            },
            child: const Text('참여하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinChallengeDialog(Challenge challenge) async {
    if (_hasCurrentChallenge) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 참여 중인 챌린지가 있습니다.')),
      );
      return;
    }

    final passwordController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          challenge.name,
          style: TextStyle(fontSize: rFont(context, 16), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: rHeight(context, 6)),
              Text('챌린지 타입: ${challenge.challengeType ? '기니피그 밥 주기(긍정 소비)' : '기니피그 밥 지키기(부정 소비)'}'),
              SizedBox(height: rHeight(context, 6)),
              Text('공개 여부: ${challenge.publicityType ? '공개' : '비공개'}'),
              SizedBox(height: rHeight(context, 6)),
              Text(
                challenge.challengeType
                    ? '개인별 목표 소비 개수: ${challenge.goalCount}번'
                    : '개인별 목표 소비 개수: ${challenge.goalCount}번 이하',
              ),
              SizedBox(height: rHeight(context, 6)),
              Text('참여자 수: ${challenge.participantCount}명'),
              SizedBox(height: rHeight(context, 6)),
              Text('종료일: ${challenge.endDate.toIso8601String().split('T').first}'),
              SizedBox(height: rHeight(context, 6)),
              SizedBox(height: rHeight(context, 12)),
              if (!challenge.publicityType)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: '비밀번호 입력',
                    border: const OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: rWidth(context, 12),
                      vertical: rHeight(context, 10),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('취소', style: TextStyle(fontSize: rFont(context, 14))),
          ),
          TextButton(
            onPressed: () async {
              if (!challenge.publicityType &&
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호를 입력해주세요.')),
                );
                return;
              }

              final response = await ChallengeService.joinChallenge(
                challengeId: challenge.challengeId,
                password:
                challenge.publicityType ? null : passwordController.text.trim(),
              );

              if (response == null) {
                Navigator.pop(context, {
                  'joined': false,
                  'msg': '서버 응답이 없습니다. 네트워크를 확인해주세요.',
                });
                return;
              }

              if (response.statusCode == 200) {
                Navigator.pop(context, {'joined': true, 'msg': '챌린지에 참여했습니다!'});
              } else {
                String msg = '챌린지 참여에 실패했습니다.';
                final body = response.data;
                if (body is Map) {
                  msg = (body['detail'] ?? body['message'] ?? msg).toString();
                } else if (body is String) {
                  try {
                    final parsed = jsonDecode(body);
                    if (parsed is Map && parsed['detail'] != null) {
                      msg = parsed['detail'].toString();
                    } else if (parsed is Map && parsed['message'] != null) {
                      msg = parsed['message'].toString();
                    } else {
                      msg = body;
                    }
                  } catch (_) {
                    msg = body;
                  }
                }
                Navigator.pop(context, {'joined': false, 'msg': msg});
              }
            },
            child: Text('참여하기', style: TextStyle(fontSize: rFont(context, 14))),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    final joined = result['joined'] == true;
    final msg = (result['msg']?.toString() ??
        (joined ? '참여 완료' : '참여 실패'));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (joined) {
      Navigator.pop(context, true);
    }
  }

  double rWidth(BuildContext context, double base) {
    final w = MediaQuery.of(context).size.width;
    return base * (w / 390);
  }

  double rHeight(BuildContext context, double base) {
    final h = MediaQuery.of(context).size.height;
    return base * (h / 844);
  }

  double rFont(BuildContext context, double base) {
    final scale = MediaQuery.of(context).textScaleFactor;
    return base * scale * (MediaQuery.of(context).size.width / 390);
  }

  @override
  Widget build(BuildContext context) {
    final topBanner = _isLoadingCurrent
        ? const SizedBox.shrink()
        : _hasCurrentChallenge
        ? Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: rHeight(context, 12)),
      padding: EdgeInsets.all(rWidth(context, 12)),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(rWidth(context, 8)),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        '이미 참여 중인 챌린지가 있어 새로 참여할 수 없습니다.',
        style: TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: rFont(context, 14),
        ),
      ),
    )
        : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '챌린지 검색',
          style: TextStyle(fontSize: rFont(context, 18), color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(rWidth(context, 16)),
        child: Column(
          children: [
            topBanner,
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(rWidth(context, 12)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: InputDecoration(
                        hintText: '챌린지 이름을 입력하세요',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: rWidth(context, 16),
                          vertical: rHeight(context, 14),
                        ),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: TextStyle(fontSize: rFont(context, 14)),
                    ),
                  ),
                ),
                SizedBox(width: rWidth(context, 8)),
                SizedBox(
                  height: rHeight(context, 44),
                  width: rWidth(context, 44),
                  child: IconButton(
                    icon: Icon(Icons.search, size: rWidth(context, 24)),
                    onPressed: _search,
                    tooltip: '검색',
                  ),
                ),
              ],
            ),
            SizedBox(height: rHeight(context, 20)),
            if (_isLoading)
              SizedBox(
                height: rHeight(context, 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red, fontSize: rFont(context, 14)))
            else if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final challenge = _searchResults[index];
                      final bgColor =
                      challenge.challengeType ? Colors.yellow[100] : Colors.blue[100];
                      final disabled = _hasCurrentChallenge;

                      return Opacity(
                        opacity: disabled ? 0.6 : 1.0,
                        child: Card(
                          color: bgColor,
                          margin: EdgeInsets.symmetric(
                            vertical: rHeight(context, 6),
                            horizontal: rWidth(context, 4),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: rHeight(context, 8),
                              horizontal: rWidth(context, 16),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.publicityType
                                      ? '공개 챌린지'
                                      : '비공개 챌린지',
                                  style: TextStyle(
                                    fontSize: rFont(context, 12),
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                SizedBox(height: rHeight(context, 4)),
                                Text(
                                  challenge.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: rFont(context, 18),
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: rHeight(context, 8)),
                              child: Text(
                                '목표: ${challenge.goalCount}개, 참여자: ${challenge.participantCount}명\n종료일: ${challenge.endDate.toIso8601String().split('T').first}',
                                style: TextStyle(fontSize: rFont(context, 14)),
                              ),
                            ),
                            trailing: Icon(
                              challenge.publicityType ? Icons.lock_open : Icons.lock,
                              color: Colors.blueGrey[700],
                              size: rWidth(context, 24),
                            ),
                            onTap: disabled
                                ? null
                                : () => _showChallengeDetailDialog(challenge),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
