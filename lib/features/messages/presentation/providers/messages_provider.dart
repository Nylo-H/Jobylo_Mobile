import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/message_cache.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/repository/messages_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

// ── Conversations list ────────────────────────────────────────────────────
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final list =
        await ref.read(messagesRepositoryProvider).getConversations();

    ref.listen(webSocketServiceProvider, (_, ws) {
      ws.conversationUpdateStream.listen((updatedConv) {
        final current = state.valueOrNull ?? [];
        final idx = current
            .indexWhere((c) => c.conversationId == updatedConv.conversationId);
        final updated = List<Conversation>.from(current);
        if (idx >= 0) {
          updated[idx] = updatedConv;
        } else {
          updated.insert(0, updatedConv);
        }
        updated.sort((a, b) {
          final at = a.lastMessageTimestamp ?? DateTime(0);
          final bt = b.lastMessageTimestamp ?? DateTime(0);
          return bt.compareTo(at);
        });
        state = AsyncData(updated);
      });
    });

    return list;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(messagesRepositoryProvider).getConversations(),
    );
  }
}

// ── Chat messages (avec cache SQLite) ────────────────────────────────────
final chatMessagesProvider =
    AsyncNotifierProvider.family<ChatMessagesNotifier, List<Message>, String>(
  ChatMessagesNotifier.new,
);

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<List<Message>, String> {
  MessageCache get _cache =>
      MessageCache(ref.read(localDbProvider));

  @override
  Future<List<Message>> build(String conversationId) async {
    // 1. Serve cache immediately so the UI has something to show
    final cached = await _cache.getMessages(conversationId);
    if (cached.isNotEmpty) state = AsyncData(cached);

    // 2. Fetch only new messages from REST (diff with stored IDs)
    final repo = ref.read(messagesRepositoryProvider);
    final storedIds = await _cache.getStoredIds(conversationId);
    final serverMessages = await repo.getMessages(conversationId);
    final newMessages =
        serverMessages.where((m) => !storedIds.contains(m.id)).toList();

    if (newMessages.isNotEmpty) {
      await _cache.saveMessages(newMessages);
    }

    // Merge: cached + new (preserve order by timestamp)
    final merged = [...cached, ...newMessages]
      ..sort((a, b) {
        final at = a.timestamp ?? DateTime(0);
        final bt = b.timestamp ?? DateTime(0);
        return at.compareTo(bt);
      });
    // Deduplicate
    final seen = <String>{};
    final deduped =
        merged.where((m) => seen.add(m.id)).toList();

    // 3. Connect WS
    final storage = ref.read(secureStorageProvider);
    final userId = await storage.getUserId();
    final ws = ref.read(webSocketServiceProvider);
    if (!ws.isConnected && userId != null) {
      await ws.connect(userId: userId, conversationId: conversationId);
    } else {
      ws.subscribeToConversation(conversationId);
    }

    // 4. Stream new WS messages into state + cache
    ws.messageStream.listen((msg) {
      if (msg.conversationId != conversationId) return;
      final current = state.valueOrNull ?? [];
      if (current.any((m) => m.id == msg.id)) return;
      _cache.saveMessage(msg);
      state = AsyncData([...current, msg]);
    });

    return deduped;
  }

  Future<void> send(String content) async {
    final repo = ref.read(messagesRepositoryProvider);
    final msg =
        await repo.sendMessage(conversationId: arg, content: content);
    await _cache.saveMessage(msg);
    final current = state.valueOrNull ?? [];
    if (!current.any((m) => m.id == msg.id)) {
      state = AsyncData([...current, msg]);
    }
  }
}

// ── Unread count ─────────────────────────────────────────────────────────
final unreadCountProvider = FutureProvider<int>(
  (ref) => ref.read(messagesRepositoryProvider).getUnreadCount(),
);
