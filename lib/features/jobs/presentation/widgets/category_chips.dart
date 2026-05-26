import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../providers/jobs_provider.dart';

class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final filters = ref.watch(jobFiltersProvider);
    final selectedId = filters.categoryId;

    return SizedBox(
      height: 40,
      child: categoriesAsync.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (categories) {
          final items = [
            _ChipData(id: null, name: 'Tous'),
            ...categories.map(
              (c) => _ChipData(id: c['id'] as String, name: c['name'] as String),
            ),
          ];

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
            itemBuilder: (context, index) {
              final item = items[index];
              final isSelected = selectedId == item.id;

              return FilterChip(
                selected: isSelected,
                label: Text(item.name),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                showCheckmark: false,
                onSelected: (_) {
                  ref
                      .read(jobFiltersProvider.notifier)
                      .setCategory(item.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ChipData {
  final String? id;
  final String name;
  const _ChipData({required this.id, required this.name});
}
