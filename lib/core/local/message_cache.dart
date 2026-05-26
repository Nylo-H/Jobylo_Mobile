import 'package:sqflite/sqflite.dart';
import '../../features/messages/domain/entities/message.dart';
import 'local_db.dart';

class MessageCache {
  final LocalDb _db;

  MessageCache(this._db);

  /// All cached messages for [conversationId], ordered chronologically.
  Future<List<Message>> getMessages(String conversationId) async {
    final rows = await _db.db.query(
      'messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(_toEntity).toList();
  }

  /// IDs already in cache — used to diff and only fetch the delta.
  Future<Set<String>> getStoredIds(String conversationId) async {
    final rows = await _db.db.query(
      'messages',
      columns: ['id'],
      where: 'conversationId = ?',
      whereArgs: [conversationId],
    );
    return {for (final r in rows) r['id'] as String};
  }

  /// Upsert a list of messages (full server response on first load).
  Future<void> saveMessages(List<Message> messages) async {
    final batch = _db.db.batch();
    for (final m in messages) {
      batch.insert(
        'messages',
        _toRow(m),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Insert / update a single message (from WS or REST send).
  Future<void> saveMessage(Message message) async {
    await _db.db.insert(
      'messages',
      _toRow(message),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Mapping ─────────────────────────────────────────────────────────────

  Map<String, dynamic> _toRow(Message m) => {
        'id': m.id,
        'conversationId': m.conversationId,
        'senderId': m.senderId,
        'senderUsername': m.senderUsername,
        'receiverId': m.receiverId,
        'receiverUsername': m.receiverUsername,
        'jobId': m.jobId,
        'content': m.content,
        'timestamp': m.timestamp?.millisecondsSinceEpoch,
        'isRead': m.isRead ? 1 : 0,
      };

  Message _toEntity(Map<String, dynamic> row) => Message(
        id: row['id'] as String,
        conversationId: row['conversationId'] as String,
        senderId: row['senderId'] as String,
        senderUsername: row['senderUsername'] as String,
        receiverId: row['receiverId'] as String,
        receiverUsername: row['receiverUsername'] as String?,
        jobId: row['jobId'] as String,
        content: row['content'] as String,
        timestamp: row['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int)
            : null,
        isRead: (row['isRead'] as int) == 1,
      );
}
