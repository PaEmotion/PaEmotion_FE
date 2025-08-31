class ChallengeApi {
  static const String create = '/challenges/create';
  static const String join = '/challenges/join';
  static const String current = '/challenges/current';
  static const String search = '/challenges/search';
  static const String list = '/challenges';
  static String detail(int challengeId) => '/challenges/$challengeId';
  static String fullDetail(int challengeId) => '/challenges/detail/$challengeId';
}