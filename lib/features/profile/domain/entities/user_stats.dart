class UserStats {
  final int totalJobsCreated;
  final int totalJobsInProgress;
  final int totalJobsCompleted;
  final double? averageRating;
  final int totalRatings;
  final int totalApplicationsReceived;
  final int totalApplicationsSent;

  const UserStats({
    required this.totalJobsCreated,
    required this.totalJobsInProgress,
    required this.totalJobsCompleted,
    this.averageRating,
    required this.totalRatings,
    required this.totalApplicationsReceived,
    required this.totalApplicationsSent,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        totalJobsCreated: json['totalJobsCreated'] as int? ?? 0,
        totalJobsInProgress: json['totalJobsInProgress'] as int? ?? 0,
        totalJobsCompleted: json['totalJobsCompleted'] as int? ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        totalRatings: json['totalRatings'] as int? ?? 0,
        totalApplicationsReceived:
            json['totalApplicationsReceived'] as int? ?? 0,
        totalApplicationsSent: json['totalApplicationsSent'] as int? ?? 0,
      );

  factory UserStats.empty() => const UserStats(
        totalJobsCreated: 0,
        totalJobsInProgress: 0,
        totalJobsCompleted: 0,
        totalRatings: 0,
        totalApplicationsReceived: 0,
        totalApplicationsSent: 0,
      );
}
