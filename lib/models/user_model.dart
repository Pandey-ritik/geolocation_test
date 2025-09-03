class UserModel {
  final int userId;
  final String email;
  final String token;

  UserModel({
    required this.userId,
    required this.email,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? json['id'] ?? 0,
      email: json['email'] ?? '',
      token: json['token'] ?? json['access_token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'token': token,
    };
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, token: ${token.isNotEmpty ? '***' : 'empty'})';
  }
}