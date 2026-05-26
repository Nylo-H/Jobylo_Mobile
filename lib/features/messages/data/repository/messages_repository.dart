import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../datasource/messages_remote_datasource.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  final dio = ref.read(dioProvider);
  return MessagesRepository(MessagesRemoteDatasource(dio));
});

class MessagesRepository {
  final MessagesRemoteDatasource _datasource;

  MessagesRepository(this._datasource);

  Future<List<Conversation>> getConversations() async {
    final data = await _datasource.getConversations();
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final data = await _datasource.getMessages(conversationId);
    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> startConversation({
    required String jobId,
    required String content,
  }) async {
    final data = await _datasource.startConversation(
      jobId: jobId,
      content: content,
    );
    return Message.fromJson(data);
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final data = await _datasource.sendMessage(
      conversationId: conversationId,
      content: content,
    );
    return Message.fromJson(data);
  }

  Future<int> getUnreadCount() => _datasource.getUnreadCount();

  Future<void> markAsRead(String messageId) => _datasource.markAsRead(messageId);
}
