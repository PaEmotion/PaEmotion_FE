class RecordApi {
  static const String create = '/records/create';
  static const String list = '/records/me';
  static String detail(int spendId) => '/records/me/$spendId';
  static String update(int spendId) => '/records/me/$spendId';
  static String delete(int spendId) => '/records/me/$spendId';
}