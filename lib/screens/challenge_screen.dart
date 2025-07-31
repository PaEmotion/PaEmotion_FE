import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/challenge.dart';
import '../models/challenge_detail.dart';
import '../utils/challenge_utils.dart';
import 'challenge_creating_screen.dart';
import 'challenge_search_screen.dart';
import '../models/user.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ChallengeDetail? _myChallengeDetail;
  bool _isLoadingMyChallenge = false;

  List<Challenge> _allChallenges = [];
  bool _isLoadingAllChallenges = false;

  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentUser();
    _loadMyChallenge();
    _loadAllChallenges();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('user');
      if (jsonString == null) return;
      final userMap = jsonDecode(jsonString);
      final user = User.fromJson(userMap);
      setState(() {
        _currentUserId = user.id;
      });
    } catch (e) {
      debugPrint('[loadCurrentUser] $e');
    }
  }

  String _formatChallengePeriod(DateTime endDate) {
    final startDate = endDate.subtract(const Duration(days: 6));
    String fmt(DateTime d) => '${d.year}.${_twoDigits(d.month)}.${_twoDigits(d.day)}';
    return '${fmt(startDate)} ~ ${fmt(endDate)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // 서버에 현재 참여중 챌린지 ID를 요청 => 있으면 상세 조회 => 화면에 표시
  Future<void> _loadMyChallenge() async {
    setState(() => _isLoadingMyChallenge = true);
    try {
      final currentId = await ChallengeService.getCurrentChallengeId();
      if (currentId == null) {
        setState(() {
          _myChallengeDetail = null;
          _isLoadingMyChallenge = false;
        });
        return;
      }

      final detailData = await ChallengeService.getChallengeDetail(currentId);
      if (detailData == null) {
        setState(() {
          _myChallengeDetail = null;
          _isLoadingMyChallenge = false;
        });
        return;
      }

      final detail = ChallengeDetail.fromJson(detailData);

      // 종료된 챌린지는 표시하지 않음
      if (detail.endDate.isBefore(DateTime.now())) {
        setState(() {
          _myChallengeDetail = null;
          _isLoadingMyChallenge = false;
        });
        return;
      }

      setState(() {
        _myChallengeDetail = detail;
        _isLoadingMyChallenge = false;
      });
    } catch (e, stack) {
      print('[loadMyChallenge] 예외 발생: $e\n$stack');
      setState(() {
        _myChallengeDetail = null;
        _isLoadingMyChallenge = false;
      });
    }
  }

  Future<void> _loadAllChallenges() async {
    setState(() => _isLoadingAllChallenges = true);
    final challenges = await ChallengeService.getChallengeList();
    setState(() {
      _allChallenges = challenges;
      _isLoadingAllChallenges = false;
    });
  }

  Future<void> _showJoinChallengeDialog(Challenge challenge) async {
    if (_myChallengeDetail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 참여 중인 챌린지가 있습니다.')),
      );
      return;
    }

    if (challenge.publicityType) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('참여하기'),
          content: Text('${challenge.name} 챌린지에 참여하시겠습니까?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('참여')),
          ],
        ),
      );
      if (confirmed == true) {
        await _joinChallenge(challenge.challengeId);
      }
    } else {
      final passwordController = TextEditingController();
      final joined = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${challenge.name} 비공개 챌린지 참여'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: '비밀번호'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('참여')),
          ],
        ),
      );
      if (joined == true) {
        final pw = passwordController.text.trim();
        if (pw.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호를 입력해주세요.')),
          );
          return;
        }
        await _joinChallenge(challenge.challengeId, password: pw);
      }
    }
  }

  Future<void> _joinChallenge(int challengeId, {String? password}) async {
    final res = await ChallengeService.joinChallenge(
      challengeId: challengeId,
      password: password,
    );

    if (res == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서버 응답이 없습니다. 네트워크를 확인해주세요.')),
      );
      return;
    }

    if (res.statusCode == 200) {
      await _loadMyChallenge();
      await _loadAllChallenges();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('챌린지 참여 성공!')),
      );
      _tabController.animateTo(0);
      return;
    }

    String msg = '챌린지 참여 실패';
    final body = res.data;

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

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  final List<String> guineaNames = [
    '행복한 기니피그',
    '행운의 기니피그',
    '똑똑한 기니피그',
    '친절한 기니피그',
    '귀여운 기니피그',
  ];

  Widget _buildMyChallengeTab() {
    if (_isLoadingMyChallenge) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myChallengeDetail == null) {
      return const Center(child: Text('현재 참여중인 챌린지가 없습니다.'));
    }

    final detail = _myChallengeDetail!;

    // 내 기니피그 이름 구하기
    int? myIdx;
    if (_currentUserId != null) {
      final idx = detail.participantsInfo.indexWhere((p) => p.userId == _currentUserId);
      if (idx >= 0) myIdx = idx;
    }
    final String? myGuineaName = (myIdx != null) ? guineaNames[myIdx % guineaNames.length] : null;

    // 긍/부정
    final bool isPositive = detail.challengeType == true;

    // 목표 텍스트
    final String goalText = isPositive
        ? '긍정적 소비 ${detail.goalCount}개 하기'
        : '부정적 소비 ${detail.goalCount}개 이하로 하기';

    // 기니피그 밥 상태 텍스트
    final String feedText = isPositive
        ? '${detail.guineaFeedCurrent}개 있어요'
        : '${detail.guineaFeedCurrent}개 남았어요';

    // 팀 진행률 값(0~1)
    final double teamProgressValue =
        ((detail.teamProgressRate).clamp(0, 100) as num).toDouble() / 100.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            detail.name,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 기간
          Text(
            _formatChallengePeriod(detail.endDate),
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),

          // 참여자 수 + 기니피그 풀 상태
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 참여자 수
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.people_outline, color: Colors.black87, size: 20),
                        SizedBox(width: 6),
                        Text('참여자 수', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${detail.participantsInfo.length}명', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 기니피그 풀 상태 (풀 아이콘으로 변경)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.grass, color: Colors.black87, size: 20),
                        SizedBox(width: 6),
                        Text('기니피그 풀 상태', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(feedText, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 개인별 목표
          Row(
            children: const [
              Icon(Icons.flag, color: Colors.black87, size: 20),
              SizedBox(width: 6),
              Text('개인별 목표', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(goalText, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 16),

          // 팀 진행률 타이틀
          Row(
            children: const [
              Icon(Icons.show_chart, color: Colors.black87, size: 20),
              SizedBox(width: 6),
              Text('팀 진행률', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          // 이미지
          Center(
            child: Image.asset(
              detail.teamProgressRate >= 50
                  ? 'lib/assets/opened_guinea.png'
                  : 'lib/assets/closed_guinea.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              '현재 ${detail.teamProgressRate.toStringAsFixed(1)}% 만큼 진행중이에요.\n'
                  '${isPositive ? "기니피그가 밥을 기다리고 있어요!" : "계속해서 기니피그의 밥을 지켜주세요!"}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),

          // 프로그래스바를 이미지 밑으로 이동
          LayoutBuilder(
            builder: (context, constraints) {
              final parent = constraints.maxWidth;
              final target = parent * 0.9;              // 부모의 90%
              final width = target.clamp(200.0, 420.0); // 200~420px
              return Align(
                alignment: Alignment.center,             // 가운데 정렬
                child: SizedBox(
                  width: width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: teamProgressValue,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      color: detail.teamProgressRate >= 100 ? Colors.green : Colors.lightGreen,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 10),

          // 참여자 공헌도 타이틀 + 내 기니피그 표시
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                '참여자 공헌도',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (myGuineaName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Text(
                    '내 기니피그: $myGuineaName',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detail.participantsInfo.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final nickname = guineaNames[index % guineaNames.length];
              final bool isMe = (_currentUserId != null && p.userId == _currentUserId);

              final double progressValue =
                  ((p.contributionRate).clamp(0, 100) as num).toDouble() / 100.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이름 왼쪽 정렬 + 기여도 %
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '• $nickname${isMe ? ' (나)' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${p.contributionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: p.isMost ? Colors.orange : Colors.black87,
                            fontWeight: p.isMost ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // 막대: 팀 진행률 바처럼 가운데 정렬 + 폭 비율/클램프
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final parent = constraints.maxWidth;
                        final target = parent * 0.9;              // 부모의 90%
                        final width  = target.clamp(200.0, 420.0); // 200~420px
                        return Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: width,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                color: p.isMost ? Colors.orange : Colors.lightGreen,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildAllChallengesTab() {
    if (_isLoadingAllChallenges) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allChallenges.isEmpty) {
      return const Center(child: Text('생성된 챌린지가 없습니다.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _allChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _allChallenges[index];
        final bgColor = challenge.challengeType ? Colors.yellow[100] : Colors.blue[100];

        return Card(
          color: bgColor,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.publicityType ? '공개 챌린지' : '비공개 챌린지',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey[700]),
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
            onTap: () => _showChallengeDetailDialog(challenge),
          ),
        );
      },
    );
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
              const SizedBox(height: 6),
              Text('챌린지 타입: ${challenge.challengeType ? '기니피그 밥 주기(긍정 소비)' : '기니피그 밥 지키기(부정 소비)'}'),
              const SizedBox(height: 6),
              Text('공개 여부: ${challenge.publicityType ? '공개' : '비공개'}'),
              const SizedBox(height: 6),

              // 여기서 목표 텍스트 조건 처리
              Text(
                challenge.challengeType
                    ? '개인별 목표 소비 개수: ${challenge.goalCount}번'
                    : '개인별 목표 소비 개수: ${challenge.goalCount}번 이하',
              ),

              const SizedBox(height: 6),
              Text('참여자 수: ${challenge.participantCount}명'),
              const SizedBox(height: 6),
              Text('종료일: ${challenge.endDate.toIso8601String().split('T').first}'),
              const SizedBox(height: 6),
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


  void _goToCreateChallenge() {
    if (_myChallengeDetail != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 참여 중인 챌린지가 있어 새로 생성할 수 없습니다.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengeCreatingScreen()),
    ).then((value) {
      _loadMyChallenge();
      _loadAllChallenges();
    });
  }

  void _goToSearchChallenge() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChallengeSearchScreen()),
    ).then((value) {
      _loadMyChallenge();
      _loadAllChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('챌린지', style: TextStyle(color: Colors.black87)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _goToSearchChallenge,
            tooltip: '챌린지 검색',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.black38,
          indicatorColor: Colors.black87,
          tabs: const [
            Tab(text: '내 챌린지'),
            Tab(text: '전체 챌린지'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyChallengeTab(),
          _buildAllChallengesTab(),
        ],
      ),
      floatingActionButton: _myChallengeDetail == null
          ? FloatingActionButton.extended(
        onPressed: _goToCreateChallenge,
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
        label: const Text('챌린지 만들기'),
      )
          : null,
    );
  }
}
