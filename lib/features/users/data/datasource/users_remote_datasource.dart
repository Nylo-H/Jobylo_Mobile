import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class UsersRemoteDatasource {
  final Dio _dio;
  UsersRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getUserById(String userId) async {
    try {
      final r = await _dio.get('${ApiConstants.users}/$userId');
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
