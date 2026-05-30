class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderUsername;
  final String receiverId;
  final String? receiverUsername;
  final String jobId;
  final String content;
  final DateTime? timestamp;
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderUsername,
    required this.receiverId,
    this.receiverUsername,
    required this.jobId,
    required this.content,
    this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversationId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderUsername: json['senderUsername'] as String? ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      receiverUsername: json['receiverUsername'] as String?,
      jobId: json['jobId']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      timestamp: _parseDate(json['timestamp']),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

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

  String get formattedTime {
    if (timestamp == null) return '';
    return '${timestamp!.hour}:${timestamp!.minute.toString().padLeft(2, '0')}';
  }
}
