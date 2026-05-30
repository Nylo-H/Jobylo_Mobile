import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../data/repository/profile_repository.dart';
import '../../domain/entities/user_stats.dart';

final profileProvider = Provider<AsyncValue<User?>>((ref) {
  return ref.watch(authStateProvider);
});

final userStatsProvider = FutureProvider<UserStats>((ref) {
  return ref.read(profileRepositoryProvider).getMyStats();
});
