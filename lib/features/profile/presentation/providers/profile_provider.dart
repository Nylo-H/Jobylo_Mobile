import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';

final profileProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authStateProvider);
});
