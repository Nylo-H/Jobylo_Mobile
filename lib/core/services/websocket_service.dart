import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../../features/messages/domain/entities/message.dart';
import '../../features/messages/domain/entities/conversation.dart';

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return WebSocketService(storage: storage);
});

class WebSocketService {
  final SecureStorage storage;
  StompClient? _client;

  // Stream controllers
  final _messageController = StreamController<Message>.broadcast();
  final _conversationUpdateController = StreamController<Conversation>.broadcast();

  Stream<Message> get messageStream => _messageController.stream;
  Stream<Conversation> get conversationUpdateStream => _conversationUpdateController.stream;

  bool _connected = false;
  bool get isConnected => _connected;

  WebSocketService({required this.storage});

  Future<void> connect({
    required String userId,
    required String? conversationId,
  }) async {
    final token = await storage.getAccessToken();
    if (token == null) return;

    _client = StompClient(
      config: StompConfig(
        url: ApiConstants.wsUrl,
        onConnect: (frame) {
          _connected = true;
          // Subscribe to personal notifications
          _client!.subscribe(
            destination: '/topic/notifications/$userId',
            callback: (frame) {
              if (frame.body == null) return;
              try {
                final json = jsonDecode(frame.body!) as Map<String, dynamic>;
                final conv = Conversation(
                  conversationId: json['conversationId'] as String,
                  jobId: json['jobId'] as String? ?? '',
                  jobTitle: json['jobTitle'] as String? ?? '',
                  otherUserId: json['senderId'] as String,
                  otherUserUsername: json['senderUsername'] as String? ?? '',
                  lastMessage: json['lastMessage'] as String?,
                  lastMessageTimestamp: json['lastMessageTimestamp'] != null
                      ? DateTime.parse(json['lastMessageTimestamp'] as String)
                      : null,
                  unreadCount: json['unreadCount'] as int? ?? 1,
                );
                _conversationUpdateController.add(conv);
              } catch (_) {}
            },
          );
          // Subscribe to conversation messages if open
          if (conversationId != null) {
            subscribeToConversation(conversationId);
          }
        },
        onDisconnect: (_) => _connected = false,
        onWebSocketError: (_) => _connected = false,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );
    _client!.activate();
  }

  void subscribeToConversation(String conversationId) {
    if (_client == null || !_connected) return;
    _client!.subscribe(
      destination: '/topic/messages/$conversationId',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final json = jsonDecode(frame.body!) as Map<String, dynamic>;
          _messageController.add(Message.fromJson(json));
        } catch (_) {}
      },
    );
  }

  void disconnect() {
    _client?.deactivate();
    _connected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _conversationUpdateController.close();
  }
}
