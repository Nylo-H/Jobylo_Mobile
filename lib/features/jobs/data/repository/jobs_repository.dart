import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_filters.dart';
import '../datasource/jobs_remote_datasource.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  final dio = ref.read(dioProvider);
  return JobsRepository(JobsRemoteDatasource(dio));
});

class JobsRepository {
  final JobsRemoteDatasource _datasource;

  JobsRepository(this._datasource);

  Future<List<Job>> getAvailableJobs() async {
    final data = await _datasource.getAvailableJobs();
    return data.map((json) => Job.fromJson(json)).toList();
  }

  Future<Job> getJobById(String jobId) async {
    final data = await _datasource.getJobById(jobId);
    return Job.fromJson(data);
  }

  Future<List<Job>> getMyCreatedJobs() async {
    final data = await _datasource.getMyCreatedJobs();
    return data.map((json) => Job.fromJson(json)).toList();
  }

  Future<List<Job>> getMyAssignedJobs() async {
    final data = await _datasource.getMyAssignedJobs();
    return data.map((json) => Job.fromJson(json)).toList();
  }

  Future<List<Job>> getAvailableJobsFiltered(JobFilters filters) async {
    final data = await _datasource.getAvailableJobsFiltered(filters.toQueryParams());
    return data.map((json) => Job.fromJson(json)).toList();
  }

  Future<Job> createJob({
    required String title,
    required String description,
    required String location,
    required double price,
    required String categoryId,
    List<String> images = const [],
  }) async {
    final data = await _datasource.createJob({
      'title': title,
      'description': description,
      'location': location,
      'price': price,
      'categoryId': categoryId,
      'images': images,
    });
    return Job.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getCategories() {
    return _datasource.getCategories();
  }
}
