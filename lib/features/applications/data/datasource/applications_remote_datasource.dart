import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class ApplicationsRemoteDatasource {
  final Dio _dio;
  ApplicationsRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> applyToJob({
    required String jobId,
    String? coverLetter,
  }) async {
    try {
      final response = await _dio.post(
        '/jobs/$jobId/apply',
        data: coverLetter != null ? {'coverLetter': coverLetter} : null,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    try {
      final response = await _dio.get('/applications/mine');
      return _toList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getJobApplicants(String jobId) async {
    try {
      final response = await _dio.get('/jobs/$jobId/applicants');
      return _toList(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<int> getApplicantsCount(String jobId) async {
    try {
      final response = await _dio.get('/jobs/$jobId/applicants/count');
      final data = Map<String, dynamic>.from(response.data as Map);
      // Spring can return count as int or double depending on DB driver
      return (data['count'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> rejectApplicant({
    required String jobId,
    required String workerId,
  }) async {
    try {
      await _dio.post('/jobs/$jobId/reject/$workerId');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> assignWorker({
    required String jobId,
    required String workerId,
  }) async {
    try {
      await _dio.post('/jobs/$jobId/assign', data: {'workerId': workerId});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Safely converts any List response to List<Map<String, dynamic>>
  static List<Map<String, dynamic>> _toList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    // Wrapped response e.g. { "content": [...] }
    if (data is Map && data.containsKey('content')) {
      return _toList(data['content']);
    }
    return [];
  }
}
