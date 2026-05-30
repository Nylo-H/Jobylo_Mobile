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
import '../../domain/entities/job_filters.dart';
import '../providers/jobs_provider.dart';
import '../widgets/category_chips.dart';
import 'create_job_page.dart';

// Villes camerounaises fréquentes
const _cameroonCities = [
  'Douala',
  'Yaoundé',
  'Bafoussam',
  'Bamenda',
  'Garoua',
  'Maroua',
  'Ngaoundéré',
  'Bertoua',
  'Kribi',
  'Limbé',
];

class JobsPage extends ConsumerStatefulWidget {
  const JobsPage({super.key});

  @override
  ConsumerState<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends ConsumerState<JobsPage> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(jobFiltersProvider.notifier).setSearch(value);
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(availableJobsProvider);
    final filters = ref.watch(jobFiltersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSearch
                ? const Icon(
                    Icons.close,
                    key: ValueKey('close'),
                    color: AppColors.textPrimary,
                  )
                : const Icon(
                    Icons.search,
                    key: ValueKey('search'),
                    color: AppColors.textPrimary,
                  ),
          ),
          onPressed: () {
            setState(() => _showSearch = !_showSearch);
            if (!_showSearch) {
              _searchCtrl.clear();
              ref.read(jobFiltersProvider.notifier).setSearch(null);
            }
          },
        ),
        title: const Text('Jobylo'),
        actions: [
          // Filtre avancé avec badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.textPrimary),
                tooltip: 'Filtres',
                onPressed: _showFilterSheet,
              ),
              if (filters.activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.badge,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${filters.activeFilterCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Tri
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.textPrimary),
            onSelected: (s) => ref.read(jobFiltersProvider.notifier).setSort(s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'date_desc', child: Text('Plus récents')),
              PopupMenuItem(value: 'date_asc', child: Text('Plus anciens')),
              PopupMenuItem(value: 'price_asc', child: Text('Moins cher')),
              PopupMenuItem(value: 'price_desc', child: Text('Plus cher')),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: const Icon(
                Icons.person,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Barre de recherche ──────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.sm,
                      AppSizes.md,
                      0,
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un service...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  ref
                                      .read(jobFiltersProvider.notifier)
                                      .setSearch(null);
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── Chips filtres actifs ────────────────────────────────────
          if (filters.hasActiveFilters)
            _ActiveFilterChips(
              filters: filters,
              onRemoveCategory: () =>
                  ref.read(jobFiltersProvider.notifier).setCategory(null),
              onRemoveLocation: () =>
                  ref.read(jobFiltersProvider.notifier).setLocation(null),
              onRemoveSearch: () {
                _searchCtrl.clear();
                ref.read(jobFiltersProvider.notifier).setSearch(null);
              },
              onRemovePrice: () => ref
                  .read(jobFiltersProvider.notifier)
                  .setPriceRange(null, null),
              onClearAll: () {
                _searchCtrl.clear();
                setState(() => _showSearch = false);
                ref.read(jobFiltersProvider.notifier).reset();
              },
            ),

          // ── Titre ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jobs',
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
          const SizedBox(height: AppSizes.sm),

          // ── Liste des jobs ──────────────────────────────────────────
          Expanded(
            child: jobsAsync.when(
              loading: () => const AppLoading(),
              error: (e, _) => AppError(
                message: e.toString(),
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
                  onRefresh: () async => ref.invalidate(availableJobsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.md,
                      AppSizes.xs,
                      AppSizes.md,
                      AppSizes.md,
                    ),
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const CreateJobPage()),
          );
          if (created == true) ref.invalidate(availableJobsProvider);
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Active filter chips bar ───────────────────────────────────────────────
class _ActiveFilterChips extends StatelessWidget {
  final JobFilters filters;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemoveLocation;
  final VoidCallback onRemoveSearch;
  final VoidCallback onRemovePrice;
  final VoidCallback onClearAll;

  const _ActiveFilterChips({
    required this.filters,
    required this.onRemoveCategory,
    required this.onRemoveLocation,
    required this.onRemoveSearch,
    required this.onRemovePrice,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        0,
      ),
      child: Row(
        children: [
          // Tout effacer
          _FilterChip(
            label: 'Tout effacer',
            icon: Icons.close,
            color: AppColors.error,
            onRemove: onClearAll,
          ),
          const SizedBox(width: AppSizes.xs),

          if (filters.categoryId != null) ...[
            _FilterChip(
              label: 'Catégorie',
              icon: Icons.category_outlined,
              color: AppColors.primary,
              onRemove: onRemoveCategory,
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          if (filters.location != null && filters.location!.isNotEmpty) ...[
            _FilterChip(
              label: filters.location!,
              icon: Icons.location_on_outlined,
              color: const Color(0xFF0EA5E9),
              onRemove: onRemoveLocation,
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          if (filters.q != null && filters.q!.isNotEmpty) ...[
            _FilterChip(
              label: '"${filters.q}"',
              icon: Icons.search,
              color: const Color(0xFF8B5CF6),
              onRemove: onRemoveSearch,
            ),
            const SizedBox(width: AppSizes.xs),
          ],
          if (filters.minPrice != null || filters.maxPrice != null) ...[
            _FilterChip(
              label:
                  '${filters.minPrice?.toStringAsFixed(0) ?? '0'} – ${filters.maxPrice?.toStringAsFixed(0) ?? '∞'} FCFA',
              icon: Icons.sell_outlined,
              color: AppColors.price,
              onRemove: onRemovePrice,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late TextEditingController _locationCtrl;
  late double _minPrice;
  late double _maxPrice;
  bool _priceEnabled = false;

  static const double _priceMax = 500000;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(jobFiltersProvider);
    _locationCtrl = TextEditingController(text: filters.location ?? '');
    _minPrice = filters.minPrice ?? 0;
    _maxPrice = filters.maxPrice ?? _priceMax;
    _priceEnabled = filters.minPrice != null || filters.maxPrice != null;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(jobFiltersProvider.notifier);
    notifier.setLocation(
      _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
    );
    if (_priceEnabled) {
      notifier.setPriceRange(
        _minPrice == 0 ? null : _minPrice,
        _maxPrice == _priceMax ? null : _maxPrice,
      );
    } else {
      notifier.setPriceRange(null, null);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.md,
          AppSizes.lg,
          AppSizes.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref.read(jobFiltersProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Tout effacer',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // ── Lieu ───────────────────────────────────────────────
            const _SheetLabel('VILLE / QUARTIER'),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: 'ex: Akwa, Douala',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                suffixIcon: _locationCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          _locationCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.sm),
            // Suggestions rapides
            Wrap(
              spacing: AppSizes.xs,
              children: _cameroonCities.map((city) {
                final isSelected = _locationCtrl.text == city;
                return GestureDetector(
                  onTap: () => setState(() => _locationCtrl.text = city),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      city,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Prix ───────────────────────────────────────────────
            Row(
              children: [
                const _SheetLabel('FOURCHETTE DE PRIX'),
                const Spacer(),
                Switch(
                  value: _priceEnabled,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  onChanged: (v) => setState(() => _priceEnabled = v),
                ),
              ],
            ),
            if (_priceEnabled) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_minPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _maxPrice >= _priceMax
                        ? 'Sans limite'
                        : '${_maxPrice.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(_minPrice, _maxPrice),
                min: 0,
                max: _priceMax,
                divisions: 100,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.primary.withValues(alpha: 0.2),
                onChanged: (v) => setState(() {
                  _minPrice = v.start;
                  _maxPrice = v.end;
                }),
              ),
              // Valeurs rapides
              Wrap(
                spacing: AppSizes.xs,
                children: const [
                  _QuickPrice(label: '< 5 000', min: 0, max: 5000),
                  _QuickPrice(label: '5K – 20K', min: 5000, max: 20000),
                  _QuickPrice(label: '20K – 50K', min: 20000, max: 50000),
                  _QuickPrice(label: '> 50 000', min: 50000, max: null),
                ],
              ),
            ],
            const SizedBox(height: AppSizes.xl),

            // ── Bouton Appliquer ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                ),
                child: const Text(
                  'Appliquer les filtres',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPrice extends ConsumerWidget {
  final String label;
  final double min;
  final double? max;

  const _QuickPrice({required this.label, required this.min, this.max});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // find parent state through InheritedWidget is complex; use setState via callback
        // Instead we communicate via a local callback approach
        // Simpler: just apply directly through notifier
        ref
            .read(jobFiltersProvider.notifier)
            .setPriceRange(min == 0 ? null : min, max);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.xs),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}
