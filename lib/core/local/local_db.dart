import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

final localDbProvider = Provider<LocalDb>((ref) {
  throw UnimplementedError('Override in ProviderScope after await');
});

class LocalDb {
  final Database _db;
  LocalDb._(this._db);

  static Future<LocalDb> open() async {
    final dbPath = await getDatabasesPath();
    final db = await openDatabase(
      '$dbPath/jobylo.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversationId TEXT NOT NULL,
            senderId TEXT NOT NULL,
            senderUsername TEXT NOT NULL,
            receiverId TEXT NOT NULL,
            receiverUsername TEXT,
            jobId TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER,
            isRead INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_conv ON messages(conversationId)',
        );
      },
    );
    return LocalDb._(db);
  }

  Database get db => _db;
}
