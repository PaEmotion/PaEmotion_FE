class TraitInfo {
  final String key;
  final String title;
  final String description;
  final String summary;
  final String imagePath;

  TraitInfo({
    required this.key,
    required this.title,
    required this.description,
    required this.summary,
    required this.imagePath,
  });
}

final List<TraitInfo> traitInfos = [
  TraitInfo(
    key: 'coffee',
    title: '☕ 카페인 중독형',
    description: '''
“하루 한 잔은 기본, 커피값은 고정지출!”

당신은 커피 없는 하루는 상상도 안 되는 카페 러버!

당신에게 카페는 단순한 가게가 아니라 작업실, 휴식처, 심지어 힐링 공간입니다.

아침 루틴도 “카페 들르기”로 시작하고,

친구 만남이나 데이트도 무조건 분위기 있는 카페로 픽!

- ✔️ 카페 구독 서비스 200% 활용 중
- ✔️ 원두, 텀블러, 드립세트까지 보유
- ✔️ 소비 리스트에 ‘커피값’은 필수 고정지출
''',
    summary: '“내 인생의 진정한 연료는 카페인이다.”',
    imagePath: 'lib/assets/t_coffee.jpg',
  ),
  TraitInfo(
    key: 'flashy',
    title: '🛍️ 탕진잼형',
    description: '''
“월급날이면 일단 Flex!”

당신은 돈 쓸 때 제일 빛나는 스타일.

월급은 통장을 스치고, 내 손은 결제를 누르지!

플렉스에 죄책감은 없고, 오히려 탕진이 곧 힐링인 사람.

한 달에 한 번쯤은 “오늘만 산다” 마인드로 제대로 터트리는 타입.

- ✔️ 월급날이면 무조건 쇼핑 or 맛집 예약
- ✔️ 장바구니 텅 비는 날 = 행복한 날
- ✔️ ‘다음 달 카드값’은 일단 다음 달 일
''',
    summary: '“사치도 추억이다. 지금 아니면 언제 질러?”',
    imagePath: 'lib/assets/t_flashy.jpg',
  ),
  TraitInfo(
    key: 'emotional',
    title: '😭 감정해소형',
    description: '''
“기분 안 좋을 땐 쇼핑이지 뭐.”

당신은 감정이 지갑을 움직이는 타입.

스트레스를 받거나 우울하면 무의식적으로 결제 버튼을 누르곤 합니다.

그게 옷이든, 음식이든, 아무거나 사야 마음이 좀 놓이죠.

감정 해소용 소비지만, 후회할 때도 많은 스타일.

- ✔️ 배달 앱 켜는 타이밍 = 기분 안 좋을 때
- ✔️ “살까 말까 할 땐 산다” 경험 많음
- ✔️ 월말엔 “나 왜 이걸 샀더라…” 하고 후회
''',
    summary: '“소비는 나의 감정치료제.”',
    imagePath: 'lib/assets/t_emotional.jpg',
  ),
  TraitInfo(
    key: 'impulse',
    title: '📦 충동구매왕',
    description: '''
“할인? 한정판? 안 살 수 없지!”

당신은 지름신이 강림하면 아무도 못 말리는 스타일.

계획? 예산? 그딴 거 없다.

세일, 타임딜, ‘품절 임박’이라는 말에 광클릭 발동!

그때는 너무 사고 싶었는데…

다음 달 카드 고지서를 보며 뒤늦게 정신 차리는 경우도 많지요.

- ✔️ “또 뭐 시켰더라…” 택배 까고 놀람
- ✔️ 앱 알림에 약함. 특히 ‘~% 할인’
- ✔️ 갖고 있는 물건 중 절반은 안 씀
''',
    summary: '“계획 없는 소비가 제일 짜릿해!”',
    imagePath: 'lib/assets/t_impulse.jpg',
  ),
  TraitInfo(
    key: 'hobby',
    title: '🎨 취미몰빵형',
    description: '''
“요즘엔 이것밖에 안 보여요.”

당신은 뭔가에 꽂히면 한없이 깊게 파는 타입.

관심 생긴 순간부터 지출은 정해진 운명.

입문템, 장비, 관련 굿즈까지 몰빵하며,

하나에 올인하는 대신 다른 건 전혀 안 쓰죠.

덕질, 게임, 그림, 운동 등 열정에 돈 쓰는 걸 아끼지 않아요.

- ✔️ “요즘엔 이게 내 전부야”란 말 자주 함
- ✔️ 장비빨 중요하게 여김
- ✔️ 덕질 컨텐츠+굿즈는 무조건 쟁여두는 편
''',
    summary: '“진심을 담은 취미엔 돈도 따라간다.”',
    imagePath: 'lib/assets/t_hobby.jpg',
  ),
  TraitInfo(
    key: 'planner',
    title: '📅 계획형 소비자',
    description: '''
“월간 지출표+예산표는 필수!”

당신은 소비에도 계획이 있는 진성 플래너형.

“돈은 전략적으로 써야 한다”가 철칙이고,

지출과 수입을 가계부나 앱으로 꼼꼼히 관리하죠.

계획한 예산 넘는 소비는 거의 없고,

무지출 챌린지, 할인 비교까지 똑부러지게 실천하는 편.

- ✔️ 엑셀, 앱 가계부 2개 이상 돌리는 사람
- ✔️ 장바구니 담기 전에 가격 비교는 기본
- ✔️ “이번 달 고정지출이 얼마였더라” 읊을 수 있음
''',
    summary: '“소비에도 전략이 필요하다.”',
    imagePath: 'lib/assets/t_planner.jpg',
  ),
  TraitInfo(
    key: 'social',
    title: '🎉 인싸플렉스형',
    description: '''
“사람들과 있는 자리에선 아낌없이 쓴다!”

당신은 사람 만나는 걸 좋아하고,

소비도 나 혼자보단 함께일 때 즐거운 타입.

모임, 술자리, 여행, 핫플 탐방 같은

“함께하는 경험”에 돈 쓰는 걸 아끼지 않죠.

분위기 살리고, 친구들 챙기고, 인싸력으로 소비도 FLEX하게!

- ✔️ 모임비 계산 자주 함
- ✔️ 맛집 탐방 좋아함
- ✔️ “사진 찍기 좋은 곳” 체크 필수
''',
    summary: '“추억이 남는 소비, 그게 진짜 플렉스.”',
    imagePath: 'lib/assets/t_social.jpg',
  ),
  TraitInfo(
    key: 'minimal',
    title: '🧘 무소비 미니멀리스트',
    description: '''
“사고 싶은 건 많은데… 참는 것도 내 능력.”

당신은 소비를 잘 참고, 잘 거르는 절제력 만렙 소비자.

필요한 것만 사고, 쓸데없는 건 거침없이 넘겨요.

한 번 살 때도 리뷰 + 가격비교 + 실용성 검증까지 하고,

결국 안 사는 선택을 자주 하죠.

미니멀하면서 똑똑한 소비, 당신에겐 이미 습관입니다.

- ✔️ 중고 거래 자주 활용함
- ✔️ 택배 안 오는 주간도 거뜬
- ✔️ 소비 = 기능 중심, 심플한 게 최고
''',
    summary: '“사는 것보다 안 사는 게 더 어렵다는 걸 아는 사람.”',
    imagePath: 'lib/assets/t_minimal.jpg',
  ),
];