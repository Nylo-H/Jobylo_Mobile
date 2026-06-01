import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/users_repository.dart';
import '../../domain/entities/public_user.dart';

final publicUserProvider =
    FutureProvider.family<PublicUser, String>((ref, userId) {
  if (userId.isEmpty) throw Exception('userId is empty');
  return ref.read(usersRepositoryProvider).getUserById(userId);
});
