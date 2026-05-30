import '../../../../core/constants/api_constants.dart';

class Job {
  final String id;
  final String title;
  final String? description;
  final String location;
  final double price;
  final String creatorId;
  final String creatorUsername;
  final String? workerId;
  final String? workerUsername;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final String? categoryId;
  final String? categoryName;

  const Job({
    required this.id,
    required this.title,
    this.description,
    required this.location,
    required this.price,
    required this.creatorId,
    required this.creatorUsername,
    this.workerId,
    this.workerUsername,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.images,
    this.categoryId,
    this.categoryName,
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
      workerId: json['workerId']?.toString(),
      workerUsername: json['workerUsername'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName'] as String?,
    );
  }

  /// Handles both ISO-8601 String and Jackson LocalDateTime array [y,m,d,h,min,s,ns]
  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return DateTime.tryParse(raw);
    if (raw is List && raw.length >= 6) {
      try {
        return DateTime(
          raw[0] as int, raw[1] as int, raw[2] as int,
          raw[3] as int, raw[4] as int, raw[5] as int,
        );
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
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays > 7) return "${createdAt.day}/${createdAt.month}";
    if (diff.inDays > 0) return "Il y a ${diff.inDays}j";
    if (diff.inHours > 0) return "Il y a ${diff.inHours}h";
    if (diff.inMinutes > 0) return "Il y a ${diff.inMinutes}min";
    return "À l'instant";
  }

  bool get isPending => status == 'PENDING';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isDone => status == 'DONE';
}
