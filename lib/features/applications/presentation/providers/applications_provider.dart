import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repository/applications_repository.dart';
import '../../domain/entities/application.dart';

// ── Mes candidatures ──────────────────────────────────────────────────────
final myApplicationsProvider =
    AsyncNotifierProvider<MyApplicationsNotifier, List<Application>>(
  MyApplicationsNotifier.new,
);

class MyApplicationsNotifier extends AsyncNotifier<List<Application>> {
  @override
  Future<List<Application>> build() =>
      ref.read(applicationsRepositoryProvider).getMyApplications();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(applicationsRepositoryProvider).getMyApplications(),
    );
  }
}

// ── Check si déjà postulé à un job ───────────────────────────────────────
final hasAppliedProvider = Provider.family<bool, String>((ref, jobId) {
  final apps = ref.watch(myApplicationsProvider).valueOrNull ?? [];
  return apps.any((a) => a.jobId == jobId);
});

final myApplicationForJobProvider =
    Provider.family<Application?, String>((ref, jobId) {
  final apps = ref.watch(myApplicationsProvider).valueOrNull ?? [];
  try {
    return apps.firstWhere((a) => a.jobId == jobId);
  } catch (_) {
    return null;
  }
});

// ── Candidats d'un job ────────────────────────────────────────────────────
final jobApplicantsProvider =
    AsyncNotifierProvider.family<JobApplicantsNotifier, List<Application>, String>(
  JobApplicantsNotifier.new,
);

class JobApplicantsNotifier
    extends FamilyAsyncNotifier<List<Application>, String> {
  @override
  Future<List<Application>> build(String jobId) =>
      ref.read(applicationsRepositoryProvider).getJobApplicants(jobId);

  Future<void> reject(String workerId) async {
    final repo = ref.read(applicationsRepositoryProvider);
    await repo.rejectApplicant(jobId: arg, workerId: workerId);
    // Update local state immediately
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((a) =>
              a.workerId == workerId ? _withStatus(a, 'REJECTED') : a)
          .toList(),
    );
  }

  Future<void> assign(String workerId) async {
    final repo = ref.read(applicationsRepositoryProvider);
    await repo.assignWorker(jobId: arg, workerId: workerId);
    // All others become REJECTED, chosen one becomes ACCEPTED
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((a) => _withStatus(
              a, a.workerId == workerId ? 'ACCEPTED' : 'REJECTED'))
          .toList(),
    );
  }

  Application _withStatus(Application a, String s) => Application(
        id: a.id,
        jobId: a.jobId,
        jobTitle: a.jobTitle,
        jobPrice: a.jobPrice,
        workerId: a.workerId,
        workerUsername: a.workerUsername,
        workerRating: a.workerRating,
        workerTotalRatings: a.workerTotalRatings,
        coverLetter: a.coverLetter,
        status: s,
        createdAt: a.createdAt,
      );
}

// ── Compteur candidats ────────────────────────────────────────────────────
final applicantsCountProvider =
    FutureProvider.family<int, String>((ref, jobId) {
  return ref.read(applicationsRepositoryProvider).getApplicantsCount(jobId);
});
