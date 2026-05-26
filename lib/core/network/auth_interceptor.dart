import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final SecureStorage storage;
  bool _isRefreshing = false;

  AuthInterceptor({required this.dio, required this.storage});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Avoid infinite loop on /auth/refresh itself
    if (err.response?.statusCode == 401 &&
        !err.requestOptions.path.contains(ApiConstants.refresh) &&
        !_isRefreshing) {
      _isRefreshing = true;
      try {
        final newAccess = await _rotateTokens();
        if (newAccess != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
          final response = await dio.fetch(err.requestOptions);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (_) {
        await storage.clearAll();
      } finally {
        _isRefreshing = false;
      }
    }
    handler.next(err);
  }

  /// Sends refreshToken in the JSON body as per new backend rotation contract.
  /// Returns the new accessToken, or null on failure.
  Future<String?> _rotateTokens() async {
    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(ApiConstants.refresh, data: {'refreshToken': refreshToken});

      final data = response.data as Map<String, dynamic>;
      final newAccess = data['accesstoken'] as String?;
      final newRefresh = data['refreshtoken'] as String?;

      if (newAccess != null) await storage.saveAccessToken(newAccess);
      if (newRefresh != null) await storage.saveRefreshToken(newRefresh);

      return newAccess;
    } catch (_) {
      return null;
    }
  }
}
