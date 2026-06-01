import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../../features/messages/domain/entities/message.dart';
import '../../features/messages/domain/entities/conversation.dart';

// ── Events ────────────────────────────────────────────────────────────────

class ReadReceiptEvent {
  final String conversationId;
  final String readByUserId;
  final String? readByUsername;
  final DateTime? readAt;

  const ReadReceiptEvent({
    required this.conversationId,
    required this.readByUserId,
    this.readByUsername,
    this.readAt,
  });

  factory ReadReceiptEvent.fromJson(Map<String, dynamic> json) =>
      ReadReceiptEvent(
        conversationId: json['conversationId'] as String,
        readByUserId: json['readByUserId'] as String,
        readByUsername: json['readByUsername'] as String?,
        readAt: json['readAt'] != null
            ? DateTime.parse(json['readAt'] as String)
            : null,
      );
}

class PresenceEvent {
  final String userId;
  final bool online;
  final DateTime? lastSeenAt;

  const PresenceEvent({
    required this.userId,
    required this.online,
    this.lastSeenAt,
  });

  factory PresenceEvent.fromJson(Map<String, dynamic> json) => PresenceEvent(
        userId: json['userId'] as String,
        online: json['online'] as bool? ?? false,
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
      );
}

// ── Provider ─────────────────────────────────────────────────────────────

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final svc = WebSocketService(storage: ref.read(secureStorageProvider));
  ref.onDispose(svc.dispose);
  return svc;
});

// ── Service ───────────────────────────────────────────────────────────────

class WebSocketService {
  final SecureStorage storage;
  StompClient? _client;

  // Broadcast streams
  final _messageCtrl = StreamController<Message>.broadcast();
  final _convUpdateCtrl = StreamController<Conversation>.broadcast();
  final _readReceiptCtrl = StreamController<ReadReceiptEvent>.broadcast();
  final _presenceCtrl = StreamController<PresenceEvent>.broadcast();

  Stream<Message> get messageStream => _messageCtrl.stream;
  Stream<Conversation> get conversationUpdateStream => _convUpdateCtrl.stream;
  Stream<ReadReceiptEvent> get readReceiptStream => _readReceiptCtrl.stream;
  Stream<PresenceEvent> get presenceStream => _presenceCtrl.stream;

  // Online users cache: userId → bool
  final Map<String, bool> _onlineUsers = {};
  bool isUserOnline(String userId) => _onlineUsers[userId] ?? false;

  // Deduplication: track seen message IDs to avoid duplicates from personal queue + topic
  final Set<String> _seenMessageIds = {};

  bool _connected = false;
  bool get isConnected => _connected;

  // Track active conversation subscriptions so we can unsubscribe
  final Map<String, StompUnsubscribe> _convSubs = {};
  final Map<String, StompUnsubscribe> _readSubs = {};

  WebSocketService({required this.storage});

  // ── Connect ────────────────────────────────────────────────────────────

  Future<void> connect({
    required String userId,
    String? conversationId,
  }) async {
    if (_connected) {
      if (conversationId != null) openConversation(conversationId);
      return;
    }

    final token = await storage.getAccessToken();
    if (token == null) return;

    _client = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (frame) => _onConnected(frame, userId, conversationId),
        onDisconnect: (_) => _connected = false,
        onWebSocketError: (_) => _connected = false,
        onStompError: (_) => _connected = false,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _client!.activate();
  }

  void _onConnected(
    StompFrame frame,
    String userId,
    String? conversationId,
  ) {
    _connected = true;

    // ── /user/{userId}/queue/messages — personal queue (all messages) ─
    // Fixes "first message doesn't appear": this queue receives ALL messages
    // for this user regardless of whether the topic subscription exists yet.
    _client!.subscribe(
      destination: '/user/$userId/queue/messages',
      callback: (f) {
        if (f.body == null) return;
        try {
          final msg = Message.fromJson(
              jsonDecode(f.body!) as Map<String, dynamic>);
          // Deduplicate: topic subscription may also deliver this message
          if (!_seenMessageIds.contains(msg.id)) {
            _seenMessageIds.add(msg.id);
            _messageCtrl.add(msg);
          }
        } catch (_) {}
      },
    );

    // ── /topic/notifications/{userId} ─────────────────────────────────
    _client!.subscribe(
      destination: '/topic/notifications/$userId',
      callback: (f) {
        if (f.body == null) return;
        try {
          final json = jsonDecode(f.body!) as Map<String, dynamic>;
          final conv = Conversation(
            conversationId: json['conversationId'] as String,
            jobId: json['jobId'] as String? ?? '',
            jobTitle: json['jobTitle'] as String? ?? '',
            otherUserId: json['senderId'] as String? ?? '',
            otherUserUsername: json['senderUsername'] as String? ?? '',
            lastMessage: json['lastMessage'] as String?,
            lastMessageTimestamp: json['lastMessageTimestamp'] != null
                ? DateTime.parse(json['lastMessageTimestamp'] as String)
                : null,
            unreadCount: json['unreadCount'] as int? ?? 1,
          );
          _convUpdateCtrl.add(conv);
        } catch (_) {}
      },
    );

    // ── /topic/presence ───────────────────────────────────────────────
    _client!.subscribe(
      destination: '/topic/presence',
      callback: (f) {
        if (f.body == null) return;
        try {
          final event = PresenceEvent.fromJson(
              jsonDecode(f.body!) as Map<String, dynamic>);
          _onlineUsers[event.userId] = event.online;
          _presenceCtrl.add(event);
        } catch (_) {}
      },
    );

    // Open conversation if given
    if (conversationId != null) openConversation(conversationId);
  }

  // ── Conversation sub/unsub ─────────────────────────────────────────────

  void openConversation(String conversationId) {
    if (_client == null || !_connected) return;
    if (_convSubs.containsKey(conversationId)) return; // already subscribed

    // Messages temps réel (deduplicated with personal queue)
    final msgUnsub = _client!.subscribe(
      destination: '/topic/messages/$conversationId',
      callback: (f) {
        if (f.body == null) return;
        try {
          final msg = Message.fromJson(
              jsonDecode(f.body!) as Map<String, dynamic>);
          if (!_seenMessageIds.contains(msg.id)) {
            _seenMessageIds.add(msg.id);
            _messageCtrl.add(msg);
          }
        } catch (_) {}
      },
    );
    _convSubs[conversationId] = msgUnsub;

    // Read receipts (✅✅ bleus)
    final readUnsub = _client!.subscribe(
      destination: '/topic/read/$conversationId',
      callback: (f) {
        if (f.body == null) return;
        try {
          _readReceiptCtrl.add(ReadReceiptEvent.fromJson(
              jsonDecode(f.body!) as Map<String, dynamic>));
        } catch (_) {}
      },
    );
    _readSubs[conversationId] = readUnsub;
  }

  void closeConversation(String conversationId) {
    _convSubs.remove(conversationId)?.call(unsubscribeHeaders: {});
    _readSubs.remove(conversationId)?.call(unsubscribeHeaders: {});
  }

  // kept for backward compat
  void subscribeToConversation(String conversationId) =>
      openConversation(conversationId);

  // ── Disconnect / Dispose ──────────────────────────────────────────────

  void disconnect() {
    _client?.deactivate();
    _connected = false;
    _convSubs.clear();
    _readSubs.clear();
    _seenMessageIds.clear();
  }

  void dispose() {
    disconnect();
    _messageCtrl.close();
    _convUpdateCtrl.close();
    _readReceiptCtrl.close();
    _presenceCtrl.close();
  }
}
