import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class MessagesRemoteDatasource {
  final Dio _dio;

  MessagesRemoteDatasource(this._dio);

  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _dio.get(ApiConstants.conversations);
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.messagesConversation}/$conversationId',
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> startConversation({
    required String jobId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.messagesStart}/$jobId',
        data: {'content': content},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.messages,
        data: {'conversationId': conversationId, 'content': content},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiConstants.unreadCount);
      return (response.data as Map<String, dynamic>)['unreadCount'] as int? ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _dio.patch('${ApiConstants.messages}/$messageId/read');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
