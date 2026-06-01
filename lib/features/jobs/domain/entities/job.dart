import '../../../../core/constants/api_constants.dart';

class Job {
  final String id;
  final String title;
  final String? description;
  final String location;
  final double price;
  final String creatorId;
  final String creatorUsername;
  final String? creatorPhotoUrl;
  final double? creatorRating;
  final int? creatorTotalRatings;
  final String? workerId;
  final String? workerUsername;
  final double? workerRating;
  final int? workerTotalRatings;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;
  final DateTime? applicationDeadline;

  const Job({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.price,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorPhotoUrl,
    this.creatorRating,
    this.creatorTotalRatings,
    this.workerId,
    this.workerUsername,
    this.workerRating,
    this.workerTotalRatings,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.images,
    this.categoryId,
    this.categoryName,
    this.applicationDeadline,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      creatorId: json['creatorId']?.toString() ?? '',
      creatorUsername: json['creatorUsername'] as String? ?? '',
      creatorPhotoUrl: json['creatorPhotoUrl'] as String? ??
          json['creatorPhotoProfil'] as String?,
      creatorRating: (json['creatorRating'] as num?)?.toDouble(),
      creatorTotalRatings: (json['creatorTotalRatings'] as num?)?.toInt(),
      workerId: json['workerId']?.toString(),
      workerUsername: json['workerUsername'] as String?,
      workerRating: (json['workerRating'] as num?)?.toDouble(),
      workerTotalRatings: (json['workerTotalRatings'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
      applicationDeadline: _parseDate(json['applicationDeadline']),
    );
  }

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

  String get fullImageUrl {
    if (images.isEmpty) return '';
    final path = images.first;
    if (path.startsWith('http')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 7) return '${createdAt.day}/${createdAt.month}';
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
    return "À l'instant";
  }

  bool get isPending => status == 'PENDING';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isDone => status == 'DONE';
  bool get isExpired => status == 'EXPIRED';

  bool get isDeadlinePassed =>
      applicationDeadline != null &&
      applicationDeadline!.isBefore(DateTime.now());

  bool get canApply => isPending && !isDeadlinePassed;

  String get deadlineCountdown {
    if (applicationDeadline == null) return '';
    final remaining = applicationDeadline!.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirée';
    if (remaining.inDays > 0) {
      return '${remaining.inDays}j ${remaining.inHours % 24}h restantes';
    }
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}min restantes';
    }
    return '${remaining.inMinutes}min restantes';
  }
}
