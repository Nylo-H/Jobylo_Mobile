import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../datasource/messages_remote_datasource.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository(MessagesRemoteDatasource(ref.read(dioProvider)));
});

class PagedMessages {
  final List<Message> messages;
  final bool isLast;
  final int page;
  const PagedMessages(
      {required this.messages, required this.isLast, required this.page});
}

class MessagesRepository {
  final MessagesRemoteDatasource _datasource;
  MessagesRepository(this._datasource);

  Future<List<Conversation>> getConversations() async {
    final data = await _datasource.getConversations();
    return data.map(Conversation.fromJson).toList();
  }

  Future<PagedMessages> getMessages(
    String conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    final raw =
        await _datasource.getMessagesPaged(conversationId, page: page, size: size);
    final content = (raw['content'] as List).cast<Map<String, dynamic>>();
    return PagedMessages(
      messages: content.map(Message.fromJson).toList(),
      isLast: raw['last'] as bool? ?? true,
      page: raw['number'] as int? ?? page,
    );
  }

  Future<Message> startConversation({
    required String jobId,
    required String content,
  }) async {
    final data = await _datasource.startConversation(
        jobId: jobId, content: content);
    return Message.fromJson(data);
  }

  Future<Message> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final data = await _datasource.sendMessage(
        conversationId: conversationId, content: content);
    return Message.fromJson(data);
  }

  Future<int> getUnreadCount() => _datasource.getUnreadCount();

  Future<void> markConversationRead(String conversationId) =>
      _datasource.markConversationRead(conversationId);
}
