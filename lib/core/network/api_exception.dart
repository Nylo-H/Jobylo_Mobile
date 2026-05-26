import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String? errorCode;
  final int? statusCode;

  const ApiException({
    required this.message,
    this.errorCode,
    this.statusCode,
  });

  factory ApiException.fromDioException(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      return ApiException(
        message: data['message'] as String? ?? 'Une erreur est survenue',
        errorCode: data['errorCode'] as String?,
        statusCode: e.response?.statusCode,
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException(message: 'Connexion lente. Réessayez.');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'Pas de connexion internet.');
      default:
        return const ApiException(message: 'Une erreur est survenue.');
    }
  }

  @override
  String toString() => message;
}
