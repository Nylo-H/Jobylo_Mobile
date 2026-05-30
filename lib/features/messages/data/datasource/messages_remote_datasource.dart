import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class MessagesRemoteDatasource {
  final Dio _dio;
  MessagesRemoteDatasource(this._dio);

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final r = await _dio.get(ApiConstants.conversations);
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Returns a Spring Page response: { content, totalPages, number, last }
  Future<Map<String, dynamic>> getMessagesPaged(
    String conversationId, {
    int page = 0,
    int size = 50,
  }) async {
    try {
      final r = await _dio.get(
        '${ApiConstants.messagesConversation}/$conversationId',
        queryParameters: {'page': page, 'size': size},
      );
      // Supports both paginated (Map) and legacy list responses
      if (r.data is List) {
        return {
          'content': r.data,
          'last': true,
          'number': 0,
          'totalPages': 1,
        };
      }
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> startConversation({
    required String jobId,
    required String content,
  }) async {
    try {
      final r = await _dio.post(
        '${ApiConstants.messagesStart}/$jobId',
        data: {'content': content},
      );
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final r = await _dio.post(
        ApiConstants.messages,
        data: {'conversationId': conversationId, 'content': content},
      );
      return r.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final r = await _dio.get(ApiConstants.unreadCount);
      return (r.data as Map<String, dynamic>)['unreadCount'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markMessageRead(String messageId) async {
    try {
      await _dio.patch('${ApiConstants.messages}/$messageId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Marks ALL unread messages in the conversation as read in one call.
  Future<void> markConversationRead(String conversationId) async {
    try {
      await _dio.patch(
        '${ApiConstants.messagesConversation}/$conversationId/read',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static List<Map<String, dynamic>> _toList(dynamic data) {
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (data is Map && data.containsKey('content')) {
      return _toList(data['content']);
    }
    return [];
  }
}
