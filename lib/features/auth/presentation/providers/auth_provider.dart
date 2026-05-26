import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/auth_repository.dart';
import '../../domain/entities/user.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    final isLoggedIn = await repo.isLoggedIn();
    if (!isLoggedIn) return null;
    try {
      return await repo.getMe();
    } catch (_) {
      return null;
    }
  }

  // Throws on error so the page can catch and display the message
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.login(email: email, password: password);
    final user = await repo.getMe();
    state = AsyncData(user);
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncData(null);
  }

  void setUser(User user) => state = AsyncData(user);

  Future<void> refreshUser() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.getMe();
      state = AsyncData(user);
    } catch (_) {}
  }
}
