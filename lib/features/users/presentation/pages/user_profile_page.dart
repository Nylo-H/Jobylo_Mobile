import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../ratings/presentation/pages/my_ratings_page.dart';
import '../../../ratings/presentation/providers/ratings_provider.dart';
import '../providers/users_provider.dart';

class UserProfilePage extends ConsumerWidget {
  final String userId;
  const UserProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(publicUserProvider(userId));
    final ratingsAsync = ref.watch(userRatingsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: userAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(publicUserProvider(userId)),
        ),
        data: (user) {
          final initial = user.username.isNotEmpty
              ? user.username[0].toUpperCase()
              : '?';

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(publicUserProvider(userId));
              ref.invalidate(userRatingsProvider(userId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.md),
              children: [
                const SizedBox(height: AppSizes.lg),
                // ── Avatar + info ─────────────────────────────────────
                Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Center(
                  child: Text(
                    user.username,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                if (user.firstName != null || user.lastName != null) ...[
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim(),
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.sm),

                // ── Rating summary ─────────────────────────────────────
                if (user.averageRating != null && user.totalRatings != null)
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < user.averageRating!.round()
                                ? Icons.star
                                : Icons.star_border,
                            color: const Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${user.averageRating!.toStringAsFixed(1)} (${user.totalRatings} avis)',
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                // ── KYC badge ─────────────────────────────────────────
                if (user.kycStatus == 'VERIFIED') ...[
                  const SizedBox(height: AppSizes.sm),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user,
                              size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('Vérifié',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSizes.xl),
                const Divider(),
                const SizedBox(height: AppSizes.md),

                // ── Ratings section ────────────────────────────────────
                const Text(
                  'Évaluations reçues',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.md),

                ratingsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSizes.lg),
                    child: Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Text('Erreur: $e',
                      style: const TextStyle(color: AppColors.error)),
                  data: (ratings) {
                    if (ratings.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
                        child: Center(
                          child: Text(
                            'Aucune évaluation pour le moment.',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textHint),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: ratings
                          .map((r) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.sm),
                                child: RatingCard(rating: r),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
