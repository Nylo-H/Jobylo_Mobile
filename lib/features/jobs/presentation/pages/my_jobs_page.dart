import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../../../shared/widgets/job_card.dart';
import '../../../applications/presentation/pages/my_applications_page.dart';
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
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
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
          _JobsList(
            provider: myCreatedJobsProvider,
            emptyMessage: 'Vous n\'avez pas encore créé d\'annonce.',
            emptyIcon: Icons.post_add_outlined,
            onRefresh: () => ref.invalidate(myCreatedJobsProvider),
          ),
          _JobsList(
            provider: myAssignedJobsProvider,
            emptyMessage: 'Aucune mission en cours.',
            emptyIcon: Icons.engineering_outlined,
            onRefresh: () => ref.invalidate(myAssignedJobsProvider),
          ),
          // Mes candidatures (worker view)
          const MyApplicationsPage(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateJob,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouvelle annonce',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateJobPage()),
    );
    if (created == true) {
      ref.invalidate(myCreatedJobsProvider);
    }
  }
}

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
      error: (e, _) =>
          AppError(message: e.toString(), onRetry: onRefresh),
      data: (jobs) {
        if (jobs.isEmpty) {
          return AppEmpty(message: emptyMessage, icon: emptyIcon);
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: jobs.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSizes.md),
            itemBuilder: (context, i) => JobCard(
              job: jobs[i],
              onTap: () => context.push('/jobs/${jobs[i].id}'),
            ),
          ),
        );
      },
    );
  }
}
