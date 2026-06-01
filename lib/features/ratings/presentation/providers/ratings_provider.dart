import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/ratings_repository.dart';
import '../../domain/entities/rating.dart';

final myRatingsProvider = FutureProvider<List<Rating>>((ref) {
  return ref.read(ratingsRepositoryProvider).getMyRatings();
});

final userRatingsProvider =
    FutureProvider.family<List<Rating>, String>((ref, userId) {
  return ref.read(ratingsRepositoryProvider).getUserRatings(userId);
});
