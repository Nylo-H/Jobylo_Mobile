import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_stats.dart';
import '../datasource/profile_remote_datasource.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ProfileRemoteDatasource(ref.read(dioProvider)));
});

class ProfileRepository {
  final ProfileRemoteDatasource _datasource;
  ProfileRepository(this._datasource);

  Future<UserStats> getMyStats() async {
    final data = await _datasource.getMyStats();
    return UserStats.fromJson(data);
  }
}
