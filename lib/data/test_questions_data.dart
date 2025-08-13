import '../models/test_question_model.dart';

final List<Question> testQuestions = [
  Question(
    questionText: '월급 or 알바비 들어오면 제일 먼저 하는 생각은?',
    choices: [
      Choice(text: '무조건 Flex! 뭐라도 질러야 기분 나지', traitKey: 'flashy'),
      Choice(text: '오늘은 비싼 커피 마셔야겠다 ㅎㅎ', traitKey: 'coffee'),
      Choice(text: '계좌 나눠서 저축부터 하자!', traitKey: 'planner'),
      Choice(text: '이번엔 덕질 굿즈 사야지~', traitKey: 'hobby'),
      Choice(text: '그냥 그대로 둬야지... 필요 없으면 안 사.', traitKey: 'minimal'),
      Choice(text: '친구들한테 놀자고 해야겠다!', traitKey: 'social'),
    ],
  ),
  Question(
    questionText: '핫딜을 봤을 때 넌?',
    choices: [
      Choice(text: '이건 사야 해!', traitKey: 'impulse'),
      Choice(text: '담아놓고 일단 고민하자...', traitKey: 'minimal'),
      Choice(text: '내 리스트에 있던 거니까 바로 사야겠다~', traitKey: 'planner'),
      Choice(text: '내가 덕질하는 분야면 무조건 찜해둠!', traitKey: 'hobby'),
      Choice(text: '이건 플렉스용이다. 질러!!!', traitKey: 'flashy'),
      Choice(text: '스트레스 받을 때 핫딜 보면 바로 클릭', traitKey: 'emotional'),
    ],
  ),
  Question(
    questionText: '카페 소비에 대한 너의 생각은?',
    choices: [
      Choice(text: '커피 하루 한 잔은 필수지. 낭비가 아니라 투자임', traitKey: 'coffee'),
      Choice(text: '친구 만나면 자연스럽게 가는 곳', traitKey: 'social'),
      Choice(text: '구독 or 멤버십으로 알뜰하게 할인받음', traitKey: 'planner'),
      Choice(text: '커피는 집에서 내려먹어야 제 맛', traitKey: 'minimal'),
      Choice(text: '기분 안 좋을 땐 무조건 음료 하나 사 마심', traitKey: 'emotional'),
      Choice(text: '신메뉴 나오면 한번씩 또 가줘야지~', traitKey: 'impulse'),
    ],
  ),
  Question(
    questionText: '취미에 돈 쓰는 스타일은?',
    choices: [
      Choice(text: '입덕하면 끝장 봄. 장비부터 산다', traitKey: 'hobby'),
      Choice(text: '카페 가는 게 취미임. 분위기 좋은 곳이면 더 좋음.', traitKey: 'coffee'),
      Choice(text: '취미에는 되도록 돈을 쓰고싶지 않음', traitKey: 'minimal'),
      Choice(text: '스트레스 받으면 그냥 사버림', traitKey: 'emotional'),
      Choice(text: '한정판이면 무조건 달린다', traitKey: 'impulse'),
      Choice(text: '눈 돌아가서 보이는대로 마구 샀다가 후회한적 많음…', traitKey: 'flashy'),
    ],
  ),
  Question(
    questionText: '쇼핑몰 장바구니 관리법은?',
    choices: [
      Choice(text: '장바구니 담자마자 바로 결제함', traitKey: 'impulse'),
      Choice(text: '약속 생기면 그날 입을 옷부터 장바구니에 넣음', traitKey: 'social'),
      Choice(text: '여러 사이트 비교하고 최저가에 삼', traitKey: 'planner'),
      Choice(text: '장바구니 채우는 게 행복임', traitKey: 'flashy'),
      Choice(text: '기분 나쁠 때 지름신 내림 받고 결제 누름', traitKey: 'emotional'),
      Choice(text: '덕질템은 장바구니 거치지 않고 바로 결제함', traitKey: 'hobby'),
    ],
  ),
  Question(
    questionText: '너의 소비 철학은?',
    choices: [
      Choice(text: '안 쓰면 돈이 아님', traitKey: 'flashy'),
      Choice(text: '힐링엔 돈이 들어간다', traitKey: 'emotional'),
      Choice(text: '아껴야 잘 산다', traitKey: 'minimal'),
      Choice(text: '돈도 전략이다', traitKey: 'planner'),
      Choice(text: '즐길 수 있을 때 즐겨야지', traitKey: 'social'),
      Choice(text: '살기 위해서는 쓸 수 밖에 없음', traitKey: 'coffee'),
    ],
  ),
  Question(
    questionText: '친구가 너한테 선물 사준대! 뭘 받고 싶어?',
    choices: [
      Choice(text: '분위기 좋은 카페 기프티콘', traitKey: 'coffee'),
      Choice(text: '굿즈나 키링, 피규어 같은 소장템', traitKey: 'hobby'),
      Choice(text: '캔들이나 디퓨저같은 힐링템', traitKey: 'emotional'),
      Choice(text: '요즘 유행하는 예쁜 감성 디카', traitKey: 'social'),
      Choice(text: '그냥 돈으로 주면 좋겠다…', traitKey: 'planner'),
      Choice(text: '평소 안 사봤던 신선한 거!', traitKey: 'impulse'),
    ],
  ),
  Question(
    questionText: '소비 기록은 어떻게 남기고 있어?',
    choices: [
      Choice(text: '엑셀 가계부 + 카테고리 정리 완벽', traitKey: 'planner'),
      Choice(text: '메모장에 대충 써둠', traitKey: 'emotional'),
      Choice(text: '그냥 통장 내역 보면 됨', traitKey: 'minimal'),
      Choice(text: '리뷰나 SNS에 자랑 겸 기록함', traitKey: 'flashy'),
      Choice(text: '딱히 쓸 필요를 못 느껴서 안 남김', traitKey: 'impulse'),
      Choice(text: '1/N 결제를 많이 해서 기록 남기기가 복잡함…', traitKey: 'social'),
    ],
  ),
  Question(
    questionText: '플렉스 해본 경험 중 최고는?',
    choices: [
      Choice(text: '명품템! 어깨 펴짐', traitKey: 'flashy'),
      Choice(text: '핫플 카페에서 시그니처 싹 다 주문', traitKey: 'coffee'),
      Choice(text: '친구들이랑 고급 술집에서 털어버림', traitKey: 'social'),
      Choice(text: '콘서트 or 굿즈 풀패키지 결제', traitKey: 'hobby'),
      Choice(text: '그런 경험 없음. 플렉스 안 함', traitKey: 'minimal'),
      Choice(text: '리미티드 에디션 떠서 바로 질러버림', traitKey: 'impulse'),
    ],
  ),
  Question(
    questionText: '지금 가장 사고 싶은 건 뭐야?',
    choices: [
      Choice(text: '새로 나온 한정판 굿즈', traitKey: 'hobby'),
      Choice(text: '요즘 유행하는 예쁜 텀블러', traitKey: 'coffee'),
      Choice(text: '이번 주말 친구들 모임에서 빛날 옷', traitKey: 'social'),
      Choice(text: '예쁜 악세서리 or 명품템 하나쯤', traitKey: 'flashy'),
      Choice(text: '사고 싶은 건 많지만… 참는다.', traitKey: 'minimal'),
      Choice(text: '필요는 없는데 예쁘고 저렴한게 눈에 보이면 산다', traitKey: 'impulse'),
    ],
  ),
];