import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/jobs_repository.dart';
import '../../domain/entities/job.dart';
import '../../domain/entities/job_filters.dart';

// ── Filters state ──────────────────────────────────────────────────────────
final jobFiltersProvider = StateNotifierProvider<JobFiltersNotifier, JobFilters>(
  (ref) => JobFiltersNotifier(),
);

class JobFiltersNotifier extends StateNotifier<JobFilters> {
  JobFiltersNotifier() : super(const JobFilters());

  void setCategory(String? id) =>
      state = state.copyWith(categoryId: id, clearCategory: id == null);

  void setSearch(String? q) =>
      state = state.copyWith(q: q, clearSearch: q == null || q.isEmpty);

  void setSort(String sort) => state = state.copyWith(sort: sort);

  void setPriceRange(double? min, double? max) =>
      state = state.copyWith(minPrice: min, maxPrice: max);

  void reset() => state = const JobFilters();
}

// ── Available jobs (with filters) ─────────────────────────────────────────
final availableJobsProvider = FutureProvider<List<Job>>((ref) {
  final filters = ref.watch(jobFiltersProvider);
  final repo = ref.read(jobsRepositoryProvider);
  return repo.getAvailableJobsFiltered(filters);
});

// ── Job detail ────────────────────────────────────────────────────────────
final jobDetailProvider = FutureProvider.family<Job, String>((ref, jobId) {
  return ref.read(jobsRepositoryProvider).getJobById(jobId);
});

// ── My jobs ───────────────────────────────────────────────────────────────
final myCreatedJobsProvider = FutureProvider<List<Job>>((ref) {
  return ref.read(jobsRepositoryProvider).getMyCreatedJobs();
});

final myAssignedJobsProvider = FutureProvider<List<Job>>((ref) {
  return ref.read(jobsRepositoryProvider).getMyAssignedJobs();
});

// ── Categories ────────────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(jobsRepositoryProvider).getCategories();
});

// Legacy alias kept for category_chips widget
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
