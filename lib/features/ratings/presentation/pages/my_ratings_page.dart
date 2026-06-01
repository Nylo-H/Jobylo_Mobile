import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../domain/entities/rating.dart';
import '../providers/ratings_provider.dart';

class MyRatingsPage extends ConsumerWidget {
  const MyRatingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(myRatingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes évaluations')),
      body: ratingsAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(myRatingsProvider),
        ),
        data: (ratings) {
          if (ratings.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(myRatingsProvider),
              child: const AppEmpty(
                message: 'Vous n\'avez pas encore reçu d\'évaluations.',
                icon: Icons.star_outline,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myRatingsProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: ratings.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (_, i) => RatingCard(rating: ratings[i]),
            ),
          );
        },
      ),
    );
  }
}

class RatingCard extends StatelessWidget {
  final Rating rating;
  const RatingCard({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    final initial = (rating.raterUsername ?? '?')[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.raterUsername ?? 'Utilisateur',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    if (rating.jobTitle != null)
                      Text(
                        rating.jobTitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textHint),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _buildStars(rating.score),
            ],
          ),
          if (rating.comment != null && rating.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '« ${rating.comment} »',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4),
              ),
            ),
          ],
          if (rating.createdAt != null) ...[
            const SizedBox(height: AppSizes.xs),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _formatDate(rating.createdAt!),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(int score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < score ? Icons.star : Icons.star_border,
          color: const Color(0xFFF59E0B),
          size: 16,
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
