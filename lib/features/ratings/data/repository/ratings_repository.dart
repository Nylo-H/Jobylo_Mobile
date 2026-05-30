import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/rating.dart';
import '../datasource/ratings_remote_datasource.dart';

final ratingsRepositoryProvider = Provider<RatingsRepository>((ref) {
  return RatingsRepository(RatingsRemoteDatasource(ref.read(dioProvider)));
});

class RatingsRepository {
  final RatingsRemoteDatasource _ds;
  RatingsRepository(this._ds);

  Future<Rating> submitRating({
    required String jobId,
    required String targetUserId,
    required int score,
    String? comment,
  }) async {
    final data = await _ds.submitRating(
      jobId: jobId,
      targetUserId: targetUserId,
      score: score,
      comment: comment,
    );
    return Rating.fromJson(data);
  }

  Future<List<Rating>> getUserRatings(String userId) async {
    final data = await _ds.getUserRatings(userId);
    return data.map(Rating.fromJson).toList();
  }

  Future<List<Rating>> getJobRatings(String jobId) async {
    final data = await _ds.getJobRatings(jobId);
    return data.map(Rating.fromJson).toList();
  }

  Future<List<Rating>> getMyRatings() async {
    final data = await _ds.getMyRatings();
    return data.map(Rating.fromJson).toList();
  }
}
