import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/public_user.dart';
import '../datasource/users_remote_datasource.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(UsersRemoteDatasource(ref.read(dioProvider)));
});

class UsersRepository {
  final UsersRemoteDatasource _ds;
  UsersRepository(this._ds);

  Future<PublicUser> getUserById(String userId) async {
    final data = await _ds.getUserById(userId);
    return PublicUser.fromJson(data);
  }
}
