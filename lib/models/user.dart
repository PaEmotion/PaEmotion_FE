class User {
  final String id;
  final String email;
  final String name;
  final String nickname;
  final String accessToken;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    required this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'],
      email: json['email'],
      name: json['name'],
      nickname: json['nickname'],
      accessToken: json['access_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'email': email,
      'name': name,
      'nickname': nickname,
      'access_token': accessToken,
    };
  }
}
