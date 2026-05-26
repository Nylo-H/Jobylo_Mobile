import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class KycRemoteDatasource {
  final Dio _dio;
  KycRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String documentType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'documentType': documentType,
      });
      final response = await _dio.post(ApiConstants.kycUpload, data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await _dio.get(ApiConstants.kycStatus);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
