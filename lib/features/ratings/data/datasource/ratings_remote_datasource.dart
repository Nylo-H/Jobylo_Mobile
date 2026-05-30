import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class RatingsRemoteDatasource {
  final Dio _dio;
  RatingsRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> submitRating({
    required String jobId,
    required String targetUserId,
    required int score,
    String? comment,
  }) async {
    try {
      final r = await _dio.post(ApiConstants.ratings, data: {
        'jobId': jobId,
        'targetUserId': targetUserId,
        'score': score,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      });
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getUserRatings(String userId) async {
    try {
      final r = await _dio.get('${ApiConstants.ratings}/user/$userId');
      if (r.data is List) {
        return (r.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getJobRatings(String jobId) async {
    try {
      final r = await _dio.get('${ApiConstants.ratings}/job/$jobId');
      if (r.data is List) {
        return (r.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyRatings() async {
    try {
      final r = await _dio.get('${ApiConstants.ratings}/mine');
      if (r.data is List) {
        return (r.data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
