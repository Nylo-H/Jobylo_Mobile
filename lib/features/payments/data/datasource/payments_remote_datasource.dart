import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_exception.dart';

class PaymentsRemoteDatasource {
  final Dio _dio;
  PaymentsRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> initiatePayment(String jobId) async {
    try {
      final r = await _dio.post(ApiConstants.payments, data: {'jobId': jobId});
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> confirmPayment(String transactionId) async {
    try {
      final r = await _dio.post(
        ApiConstants.paymentsConfirm,
        data: {'transactionId': transactionId},
      );
      return Map<String, dynamic>.from(r.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Map<String, dynamic>>> getMyPayments() async {
    try {
      final r = await _dio.get(ApiConstants.payments);
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
