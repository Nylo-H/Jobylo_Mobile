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
      conversationId: json['conversationId']?.toString() ?? '',
      jobId: json['jobId']?.toString() ?? '',
      jobTitle: json['jobTitle'] as String? ?? '',
      otherUserId: json['otherUserId']?.toString() ?? '',
      otherUserUsername: json['otherUserUsername'] as String? ?? '',
      lastMessage: json['lastMessage'] as String?,
      lastMessageTimestamp: _parseDate(json['lastMessageTimestamp']),
      unreadCount: json['unreadCount'] as int? ?? 0,
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
