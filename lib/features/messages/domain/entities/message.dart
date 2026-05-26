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
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderUsername: json['senderUsername'] as String,
      receiverId: json['receiverId'] as String,
      receiverUsername: json['receiverUsername'] as String?,
      jobId: json['jobId'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get formattedTime {
    if (timestamp == null) return '';
    return '${timestamp!.hour}:${timestamp!.minute.toString().padLeft(2, '0')}';
  }
}
