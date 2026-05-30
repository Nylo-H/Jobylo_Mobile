class Payment {
  final String id;
  final String jobId;
  final String? jobTitle;
  final String buyerId;
  final String? buyerUsername;
  final String sellerId;
  final String? sellerUsername;
  final double amount;
  final double commissionPercentage;
  final double commissionAmount;
  final double netAmount;
  final String status; // HELD | COMPLETED | CANCELLED
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.jobId,
    this.jobTitle,
    required this.buyerId,
    this.buyerUsername,
    required this.sellerId,
    this.sellerUsername,
    required this.amount,
    required this.commissionPercentage,
    required this.commissionAmount,
    required this.netAmount,
    required this.status,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id']?.toString() ?? '',
        jobId: json['jobId']?.toString() ?? '',
        jobTitle: json['jobTitle'] as String?,
        buyerId: json['buyerId']?.toString() ?? '',
        buyerUsername: json['buyerUsername'] as String?,
        sellerId: json['sellerId']?.toString() ?? '',
        sellerUsername: json['sellerUsername'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        commissionPercentage:
            (json['commissionPercentage'] as num?)?.toDouble() ?? 0,
        commissionAmount:
            (json['commissionAmount'] as num?)?.toDouble() ?? 0,
        netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'HELD',
        paymentMethod: json['paymentMethod'] as String?,
        createdAt: _parseDate(json['createdAt']),
        updatedAt: _parseDate(json['updatedAt']),
      );

  bool get isHeld => status == 'HELD';
  bool get isCompleted => status == 'COMPLETED';

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
