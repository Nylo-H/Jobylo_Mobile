class Conversation {
  final String conversationId;
  final String jobId;
  final String jobTitle;
  final String otherUserId;
  final String otherUserUsername;
  final String? lastMessage;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;

  const Conversation({
    required this.conversationId,
    required this.jobId,
    required this.jobTitle,
    required this.otherUserId,
    required this.otherUserUsername,
    this.lastMessage,
    this.lastMessageTimestamp,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String? ?? '',
      otherUserId: json['otherUserId'] as String,
      otherUserUsername: json['otherUserUsername'] as String,
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: json['lastMessageTimestamp'] != null
          ? DateTime.parse(json['lastMessageTimestamp'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  String get formattedTime {
    if (lastMessageTimestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastMessageTimestamp!);
    if (diff.inDays > 7) {
      return "${lastMessageTimestamp!.day}/${lastMessageTimestamp!.month.toString().padLeft(2, '0')}";
    }
    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'Hier';
      return _dayName(lastMessageTimestamp!.weekday);
    }
    return "${lastMessageTimestamp!.hour}:${lastMessageTimestamp!.minute.toString().padLeft(2, '0')}";
  }

  String _dayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[weekday - 1];
  }
}
