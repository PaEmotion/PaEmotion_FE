import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/challenge.dart';
import '../models/challenge_detail.dart';
import '../utils/challenge_utils.dart';
import 'challenge_creating_screen.dart';
import 'challenge_search_screen.dart';
import '../utils/user_storage.dart';

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

  final List<String> guineaNames = [
    '행복한 기니피그',
    '행운의 기니피그',
    '똑똑한 기니피그',
    '멋있는 기니피그',
    '귀여운 기니피그',
  ];

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
      final userMap = await UserStorage.loadProfileJson();
      if (userMap == null) return;

      final userId = userMap['userId'];

      if (userId != null) {
        setState(() {
          _currentUserId = userId;
        });
      }
    } catch (e) {
      debugPrint('[loadCurrentUser] $e');
    }
  }

  String _formatChallengePeriod(DateTime endDate) {
    final startDate = endDate.subtract(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.year}.${_twoDigits(d.month)}.${_twoDigits(d.day)}';
    return '${fmt(startDate)} ~ ${fmt(endDate)}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

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
      debugPrint('[loadMyChallenge] 예외 발생: $e\n$stack');
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
        builder: (_) =>
            AlertDialog(
              title: const Text('참여하기'),
              content: Text('${challenge.name} 챌린지에 참여하시겠습니까?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                    child: const Text('참여')),
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
        builder: (_) =>
            AlertDialog(
              title: Text('${challenge.name} 비공개 챌린지 참여'),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소')),
                TextButton(onPressed: () => Navigator.pop(context, true),
                    child: const Text('참여')),
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

  String _assetForGuineaName(String name) {
    return switch (name) {
      '멋있는 기니피그' => 'lib/assets/cool_gui.png',
      '귀여운 기니피그' => 'lib/assets/cute_gui.png',
      '행운의 기니피그' => 'lib/assets/lucky_gui.png',
      '똑똑한 기니피그' => 'lib/assets/smart_gui.png',
      '행복한 기니피그' => 'lib/assets/happy_gui.png',
      _ => 'lib/assets/happy_gui.png',
    };
  }

  double rWidth(BuildContext context, double base) {
    final w = MediaQuery
        .of(context)
        .size
        .width;
    return base * (w / 390);
  }

  double rHeight(BuildContext context, double base) {
    final h = MediaQuery
        .of(context)
        .size
        .height;
    return base * (h / 844);
  }

  double rFont(BuildContext context, double base) {
    final scale = MediaQuery
        .of(context)
        .textScaleFactor;
    return base * scale * (MediaQuery
        .of(context)
        .size
        .width / 390);
  }

  Widget _buildMyChallengeTab() {
    if (_isLoadingMyChallenge) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_myChallengeDetail == null) {
      return const Center(child: Text('현재 참여중인 챌린지가 없습니다.'));
    }

    final detail = _myChallengeDetail!;

    int? myIdx;
    if (_currentUserId != null) {
      final idx = detail.participantsInfo.indexWhere((p) =>
      p.userId == _currentUserId);
      if (idx >= 0) myIdx = idx;
    }
    final String? myGuineaName = (myIdx != null) ? guineaNames[myIdx %
        guineaNames.length] : null;

    final bool isPositive = detail.challengeType == true;
    final bool isTeamComplete = detail.teamProgressRate >= 100;

    final String goalText = isPositive
        ? '긍정적 소비 ${detail.goalCount}개 하기'
        : '부정적 소비 ${detail.goalCount}개 이하로 하기';

    final String feedText = isPositive
        ? '${detail.guineaFeedCurrent}개 있어요'
        : '${detail.guineaFeedCurrent}개 남았어요';

    final double teamProgressValue =
        ((detail.teamProgressRate).clamp(0, 100) as num).toDouble() / 100.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(rWidth(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.name,
            style: TextStyle(
              fontSize: rFont(context, 26),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: rHeight(context, 12)),
          Text(
            _formatChallengePeriod(detail.endDate),
            style: TextStyle(
              fontSize: rFont(context, 14),
              color: Colors.grey,
            ),
          ),
          SizedBox(height: rHeight(context, 8)),
          Divider(height: rHeight(context, 4)),
          SizedBox(height: rHeight(context, 8)),

          // 참여자 수 + 기니피그 풀 상태
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, color: Colors.black87,
                            size: rWidth(context, 20)),
                        SizedBox(width: rWidth(context, 6)),
                        Text(
                          '참여자 수',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: rFont(context, 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rHeight(context, 4)),
                    Text(
                      '${detail.participantsInfo.length}명',
                      style: TextStyle(fontSize: rFont(context, 16)),
                    ),
                  ],
                ),
              ),
              SizedBox(width: rWidth(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.grass, color: Colors.black87,
                            size: rWidth(context, 20)),
                        SizedBox(width: rWidth(context, 6)),
                        Text(
                          '기니피그 풀 상태',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: rFont(context, 16),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rHeight(context, 4)),
                    Text(feedText,
                        style: TextStyle(fontSize: rFont(context, 16))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: rHeight(context, 16)),
          Row(
            children: [
              Icon(
                  Icons.flag, color: Colors.black87, size: rWidth(context, 20)),
              SizedBox(width: rWidth(context, 6)),
              Text(
                '개인별 목표',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rFont(context, 16),
                ),
              ),
            ],
          ),
          SizedBox(height: rHeight(context, 4)),
          Text(
            goalText,
            style: TextStyle(fontSize: rFont(context, 16)),
          ),
          SizedBox(height: rHeight(context, 16)),
          Row(
            children: [
              Icon(Icons.show_chart, color: Colors.black87,
                  size: rWidth(context, 20)),
              SizedBox(width: rWidth(context, 6)),
              Text(
                '팀 진행률',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rFont(context, 16),
                ),
              ),
            ],
          ),
          SizedBox(height: rHeight(context, 8)),
          Center(
            child: Image.asset(
              detail.teamProgressRate >= 100
                  ? 'lib/assets/complete_guinea.png'
                  : (detail.teamProgressRate >= 50
                  ? 'lib/assets/opened_guinea.png'
                  : 'lib/assets/closed_guinea.png'),
              width: rWidth(context, 220),
              height: rWidth(context, 220),
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: rHeight(context, 10)),
          Center(
            child: Text(
              isTeamComplete && isPositive
                  ? // 100% & 긍정 챌린지인 경우, 진행중 문구 없이 특별 메시지
              '모든 밥을 주는 데 성공했어요!\n기니피그가 행복해졌어요.'
                  : // 그 외는 기존 흐름: 진행률 + 상황 메시지
              '현재 ${detail.teamProgressRate.toStringAsFixed(1)}% 만큼 진행중이에요.\n'
                  '${isPositive
                  ? "기니피그가 밥을 기다리고 있어요!"
                  : "계속해서 기니피그의 밥을 지켜주세요!"}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: rFont(context, 14),
              ),
            ),
          ),
          SizedBox(height: rHeight(context, 16)),
          LayoutBuilder(
            builder: (context, constraints) {
              final parent = constraints.maxWidth;
              final target = parent * 0.9;
              final width = target.clamp(
                  rWidth(context, 180), rWidth(context, 420));
              return Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: width,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(rWidth(context, 8)),
                    child: LinearProgressIndicator(
                      value: teamProgressValue,
                      minHeight: rHeight(context, 8),
                      backgroundColor: Colors.grey[300],
                      color: detail.teamProgressRate >= 100
                          ? Colors.green
                          : Colors.lightGreen,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: rHeight(context, 16)),
          Divider(),
          SizedBox(height: rHeight(context, 10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '참여자 공헌도',
                style: TextStyle(
                  fontSize: rFont(context, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: rWidth(context, 8)),
              if (myGuineaName != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rWidth(context, 10),
                    vertical: rHeight(context, 6),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(rWidth(context, 14)),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: Text(
                    '내 기니피그: $myGuineaName',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        fontSize: rFont(context, 14)),
                  ),
                ),
            ],
          ),
          SizedBox(height: rHeight(context, 12)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: detail.participantsInfo
                .asMap()
                .entries
                .map((entry) {
              final index = entry.key;
              final p = entry.value;
              final nickname = guineaNames[index % guineaNames.length];
              final bool isMe = (_currentUserId != null &&
                  p.userId == _currentUserId);
              final double progressValue =
                  ((p.contributionRate).clamp(0, 100) as num).toDouble() /
                      100.0;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: rHeight(context, 8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: rWidth(context, 18),
                          backgroundImage: AssetImage(
                              _assetForGuineaName(nickname)),
                          backgroundColor: Colors.transparent,
                        ),
                        SizedBox(width: rWidth(context, 8)),
                        Expanded(
                          child: Text(
                            '• $nickname${isMe ? ' (나)' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: rFont(context, 14),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: rWidth(context, 8)),
                        Text(
                          '${p.contributionRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: p.isMost ? Colors.orange : Colors.black87,
                            fontWeight: p.isMost ? FontWeight.bold : FontWeight
                                .normal,
                            fontSize: rFont(context, 14),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: rHeight(context, 15)),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final parent = constraints.maxWidth;
                        final target = parent * 0.9;
                        final width = target.clamp(
                            rWidth(context, 180), rWidth(context, 420));
                        return Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: width,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  rWidth(context, 8)),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                minHeight: rHeight(context, 8),
                                backgroundColor: Colors.grey[300],
                                color: p.isMost ? Colors.orange : Colors
                                    .lightGreen,
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
      padding: EdgeInsets.all(rWidth(context, 8)),
      itemCount: _allChallenges.length,
      itemBuilder: (context, index) {
        final challenge = _allChallenges[index];
        final bgColor = challenge.challengeType ? Colors.yellow[100] : Colors
            .blue[100];

        return Card(
          color: bgColor,
          margin: EdgeInsets.symmetric(
            vertical: rHeight(context, 6),
            horizontal: rWidth(context, 8),
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
                  challenge.publicityType ? '공개 챌린지' : '비공개 챌린지',
                  style: TextStyle(fontSize: rFont(context, 12),
                      color: Colors.blueGrey[700]),
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
                '목표: ${challenge.goalCount}개, 참여자: ${challenge
                    .participantCount}명\n종료일: ${challenge.endDate
                    .toIso8601String()
                    .split('T')
                    .first}',
                style: TextStyle(fontSize: rFont(context, 14)),
              ),
            ),
            trailing: Icon(
              challenge.publicityType ? Icons.lock_open : Icons.lock,
              color: Colors.blueGrey[700],
              size: rWidth(context, 24),
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
      builder: (_) =>
          AlertDialog(
            title: Text(challenge.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: rHeight(context, 6)),
                  Text('챌린지 타입: ${challenge.challengeType
                      ? '기니피그 밥 주기(긍정 소비)'
                      : '기니피그 밥 지키기(부정 소비)'}'),
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
                  Text('종료일: ${challenge.endDate
                      .toIso8601String()
                      .split('T')
                      .first}'),
                  SizedBox(height: rHeight(context, 6)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('닫기')),
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
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.black38,
              indicatorColor: Colors.black87,
              tabs: [
                Tab(child: Text(
                    '내 챌린지', style: TextStyle(fontSize: rFont(context, 14)))),
                Tab(child: Text(
                    '전체 챌린지', style: TextStyle(fontSize: rFont(context, 14)))),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyChallengeTab(),
                _buildAllChallengesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _myChallengeDetail == null
          ? FloatingActionButton.extended(
        onPressed: _goToCreateChallenge,
        backgroundColor: Colors.black87,
        icon: Icon(Icons.add, size: rWidth(context, 20)),
        foregroundColor: Colors.white,
        label: Text(
          '챌린지 만들기',
          style: TextStyle(fontSize: rFont(context, 14)),
        ),
      )
          : null,
    );
  }
}
