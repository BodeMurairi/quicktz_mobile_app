class AuthTokens {
  final String accessToken;
  final String refreshToken;

  AuthTokens({required this.accessToken, required this.refreshToken});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'],
        refreshToken: json['refresh_token'],
      );
}

class UserModel {
  final String id;
  final String? email;
  final String? phoneNumber;
  final String fullName;
  final bool isPremium;
  final bool isActive;
  final bool isVerified;

  UserModel({
    required this.id,
    this.email,
    this.phoneNumber,
    required this.fullName,
    required this.isPremium,
    required this.isActive,
    required this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        phoneNumber: json['phone_number'],
        fullName: json['full_name'],
        isPremium: json['is_premium'] ?? false,
        isActive: json['is_active'] ?? true,
        isVerified: json['is_verified'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone_number': phoneNumber,
        'full_name': fullName,
        'is_premium': isPremium,
        'is_active': isActive,
        'is_verified': isVerified,
      };
}
