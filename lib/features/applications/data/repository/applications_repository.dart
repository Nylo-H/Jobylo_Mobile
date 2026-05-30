import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/application.dart';
import '../datasource/applications_remote_datasource.dart';

final applicationsRepositoryProvider = Provider<ApplicationsRepository>((ref) {
  return ApplicationsRepository(
    ApplicationsRemoteDatasource(ref.read(dioProvider)),
  );
});

class ApplicationsRepository {
  final ApplicationsRemoteDatasource _datasource;
  ApplicationsRepository(this._datasource);

  Future<Application> applyToJob({
    required String jobId,
    String? coverLetter,
  }) async {
    final data = await _datasource.applyToJob(
      jobId: jobId,
      coverLetter: coverLetter,
    );
    return Application.fromJson(data);
  }

  Future<List<Application>> getMyApplications() async {
    final data = await _datasource.getMyApplications();
    return data.map(Application.fromJson).toList();
  }

  Future<List<Application>> getJobApplicants(String jobId) async {
    final data = await _datasource.getJobApplicants(jobId);
    return data.map(Application.fromJson).toList();
  }

  Future<int> getApplicantsCount(String jobId) =>
      _datasource.getApplicantsCount(jobId);

  Future<void> rejectApplicant({
    required String jobId,
    required String workerId,
  }) =>
      _datasource.rejectApplicant(jobId: jobId, workerId: workerId);

  Future<void> assignWorker({
    required String jobId,
    required String workerId,
  }) =>
      _datasource.assignWorker(jobId: jobId, workerId: workerId);
}
