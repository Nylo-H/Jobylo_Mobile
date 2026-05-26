import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class JobsRemoteDatasource {
  final Dio _dio;

  JobsRemoteDatasource(this._dio);

  Future<List<Map<String, dynamic>>> getAvailableJobs() async {
    try {
      final response = await _dio.get(ApiConstants.jobsAvailable);
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getJobById(String jobId) async {
    try {
      final response = await _dio.get('${ApiConstants.jobs}/$jobId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyCreatedJobs() async {
    try {
      final response = await _dio.get(ApiConstants.jobsMyCreated);
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyAssignedJobs() async {
    try {
      final response = await _dio.get(ApiConstants.jobsMyAssigned);
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableJobsFiltered(
    Map<String, dynamic> queryParams,
  ) async {
    try {
      final response = await _dio.get(
        ApiConstants.jobsAvailable,
        queryParameters: queryParams,
      );
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> createJob(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiConstants.jobs, data: body);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _dio.get(ApiConstants.categoriesTree);
      return (response.data as List).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
