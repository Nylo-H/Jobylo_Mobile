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
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      creatorId: json['creatorId'] as String? ?? '',
      creatorUsername: json['creatorUsername'] as String? ?? '',
      workerId: json['workerId'] as String?,
      workerUsername: json['workerUsername'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      categoryId: json['categoryId'] as String?,
      categoryName: json['categoryName'] as String?,
    );
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
