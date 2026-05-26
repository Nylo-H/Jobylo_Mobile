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

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await datasource.login(
      email: email,
      password: password,
    );
    final token = data['accesstoken'] as String;
    await storage.saveAccessToken(token);

    if (data['refreshtoken'] != null) {
      await storage.saveRefreshToken(data['refreshtoken'] as String);
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await datasource.verifyOtp(email: email, otp: otp);
  }

  Future<void> resendOtp({required String username}) async {
    await datasource.resendOtp(username: username);
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
