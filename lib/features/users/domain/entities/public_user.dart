class PublicUser {
  final String id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? photoProfile;
  final double? averageRating;
  final int? totalRatings;
  final String? kycStatus;

  const PublicUser({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.photoProfile,
    this.averageRating,
    this.totalRatings,
    this.kycStatus,
  });

  factory PublicUser.fromJson(Map<String, dynamic> json) => PublicUser(
        id: json['id']?.toString() ?? '',
        username: json['username'] as String? ?? '',
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
        photoProfile:
            json['photoProfile'] as String? ?? json['photoProfil'] as String?,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        totalRatings: (json['totalRatings'] as num?)?.toInt(),
        kycStatus: json['kycStatus'] as String?,
      );

  String get displayName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    return username;
  }

  bool get isKycVerified => kycStatus == 'VERIFIED';
}
