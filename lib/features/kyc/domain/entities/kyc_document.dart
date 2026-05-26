class KycDocument {
  final String id;
  final String userId;
  final String fileUrl;
  final String documentType;
  final String status;
  final String? rejectionReason;
  final DateTime? submittedAt;

  const KycDocument({
    required this.id,
    required this.userId,
    required this.fileUrl,
    required this.documentType,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) => KycDocument(
        id: json['id'] as String,
        userId: json['userId'] as String,
        fileUrl: json['fileUrl'] as String,
        documentType: json['documentType'] as String,
        status: json['status'] as String,
        rejectionReason: json['rejectionReason'] as String?,
        submittedAt: json['submittedAt'] != null
            ? DateTime.parse(json['submittedAt'] as String)
            : null,
      );

  bool get isPending => status == 'PENDING';
  bool get isVerified => status == 'VERIFIED';
  bool get isRejected => status == 'REJECTED';
}
