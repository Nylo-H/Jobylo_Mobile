class User {
  final String id;
  final String? firstName;
  final String? lastName;
  final String username;
  final String email;
  final String? photoProfile;
  final String role;
  final bool verified;
  final String? kycStatus;
  final double? averageRating;
  final int? totalRatings;

  const User({
    required this.id,
    this.firstName,
    this.lastName,
    required this.username,
    required this.email,
    this.photoProfile,
    required this.role,
    required this.verified,
    this.kycStatus,
    this.averageRating,
    this.totalRatings,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      photoProfile: json['photoProfile'] as String? ?? json['photoProfil'] as String?,
      role: json['role'] as String? ?? 'USER',
      verified: json['verified'] as bool? ?? false,
      kycStatus: json['kycStatus'] as String?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalRatings: json['totalRatings'] as int?,
    );
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  bool get isKycVerified => kycStatus == 'VERIFIED';
}
