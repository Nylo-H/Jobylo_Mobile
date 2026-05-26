import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../../../shared/widgets/job_card.dart';
import '../providers/jobs_provider.dart';
import '../widgets/category_chips.dart';
import 'create_job_page.dart';

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(jobFiltersProvider.notifier).setSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(availableJobsProvider);
    final filters = ref.watch(jobFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSearch
                ? const Icon(Icons.close,
                    key: ValueKey('close'), color: AppColors.textPrimary)
                : const Icon(Icons.search,
                    key: ValueKey('search'), color: AppColors.textPrimary),
          ),
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchController.clear();
              ref.read(jobFiltersProvider.notifier).setSearch(null);
            }
          },
        ),
        title: const Text('Jobylo'),
        actions: [
          if (filters.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_list_off,
                  color: AppColors.error),
              tooltip: 'Effacer les filtres',
              onPressed: () {
                ref.read(jobFiltersProvider.notifier).reset();
                _searchController.clear();
                setState(() => _showSearch = false);
              },
            ),
          // Sort button
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.textPrimary),
            onSelected: (sort) =>
                ref.read(jobFiltersProvider.notifier).setSort(sort),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date_desc', child: Text('Plus récents')),
              PopupMenuItem(value: 'date_asc', child: Text('Plus anciens')),
              PopupMenuItem(value: 'price_asc', child: Text('Prix ↑')),
              PopupMenuItem(value: 'price_desc', child: Text('Prix ↓')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: const Icon(
                  Icons.person, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar (animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSizes.md, AppSizes.sm, AppSizes.md, 0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une mission...',
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textHint, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close,
                                    size: 18, color: AppColors.textHint),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(jobFiltersProvider.notifier)
                                      .setSearch(null);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emplois',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  filters.hasActiveFilters
                      ? 'Résultats filtrés'
                      : 'Trouvez votre prochaine mission.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),

          const CategoryChips(),
          const SizedBox(height: AppSizes.md),

          Expanded(
            child: jobsAsync.when(
              loading: () => const AppLoading(),
              error: (error, _) => AppError(
                message: error.toString(),
                onRetry: () => ref.invalidate(availableJobsProvider),
              ),
              data: (jobs) {
                if (jobs.isEmpty) {
                  return AppEmpty(
                    message: filters.hasActiveFilters
                        ? 'Aucun résultat pour ces filtres.'
                        : 'Aucune annonce disponible pour le moment.',
                    icon: Icons.work_off_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(availableJobsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return JobCard(
                        job: job,
                        onTap: () => context.push('/jobs/${job.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateJobPage()),
          );
          if (created == true) {
            ref.invalidate(availableJobsProvider);
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
