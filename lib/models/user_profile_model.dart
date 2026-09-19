class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String defaultCurrency;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.defaultCurrency,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      defaultCurrency: json['defaultCurrency'] ?? 'USD',
    );
  }
}