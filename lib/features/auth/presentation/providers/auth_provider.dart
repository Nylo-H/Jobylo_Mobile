import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/auth_repository.dart';
import '../../domain/entities/user.dart';

// Signals that the user logged in but needs OTP verification.
// Carries the email so OtpPage knows where to redirect.
class NeedsVerification {
  final String email;
  const NeedsVerification(this.email);
}

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

// Separate flag so the router can redirect to OTP without touching authState
final pendingVerificationProvider = StateProvider<NeedsVerification?>((ref) => null);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (!await repo.isLoggedIn()) return null;
    try {
      return await repo.getMe();
    } catch (_) {
      return null;
    }
  }

  /// Returns true if login succeeded and user is verified, false if OTP needed.
  Future<bool> login({required String email, required String password}) async {
    final repo = ref.read(authRepositoryProvider);
    final verified = await repo.login(email: email, password: password);
    if (verified) {
      final user = await repo.getMe();
      state = AsyncData(user);
      return true;
    }
    // Save the email for OTP page routing
    ref.read(pendingVerificationProvider.notifier).state =
        NeedsVerification(email);
    return false;
  }

  /// Called from OtpPage after successful OTP — auto-login.
  Future<void> completeOtpLogin({
    required String email,
    required String otp,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.verifyOtpAndLogin(email: email, otp: otp);
    ref.read(pendingVerificationProvider.notifier).state = null;
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  void setUser(User user) => state = AsyncData(user);

  Future<void> refreshUser() async {
    try {
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AsyncData(user);
    } catch (_) {}
  }
}
