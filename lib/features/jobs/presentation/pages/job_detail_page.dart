import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../messages/data/repository/messages_repository.dart';
import '../../../messages/presentation/pages/chat_page.dart';
import '../providers/jobs_provider.dart';

class JobDetailPage extends ConsumerWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: jobAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: error.toString(),
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
        data: (job) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.arrow_back,
                        color: AppColors.textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.share_outlined,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.bookmark_outline,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: job.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl:
                              '${ApiConstants.baseUrl}${job.images.first}',
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image,
                                size: 48, color: AppColors.textHint),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.work_outline,
                              size: 64, color: AppColors.textHint),
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSizes.sm),

                      // Tags
                      Wrap(spacing: AppSizes.sm, children: [
                        _Tag(
                          icon: Icons.sell_outlined,
                          label:
                              '${job.price.toStringAsFixed(0)} FCFA',
                          color: AppColors.price,
                        ),
                        if (job.isPending)
                          const _Tag(
                            icon: Icons.access_time,
                            label: 'Disponible',
                            color: AppColors.success,
                          ),
                        if (job.isInProgress)
                          const _Tag(
                            icon: Icons.engineering,
                            label: 'En cours',
                            color: AppColors.warning,
                          ),
                        if (job.isDone)
                          const _Tag(
                            icon: Icons.check_circle_outline,
                            label: 'Terminé',
                            color: AppColors.textSecondary,
                          ),
                      ]),
                      const SizedBox(height: AppSizes.md),

                      // Location + date
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(job.location,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                        const SizedBox(width: AppSizes.md),
                        const Icon(Icons.access_time,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(job.timeAgo,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: AppSizes.lg),
                      const Divider(),
                      const SizedBox(height: AppSizes.lg),

                      // Creator card
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.surface,
                            child: Text(
                              job.creatorUsername.isNotEmpty
                                  ? job.creatorUsername[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(job.creatorUsername,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                                Text('Douala, Cameroun',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textSecondary),
                        ]),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Description
                      const Text('Description de la mission',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        job.description ??
                            'Aucune description fournie.',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Category chip
                      if (job.categoryName != null) ...[
                        const Text('COMPÉTENCES REQUISES',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6)),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(spacing: AppSizes.sm, children: [
                          Chip(
                            label: Text(job.categoryName!),
                            backgroundColor: AppColors.surfaceVariant,
                            side: BorderSide.none,
                          ),
                        ]),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),

      // ── Bottom action bar ─────────────────────────────────────────────
      bottomNavigationBar: jobAsync.valueOrNull != null
          ? _BottomBar(
              job: jobAsync.value!,
              isOwner: currentUser?.username ==
                  jobAsync.value!.creatorUsername,
              isKycVerified: currentUser?.isKycVerified ?? false,
              onApply: () => _startConversation(context, ref,
                  jobAsync.value!.id, jobAsync.value!.creatorUsername),
            )
          : null,
    );
  }

  Future<void> _startConversation(BuildContext context, WidgetRef ref,
      String jobId, String creatorUsername) async {
    try {
      final repo = ref.read(messagesRepositoryProvider);
      final msg = await repo.startConversation(
        jobId: jobId,
        content: 'Bonjour, je suis intéressé(e) par votre annonce.',
      );
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: msg.conversationId,
          otherUsername: creatorUsername,
          otherUserId: msg.receiverId,
        ),
      ));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final dynamic job;
  final bool isOwner;
  final bool isKycVerified;
  final VoidCallback onApply;

  const _BottomBar({
    required this.job,
    required this.isOwner,
    required this.isKycVerified,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (isOwner) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: ElevatedButton(
              onPressed: job.isPending
                  ? (isKycVerified
                      ? onApply
                      : null)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.textHint.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusLg)),
                minimumSize:
                    const Size(double.infinity, AppSizes.buttonHeight),
              ),
              child: Text(
                job.isPending
                    ? (isKycVerified ? 'Postuler' : 'KYC requis')
                    : (job.isInProgress ? 'En cours' : 'Terminé'),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            height: AppSizes.buttonHeight,
            width: AppSizes.buttonHeight,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline,
                  color: AppColors.primary),
              onPressed: onApply,
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}
