import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/message_cache.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../data/repository/messages_repository.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

// ── Conversations ─────────────────────────────────────────────────────────
final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final list =
        await ref.read(messagesRepositoryProvider).getConversations();
    _listenWs();
    return list;
  }

  void _listenWs() {
    ref.read(webSocketServiceProvider).conversationUpdateStream.listen(
      (updatedConv) {
        final current = state.valueOrNull ?? [];
        final idx = current.indexWhere(
            (c) => c.conversationId == updatedConv.conversationId);
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
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(messagesRepositoryProvider).getConversations(),
    );
  }
}

// ── Chat state ────────────────────────────────────────────────────────────

class ChatState {
  final List<Message> messages;
  final bool isLoadingMore;
  final bool allLoaded;
  final int currentPage;
  // userId → isRead: tracks which remote users have read
  final Map<String, bool> readByOther;

  const ChatState({
    this.messages = const [],
    this.isLoadingMore = false,
    this.allLoaded = false,
    this.currentPage = 0,
    this.readByOther = const {},
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoadingMore,
    bool? allLoaded,
    int? currentPage,
    Map<String, bool>? readByOther,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        allLoaded: allLoaded ?? this.allLoaded,
        currentPage: currentPage ?? this.currentPage,
        readByOther: readByOther ?? this.readByOther,
      );
}

final chatProvider =
    AsyncNotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);

class ChatNotifier extends FamilyAsyncNotifier<ChatState, String> {
  String get _convId => arg;
  MessageCache get _cache => MessageCache(ref.read(localDbProvider));

  @override
  Future<ChatState> build(String convId) async {
    // 1. Serve cache immediately
    final cached = await _cache.getMessages(convId);
    if (cached.isNotEmpty) {
      state = AsyncData(ChatState(messages: cached));
    }

    // 2. Load first page from server (page=0)
    final repo = ref.read(messagesRepositoryProvider);
    final paged = await repo.getMessages(convId, page: 0);

    // Persist new messages
    final storedIds = await _cache.getStoredIds(convId);
    final fresh = paged.messages.where((m) => !storedIds.contains(m.id)).toList();
    if (fresh.isNotEmpty) await _cache.saveMessages(fresh);

    // Merge + dedupe (server is authoritative for page 0)
    final merged = _merge(cached, paged.messages);

    // 3. Mark all as read on open
    repo.markConversationRead(convId).catchError((_) {});

    // 4. Wire WS
    final storage = ref.read(secureStorageProvider);
    final userId = await storage.getUserId();
    final ws = ref.read(webSocketServiceProvider);
    if (userId != null) {
      if (!ws.isConnected) {
        await ws.connect(userId: userId, conversationId: convId);
      } else {
        ws.openConversation(convId);
      }
    }

    // 5. Listen to new WS messages
    ws.messageStream.listen((msg) {
      if (msg.conversationId != convId) return;
      final current = state.valueOrNull?.messages ?? [];
      if (current.any((m) => m.id == msg.id)) return;
      _cache.saveMessage(msg);
      state = AsyncData(
        (state.valueOrNull ?? const ChatState()).copyWith(
          messages: [...current, msg],
        ),
      );
    });

    // 6. Listen to read receipts → update ✅✅
    ws.readReceiptStream.listen((receipt) {
      if (receipt.conversationId != convId) return;
      final cs = state.valueOrNull ?? const ChatState();
      state = AsyncData(cs.copyWith(
        readByOther: {...cs.readByOther, receipt.readByUserId: true},
        // Mark all sent messages as read
        messages: cs.messages
            .map((m) =>
                (m.receiverId == receipt.readByUserId && !m.isRead)
                    ? Message(
                        id: m.id,
                        conversationId: m.conversationId,
                        senderId: m.senderId,
                        senderUsername: m.senderUsername,
                        receiverId: m.receiverId,
                        receiverUsername: m.receiverUsername,
                        jobId: m.jobId,
                        content: m.content,
                        timestamp: m.timestamp,
                        isRead: true,
                      )
                    : m)
            .toList(),
      ));
    });

    return ChatState(
      messages: merged,
      allLoaded: paged.isLast,
      currentPage: 0,
    );
  }

  // ── Load more (scroll to top = older messages) ─────────────────────────
  Future<void> loadMore() async {
    final cs = state.valueOrNull;
    if (cs == null || cs.allLoaded || cs.isLoadingMore) return;

    state = AsyncData(cs.copyWith(isLoadingMore: true));

    try {
      final nextPage = cs.currentPage + 1;
      final paged = await ref
          .read(messagesRepositoryProvider)
          .getMessages(_convId, page: nextPage);

      final storedIds = await _cache.getStoredIds(_convId);
      final fresh = paged.messages
          .where((m) => !storedIds.contains(m.id))
          .toList();
      if (fresh.isNotEmpty) await _cache.saveMessages(fresh);

      // Prepend older messages
      final combined = [...paged.messages, ...cs.messages];
      final deduped = _dedupe(combined);

      state = AsyncData(cs.copyWith(
        messages: deduped,
        isLoadingMore: false,
        allLoaded: paged.isLast,
        currentPage: nextPage,
      ));
    } catch (_) {
      state = AsyncData(cs.copyWith(isLoadingMore: false));
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────
  Future<void> send(String content) async {
    final msg = await ref
        .read(messagesRepositoryProvider)
        .sendMessage(conversationId: _convId, content: content);
    await _cache.saveMessage(msg);
    final cs = state.valueOrNull ?? const ChatState();
    if (!cs.messages.any((m) => m.id == msg.id)) {
      state = AsyncData(cs.copyWith(messages: [...cs.messages, msg]));
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────
  List<Message> _merge(List<Message> a, List<Message> b) {
    final combined = [...a, ...b]
      ..sort((x, y) {
        final xt = x.timestamp ?? DateTime(0);
        final yt = y.timestamp ?? DateTime(0);
        return xt.compareTo(yt);
      });
    return _dedupe(combined);
  }

  List<Message> _dedupe(List<Message> list) {
    final seen = <String>{};
    return list.where((m) => seen.add(m.id)).toList();
  }
}

// ── Presence ─────────────────────────────────────────────────────────────
final presenceProvider = StreamProvider.family<bool, String>((ref, userId) {
  final ws = ref.read(webSocketServiceProvider);
  return ws.presenceStream
      .where((e) => e.userId == userId)
      .map((e) => e.online);
});

// ── Unread count ──────────────────────────────────────────────────────────
final unreadCountProvider = FutureProvider<int>(
  (ref) => ref.read(messagesRepositoryProvider).getUnreadCount(),
);

// ── Legacy alias (MessagesPage still uses conversationsProvider) ──────────
// chatMessagesProvider kept for backward compat with ChatPage constructor
final chatMessagesProvider =
    AsyncNotifierProvider.family<_LegacyChat, List<Message>, String>(
  _LegacyChat.new,
);

class _LegacyChat extends FamilyAsyncNotifier<List<Message>, String> {
  @override
  Future<List<Message>> build(String convId) async {
    // delegate to the real provider
    final cs = await ref.watch(chatProvider(convId).future);
    ref.listen(chatProvider(convId), (_, next) {
      next.whenData((s) => state = AsyncData(s.messages));
    });
    return cs.messages;
  }

  Future<void> send(String content) =>
      ref.read(chatProvider(arg).notifier).send(content);
}
