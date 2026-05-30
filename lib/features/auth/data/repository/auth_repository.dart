import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../datasource/auth_remote_datasource.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthRepository(
    datasource: AuthRemoteDatasource(dio),
    storage: storage,
  );
});

class AuthRepository {
  final AuthRemoteDatasource datasource;
  final SecureStorage storage;

  AuthRepository({required this.datasource, required this.storage});

  Future<User> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await datasource.register(
      firstName: firstName,
      lastName: lastName,
      username: username,
      email: email,
      password: password,
    );
    return User.fromJson(data);
  }

  /// Returns `verified` flag from the server response.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final data = await datasource.login(email: email, password: password);
    await _saveTokens(data);
    return data['verified'] as bool? ?? true;
  }

  /// Verifies OTP → auto-login → returns User (tokens already stored).
  Future<User> verifyOtpAndLogin({
    required String email,
    required String otp,
  }) async {
    final data = await datasource.verifyOtpLogin(email: email, otp: otp);
    await _saveTokens(data);
    return getMe();
  }

  Future<void> resendOtp({required String email}) async {
    await datasource.resendOtp(email: email);
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final access = data['accesstoken'] as String?;
    final refresh = data['refreshtoken'] as String?;
    if (access != null) await storage.saveAccessToken(access);
    if (refresh != null) await storage.saveRefreshToken(refresh);
  }

  Future<User> getMe() async {
    final data = await datasource.getMe();
    final user = User.fromJson(data);
    await storage.saveUserId(user.id);
    return user;
  }

  Future<User> uploadProfilePhoto(String filePath) async {
    final data = await datasource.uploadProfilePhoto(filePath);
    return User.fromJson(data);
  }

  Future<void> logout() async {
    await storage.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await storage.getAccessToken();
    return token != null;
  }
}
