import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final String errorCode;
  final int statusCode;

  const ApiException({
    required this.message,
    this.errorCode = 'UNKNOWN',
    this.statusCode = 0,
  });

  factory ApiException.fromDioException(DioException e) {
    // No network response at all
    if (e.response == null) {
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.sendTimeout =>
          const ApiException(
            message: 'Connexion lente. Réessayez.',
            errorCode: 'NETWORK_ERROR',
            statusCode: 0,
          ),
        DioExceptionType.connectionError => const ApiException(
            message: 'Pas de connexion internet.',
            errorCode: 'NETWORK_ERROR',
            statusCode: 0,
          ),
        _ => const ApiException(
            message: 'Une erreur est survenue.',
            errorCode: 'UNKNOWN',
            statusCode: 0,
          ),
      };
    }

    final status = e.response!.statusCode ?? 0;
    final data = e.response!.data;

    // Standard backend error format: { status, error, errorCode, ... }
    if (data is Map) {
      final msg = data['error'] as String? ??
          data['message'] as String? ??
          'Une erreur est survenue';
      final code = data['errorCode'] as String? ?? _codeFromStatus(status);
      return ApiException(message: msg, errorCode: code, statusCode: status);
    }

    // Plain string body
    if (data is String && data.isNotEmpty) {
      return ApiException(
        message: data,
        errorCode: _codeFromStatus(status),
        statusCode: status,
      );
    }

    return ApiException(
      message: _messageFromStatus(status),
      errorCode: _codeFromStatus(status),
      statusCode: status,
    );
  }

  static String _codeFromStatus(int status) {
    switch (status) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      case 429:
        return 'TOO_MANY_REQUESTS';
      case 500:
        return 'INTERNAL_ERROR';
      default:
        return 'UNKNOWN';
    }
  }

  static String _messageFromStatus(int status) {
    switch (status) {
      case 400:
        return 'Requête invalide.';
      case 401:
        return 'Session expirée. Reconnectez-vous.';
      case 403:
        return 'Action non autorisée.';
      case 404:
        return 'Ressource introuvable.';
      case 409:
        return 'Conflit : cette action a déjà été effectuée.';
      case 429:
        return 'Trop de tentatives. Réessayez plus tard.';
      case 500:
        return 'Erreur serveur. Réessayez plus tard.';
      default:
        return 'Une erreur est survenue.';
    }
  }

  bool get isUnauthorized => statusCode == 401 || errorCode == 'UNAUTHORIZED';
  bool get isForbidden => statusCode == 403 || errorCode == 'FORBIDDEN';
  bool get isKycRequired =>
      isForbidden &&
      (message.toLowerCase().contains('kyc') ||
          message.toLowerCase().contains('vérification') ||
          message.toLowerCase().contains('identité'));
  bool get isConflict => statusCode == 409 || errorCode == 'CONFLICT';
  bool get isNotFound => statusCode == 404 || errorCode == 'NOT_FOUND';
  bool get isRateLimit =>
      statusCode == 429 || errorCode == 'TOO_MANY_REQUESTS';
  bool get isNetwork => errorCode == 'NETWORK_ERROR' || statusCode == 0;

  @override
  String toString() => message;
}
