class Application {
  final String id;
  final String jobId;
  final String? jobTitle;
  final double? jobPrice;
  final String workerId;
  final String? workerUsername;
  final double? workerRating;
  final int? workerTotalRatings;
  final String? coverLetter;
  final String status;
  final DateTime? createdAt;

  const Application({
    required this.id,
    required this.jobId,
    this.jobTitle,
    this.jobPrice,
    required this.workerId,
    this.workerUsername,
    this.workerRating,
    this.workerTotalRatings,
    this.coverLetter,
    required this.status,
    this.createdAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    // workerId peut être un UUID Java sérialisé sous différentes formes
    final rawWorkerId = json['workerId'];
    final workerId = rawWorkerId?.toString() ?? '';

    // createdAt peut être une liste [y,m,d,h,min,s,ns] (Jackson LocalDateTime)
    // ou une String ISO-8601
    DateTime? createdAt;
    final rawDate = json['createdAt'];
    if (rawDate is String) {
      createdAt = DateTime.tryParse(rawDate);
    } else if (rawDate is List && rawDate.length >= 6) {
      try {
        createdAt = DateTime(
          rawDate[0] as int,
          rawDate[1] as int,
          rawDate[2] as int,
          rawDate[3] as int,
          rawDate[4] as int,
          rawDate[5] as int,
        );
      } catch (_) {}
    }

    return Application(
      id: json['id']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      jobTitle: json['jobTitle'] as String?,
      jobPrice: (json['jobPrice'] as num?)?.toDouble(),
      workerId: workerId,
      workerUsername: json['workerUsername'] as String?,
      workerRating: (json['workerRating'] as num?)?.toDouble(),
      workerTotalRatings: json['workerTotalRatings'] as int?,
      coverLetter: json['coverLetter'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: createdAt,
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isRejected => status == 'REJECTED';
  bool get isCancelled => status == 'CANCELLED';

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'En attente';
      case 'ACCEPTED':
        return 'Acceptée';
      case 'REJECTED':
        return 'Refusée';
      case 'CANCELLED':
        return 'Annulée';
      default:
        return status;
    }
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 0) return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0) return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
    return "À l'instant";
  }
}
