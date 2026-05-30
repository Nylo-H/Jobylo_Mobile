class Rating {
  final String id;
  final String jobId;
  final String? jobTitle;
  final String raterId;
  final String? raterUsername;
  final String targetId;
  final String? targetUsername;
  final String? targetType; // WORKER | CREATOR
  final int score;
  final String? comment;
  final DateTime? createdAt;

  const Rating({
    required this.id,
    required this.jobId,
    this.jobTitle,
    required this.raterId,
    this.raterUsername,
    required this.targetId,
    this.targetUsername,
    this.targetType,
    required this.score,
    this.comment,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id']?.toString() ?? '',
        jobId: json['jobId']?.toString() ?? '',
        jobTitle: json['jobTitle'] as String?,
        raterId: json['raterId']?.toString() ?? '',
        raterUsername: json['raterUsername'] as String?,
        targetId: json['targetId']?.toString() ?? '',
        targetUsername: json['targetUsername'] as String?,
        targetType: json['targetType'] as String?,
        score: (json['score'] as num?)?.toInt() ?? 0,
        comment: json['comment'] as String?,
        createdAt: _parseDate(json['createdAt']),
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is List && raw.length >= 6) {
      try {
        return DateTime(raw[0] as int, raw[1] as int, raw[2] as int,
            raw[3] as int, raw[4] as int, raw[5] as int);
      } catch (_) {}
    }
    return null;
  }
}
