import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../../applications/presentation/pages/my_applications_page.dart';
import '../../domain/entities/job.dart';
import '../providers/jobs_provider.dart';
import 'create_job_page.dart';

class MyJobsPage extends ConsumerStatefulWidget {
  const MyJobsPage({super.key});

  @override
  ConsumerState<MyJobsPage> createState() => _MyJobsPageState();
}

class _MyJobsPageState extends ConsumerState<MyJobsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Créées'),
            Tab(text: 'En cours'),
            Tab(text: 'Candidatures'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FilteredJobsList(
            provider: myCreatedJobsProvider,
            onRefresh: () => ref.invalidate(myCreatedJobsProvider),
          ),
          _JobsList(
            provider: myAssignedJobsProvider,
            emptyMessage: 'Aucune mission en cours.',
            emptyIcon: Icons.engineering_outlined,
            onRefresh: () => ref.invalidate(myAssignedJobsProvider),
          ),
          const MyApplicationsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateJob,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle annonce',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobPage()),
    );
    if (created == true) ref.invalidate(myCreatedJobsProvider);
  }
}

// ── Liste "Créées" avec filtre par statut ─────────────────────────────────
class _FilteredJobsList extends ConsumerStatefulWidget {
  final ProviderBase<AsyncValue<List>> provider;
  final VoidCallback onRefresh;

  const _FilteredJobsList({
    required this.provider,
    required this.onRefresh,
  });

  @override
  ConsumerState<_FilteredJobsList> createState() => _FilteredJobsListState();
}

class _FilteredJobsListState extends ConsumerState<_FilteredJobsList> {
  String? _statusFilter; // null = tous

  static const _filters = [
    (null, 'Toutes'),
    ('PENDING', 'Disponibles'),
    ('IN_PROGRESS', 'En cours'),
    ('DONE', 'Terminées'),
    ('EXPIRED', 'Expirées'),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(widget.provider);

    return Column(
      children: [
        // ── Filtre chips ─────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSizes.xs),
            itemBuilder: (_, i) {
              final (value, label) = _filters[i];
              final isSelected = _statusFilter == value;
              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) =>
                    setState(() => _statusFilter = value),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Liste ───────────────────────────────────────────────────
        Expanded(
          child: async.when(
            loading: () => const AppLoading(),
            error: (e, _) => AppError(
                message: e.toString(), onRetry: widget.onRefresh),
            data: (jobs) {
              final filtered = _statusFilter == null
                  ? jobs.cast<Job>()
                  : jobs.cast<Job>()
                      .where((j) => j.status == _statusFilter)
                      .toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => widget.onRefresh(),
                  child: AppEmpty(
                    message: _statusFilter != null
                        ? 'Aucune annonce "${_statusFilter!.toLowerCase()}".'
                        : 'Vous n\'avez pas encore créé d\'annonce.',
                    icon: Icons.post_add_outlined,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.sm),
                  itemBuilder: (context, i) =>
                      _JobCard(job: filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── JobCard avec badge de statut enrichi ─────────────────────────────────
class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final statusColor = _colorForStatus(job.status);
    final statusLabel = _labelForStatus(job.status);

    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: job.isExpired
                ? AppColors.textHint.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Opacity(
          opacity: job.isExpired ? 0.7 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(children: [
              // Image ou icône placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: job.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusSm),
                        child: Image.network(
                          job.fullImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                              Icons.work_outline,
                              color: AppColors.textHint),
                        ),
                      )
                    : const Icon(Icons.work_outline,
                        color: AppColors.textHint, size: 28),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      '${job.price.toStringAsFixed(0)} FCFA • ${job.location}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Deadline warning
                    if (job.applicationDeadline != null && job.isPending)
                      Text(
                        job.deadlineCountdown,
                        style: TextStyle(
                          fontSize: 11,
                          color: job.isDeadlinePassed
                              ? AppColors.warning
                              : AppColors.textHint,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  static Color _colorForStatus(String s) {
    switch (s) {
      case 'PENDING': return AppColors.success;
      case 'IN_PROGRESS': return AppColors.warning;
      case 'DONE': return AppColors.primary;
      case 'EXPIRED': return AppColors.textHint;
      default: return AppColors.textHint;
    }
  }

  static String _labelForStatus(String s) {
    switch (s) {
      case 'PENDING': return 'Disponible';
      case 'IN_PROGRESS': return 'En cours';
      case 'DONE': return 'Terminé';
      case 'EXPIRED': return 'Expirée';
      default: return s;
    }
  }
}

// ── Simple jobs list (assigned) ───────────────────────────────────────────
class _JobsList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List>> provider;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRefresh;

  const _JobsList({
    required this.provider,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(message: e.toString(), onRetry: onRefresh),
      data: (jobs) {
        if (jobs.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => onRefresh(),
            child: AppEmpty(message: emptyMessage, icon: emptyIcon),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: jobs.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, i) => _JobCard(job: jobs[i] as Job),
          ),
        );
      },
    );
  }
}
