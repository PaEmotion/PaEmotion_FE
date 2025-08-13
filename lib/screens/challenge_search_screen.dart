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

  // ✅ 현재 참여중 챌린지 존재 여부
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
    } catch (e) {
      // 조용히 실패 처리
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

    // 키보드 닫기
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
    } catch (e) {
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

  Future<void> _showJoinChallengeDialog(Challenge challenge) async {
    // ✅ 이미 참여 중이면 참여 차단
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
        title: Text(challenge.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📆 종료일: ${challenge.endDate.toIso8601String().split('T').first}'),
              Text('🎯 목표 개수: ${challenge.goalCount}'),
              Text('👥 참여자 수: ${challenge.participantCount}명'),
              const SizedBox(height: 12),
              if (!challenge.publicityType)
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 입력',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              // 비공개인데 비밀번호 없으면 바로 경고
              if (!challenge.publicityType &&
                  passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('비밀번호를 입력해주세요.')),
                );
                return;
              }

              final response = await ChallengeService.joinChallenge(
                challengeId: challenge.challengeId,
                password: challenge.publicityType
                    ? null
                    : passwordController.text.trim(),
              );

              // 네트워크 오류 등으로 응답 자체가 없을 때
              if (response == null) {
                Navigator.pop(context, {
                  'joined': false,
                  'msg': '서버 응답이 없습니다. 네트워크를 확인해주세요.'
                });
                return;
              }

              if (response.statusCode == 200) {
                // ✅ 로컬 저장 제거: 서버를 단일 소스로
                Navigator.pop(context, {
                  'joined': true,
                  'msg': '챌린지에 참여했습니다!'
                });
              } else {
                // 실패: 서버 메시지 그대로 노출
                String msg = '챌린지 참여에 실패했습니다.';
                final body = response.data;

                if (body is Map) {
                  msg = (body['detail'] ?? body['message'] ?? msg).toString();
                } else if (body is String) {
                  // 문자열이면 JSON일 수도 있고 그냥 문자열일 수도 있음
                  try {
                    final parsed = jsonDecode(body);
                    if (parsed is Map && parsed['detail'] != null) {
                      msg = parsed['detail'].toString();
                    } else if (parsed is Map && parsed['message'] != null) {
                      msg = parsed['message'].toString();
                    } else {
                      msg = body; // 그냥 문자열
                    }
                  } catch (_) {
                    msg = body; // JSON 아니면 원문 그대로
                  }
                }

                Navigator.pop(context, {
                  'joined': false,
                  'msg': msg
                });
              }
            },
            child: const Text('참여하기'),
          ),
        ],
      ),
    );

    // 다이얼로그 닫힌 뒤 결과 처리
    if (!mounted || result == null) return;

    final joined = result['joined'] == true;
    final msg = (result['msg']?.toString() ?? (joined ? '참여 완료' : '참여 실패'));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    if (joined) {
      // ✅ 참여 성공 시: 부모 화면에서 재조회할 수 있게 이 화면을 닫음
      Navigator.pop(context, true);
      return;
    }

    // 실패 시에는 현재 화면 유지. 필요하면 최근 목록 갱신
    // await _search();
  }

  @override
  Widget build(BuildContext context) {
    final topBanner = _isLoadingCurrent
        ? const SizedBox.shrink()
        : _hasCurrentChallenge
        ? Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Text(
        '이미 참여 중인 챌린지가 있어 새로 참여할 수 없습니다.',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
      ),
    )
        : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('챌린지 검색', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 현재 상태 배너
            topBanner,

            // 검색창
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      decoration: const InputDecoration(
                        hintText: '챌린지 이름을 입력하세요',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                  tooltip: '검색',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 검색 결과
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
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
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  challenge.publicityType ? '공개 챌린지' : '비공개 챌린지',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  challenge.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '목표: ${challenge.goalCount}개, 참여자: ${challenge.participantCount}명\n종료일: ${challenge.endDate.toIso8601String().split('T').first}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            trailing: Icon(
                              challenge.publicityType ? Icons.lock_open : Icons.lock,
                              color: Colors.blueGrey[700],
                            ),
                            onTap: disabled ? null : () => _showJoinChallengeDialog(challenge),
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
