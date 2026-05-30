import 'package:dio/dio.dart';
import '../../../../core/network/api_exception.dart';

class ProfileRemoteDatasource {
  final Dio _dio;
  ProfileRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getMyStats() async {
    try {
      final response = await _dio.get('/users/me/stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
