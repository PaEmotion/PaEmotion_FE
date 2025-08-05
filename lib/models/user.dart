class User {
  final int id;
  final String email;
  final String name;
  final String nickname;
  final String accessToken;
  final String refreshToken;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    required this.accessToken,
    required this.refreshToken,
  });

  User copyWith({
    int? id,
    String? email,
    String? name,
    String? nickname,
    String? accessToken,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  factory User.fromJson(Map<String, dynamic> json, {String? accessToken, String? refreshToken}) {
    try {
      return User(
        id: json['userId'] is int
            ? json['userId'] as int
            : int.tryParse(json['userId']?.toString() ?? '') ?? 0,
        email: json['email']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        accessToken: accessToken ?? json['access_token']?.toString() ?? '',
        refreshToken: refreshToken ?? json['refresh_token']?.toString() ?? '',
      );
    } catch (e) {
      throw FormatException('Invalid User JSON: $e');
    }
  }

  Map<String, dynamic> toJson({bool includeTokens = false}) {
    final map = {
      'userId': id,
      'email': email,
      'name': name,
      'nickname': nickname,
    };
    if (includeTokens) {
      map['access_token'] = accessToken;
      map['refresh_token'] = refreshToken;
    }
    return map;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, nickname: $nickname)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.nickname == nickname &&
        other.accessToken == accessToken &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      nickname.hashCode ^
      accessToken.hashCode ^
      refreshToken.hashCode;
}
