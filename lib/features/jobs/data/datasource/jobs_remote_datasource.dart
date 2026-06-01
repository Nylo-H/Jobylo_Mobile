import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class JobsRemoteDatasource {
  final Dio _dio;
  JobsRemoteDatasource(this._dio);

  Future<List<Map<String, dynamic>>> getAvailableJobs() async {
    try {
      final r = await _dio.get(ApiConstants.jobsAvailable);
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      final r = await _dio.get('${ApiConstants.jobs}/$jobId');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyCreatedJobs() async {
    try {
      final r = await _dio.get(ApiConstants.jobsMyCreated);
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyAssignedJobs() async {
    try {
      final r = await _dio.get(ApiConstants.jobsMyAssigned);
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableJobsFiltered(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final r = await _dio.get(
        ApiConstants.jobsAvailable,
        queryParameters: queryParams,
      );
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post(ApiConstants.jobs, data: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final r = await _dio.get(ApiConstants.categoriesTree);
      return _toList(r.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateJob(
      String jobId, Map<String, dynamic> body) async {
    try {
      final r = await _dio.put('${ApiConstants.jobs}/$jobId', data: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> updateJobStatus(
      String jobId, String status) async {
    try {
      final r = await _dio.patch(
        '${ApiConstants.jobs}/$jobId/status',
        queryParameters: {'status': status},
      );
      return Map<String, dynamic>.from(r.data as Map);
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
