class AuthResponse {
  final String token;
  final String userId;
  final String fullName;
  final String email;

  AuthResponse({
    required this.token,
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      userId: json['userId'],
      fullName: json['fullName'],
      email: json['email'],
    );
  }
}