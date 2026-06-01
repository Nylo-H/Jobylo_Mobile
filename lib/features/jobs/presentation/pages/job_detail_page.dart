import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/error_handler.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../applications/data/repository/applications_repository.dart';
import '../../../applications/presentation/pages/applicants_page.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../messages/data/repository/messages_repository.dart';
import '../../../messages/presentation/pages/chat_page.dart';
import '../../../payments/data/repository/payments_repository.dart';
import '../../../payments/presentation/providers/payments_provider.dart';
import '../../../ratings/data/repository/ratings_repository.dart';
import '../../../users/presentation/providers/users_provider.dart';
import '../../data/repository/jobs_repository.dart';
import '../../domain/entities/job.dart';
import '../providers/jobs_provider.dart';
import 'edit_job_page.dart';

class JobDetailPage extends ConsumerWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final myApp = ref.watch(myApplicationForJobProvider(jobId));
    final countAsync = ref.watch(applicantsCountProvider(jobId));
    final jobPayment = ref.watch(jobPaymentProvider(jobId));

    return Scaffold(
      body: jobAsync.when(
        loading: () => const AppLoading(),
        error: (e, _) => AppError(
          message: e.toString(),
          onRetry: () => ref.invalidate(jobDetailProvider(jobId)),
        ),
        data: (job) {
          final isOwner = currentUser?.id == job.creatorId ||
              currentUser?.username == job.creatorUsername;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(jobDetailProvider(jobId));
              ref.invalidate(applicantsCountProvider(jobId));
              ref.invalidate(jobPaymentProvider(jobId));
            },
            child: CustomScrollView(
            slivers: [
              // ── Image header ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 250,
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
                  // Bouton Modifier (créateur + PENDING)
                  if (isOwner && job.isPending)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () async {
                          final edited =
                              await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) => EditJobPage(job: job)),
                          );
                          if (edited == true) {
                            ref.invalidate(jobDetailProvider(jobId));
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('Modifier',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Bouton Supprimer (créateur + PENDING)
                  if (isOwner && job.isPending)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _confirmDelete(context, ref, job),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusSm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline,
                                  size: 16, color: AppColors.error),
                              SizedBox(width: 4),
                              Text('Supprimer',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.error)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: job.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: job.fullImageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image, size: 48),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.work_outline, size: 64),
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
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSizes.sm),
                      Wrap(spacing: AppSizes.sm, children: [
                        _Tag(
                          icon: Icons.sell_outlined,
                          label: '${job.price.toStringAsFixed(0)} FCFA',
                          color: AppColors.price,
                        ),
                        _Tag(
                          icon: _statusIcon(job.status),
                          label: _statusLabel(job.status),
                          color: _statusColor(job.status),
                        ),
                      ]),
                      const SizedBox(height: AppSizes.md),
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

                      // ── Créateur card avec note ──────────────────
                      _UserCard(
                        userId: job.creatorId,
                        username: job.creatorUsername,
                        photoUrl: job.creatorPhotoUrl,
                        rating: job.creatorRating,
                        totalRatings: job.creatorTotalRatings,
                        label: 'Créateur',
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // ── Date limite & countdown ───────────────────
                      if (job.applicationDeadline != null && job.isPending)
                        _DeadlineBanner(job: job),
                      if (job.applicationDeadline != null && job.isPending)
                        const SizedBox(height: AppSizes.lg),

                      // ── EXPIRED banner ────────────────────────────
                      if (job.isExpired)
                        Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: AppColors.textHint.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(
                                color: AppColors.textHint.withValues(alpha: 0.3)),
                          ),
                          child: const Row(children: [
                            Icon(Icons.block, color: AppColors.textHint, size: 18),
                            SizedBox(width: AppSizes.sm),
                            Text('Candidatures fermées',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHint)),
                          ]),
                        ),
                      if (job.isExpired) const SizedBox(height: AppSizes.lg),

                      // ── Candidatures card (créateur + PENDING) ────
                      if (isOwner && job.isPending)
                        _ApplicantsCard(
                          jobId: jobId,
                          jobTitle: job.title,
                          count: countAsync.valueOrNull ?? 0,
                        ),
                      if (isOwner && job.isPending)
                        const SizedBox(height: AppSizes.lg),

                      // ── Bouton Expirer (créateur + PENDING) ───────
                      if (isOwner && job.isPending)
                        _ExpireButton(jobId: jobId),
                      if (isOwner && job.isPending)
                        const SizedBox(height: AppSizes.lg),

                      // ── Worker assigné ────────────────────────────
                      if (job.workerUsername != null &&
                          job.workerUsername!.isNotEmpty) ...[
                        _UserCard(
                          userId: job.workerId ?? '',
                          username: job.workerUsername!,
                          rating: job.workerRating,
                          totalRatings: job.workerTotalRatings,
                          label: 'Worker assigné',
                          labelColor: AppColors.success,
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // ── Paiement banner ───────────────────────────
                      if (job.isDone && jobPayment != null)
                        _PaymentBanner(payment: jobPayment, isOwner: isOwner),
                      if (job.isDone && jobPayment != null)
                        const SizedBox(height: AppSizes.lg),

                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        job.description ?? 'Aucune description.',
                        style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      if (job.categoryName != null) ...[
                        const Text('CATÉGORIE',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.6)),
                        const SizedBox(height: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.category_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                job.categoryName!,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),

      bottomNavigationBar: jobAsync.valueOrNull != null
          ? _BottomActions(
              job: jobAsync.value!,
              isOwner: currentUser?.id == jobAsync.value!.creatorId ||
                  currentUser?.username == jobAsync.value!.creatorUsername,
              isWorker: currentUser?.id == jobAsync.value!.workerId ||
                  currentUser?.username == jobAsync.value!.workerUsername,
              isKycVerified: currentUser?.isKycVerified ?? false,
              myApplication: myApp,
              jobId: jobId,
              jobPayment: ref.watch(jobPaymentProvider(jobId)),
            )
          : null,
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Job job) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette annonce ?'),
        content: const Text(
          'Cette action est irréversible. Les candidatures seront supprimées.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      // Backend ne supporte pas CANCELLED → on expire le job (ferme les candidatures)
      await ref
          .read(jobsRepositoryProvider)
          .updateJobStatus(job.id, 'EXPIRED');
      ref.invalidate(myCreatedJobsProvider);
      ref.invalidate(availableJobsProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }

  static IconData _statusIcon(String s) {
    switch (s) {
      case 'PENDING':
        return Icons.access_time;
      case 'IN_PROGRESS':
        return Icons.engineering;
      case 'DONE':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'PENDING':
        return 'Disponible';
      case 'IN_PROGRESS':
        return 'En cours';
      case 'DONE':
        return 'Terminé';
      default:
        return s;
    }
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'PENDING':
        return AppColors.success;
      case 'IN_PROGRESS':
        return AppColors.warning;
      case 'DONE':
        return AppColors.textSecondary;
      default:
        return AppColors.textHint;
    }
  }
}

// ── Payment banner (top of content, status info) ──────────────────────────
class _PaymentBanner extends StatelessWidget {
  final dynamic payment;
  final bool isOwner;

  const _PaymentBanner({required this.payment, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final isCompleted = payment.isCompleted;
    final color = isCompleted ? AppColors.success : AppColors.warning;
    final icon = isCompleted ? Icons.check_circle : Icons.hourglass_top;
    final label = isCompleted
        ? (isOwner
            ? 'Paiement effectué — ${payment.netAmount.toStringAsFixed(0)} FCFA versés'
            : 'Paiement reçu — ${payment.netAmount.toStringAsFixed(0)} FCFA')
        : (isOwner
            ? 'Paiement en attente de confirmation'
            : 'En attente de confirmation du paiement');

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ),
      ]),
    );
  }
}

// ── Applicants card ────────────────────────────────────────────────────────
class _ApplicantsCard extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final int count;

  const _ApplicantsCard({
    required this.jobId,
    required this.jobTitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ApplicantsPage(jobId: jobId, jobTitle: jobTitle),
      )),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border:
              Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Voir les $count candidature${count != 1 ? 's' : ''}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.primary),
        ]),
      ),
    );
  }
}

// ── Bottom actions ─────────────────────────────────────────────────────────
class _BottomActions extends ConsumerWidget {
  final Job job;
  final bool isOwner;
  final bool isWorker;
  final bool isKycVerified;
  final dynamic myApplication;
  final String jobId;
  final dynamic jobPayment;

  const _BottomActions({
    required this.job,
    required this.isOwner,
    required this.isWorker,
    required this.isKycVerified,
    required this.myApplication,
    required this.jobId,
    required this.jobPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(child: _buildActions(context, ref)),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    // ── DONE ──────────────────────────────────────────────────────────
    if (job.isDone) {
      final paymentCompleted = jobPayment?.isCompleted ?? false;
      final paymentHeld = jobPayment != null && !paymentCompleted;

      return Row(children: [
        // Créateur : Payer → Confirmer → (déjà payé)
        if (isOwner) ...[
          if (jobPayment == null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pay(context, ref),
                icon: const Icon(Icons.payment, size: 18, color: Colors.white),
                label: const Text('Payer le worker',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
              ),
            )
          else if (paymentHeld)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirmPayment(context, ref),
                icon: const Icon(Icons.check_circle_outline,
                    size: 18, color: Colors.white),
                label: const Text('Confirmer le paiement',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size(0, AppSizes.buttonHeight),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                height: AppSizes.buttonHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    SizedBox(width: 6),
                    Text('Paiement effectué',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ],
                ),
              ),
            ),
          const SizedBox(width: AppSizes.sm),
        ],

        // Worker : En attente ou paiement reçu
        if (isWorker) ...[
          Expanded(
            child: Container(
              height: AppSizes.buttonHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: paymentCompleted
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: paymentCompleted
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    paymentCompleted
                        ? Icons.check_circle
                        : Icons.hourglass_top,
                    size: 16,
                    color: paymentCompleted
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paymentCompleted
                        ? 'Paiement reçu ✓'
                        : 'En attente du paiement',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: paymentCompleted
                            ? AppColors.success
                            : AppColors.warning),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
        ],

        // Both can rate
        ElevatedButton.icon(
          onPressed: () => _rate(context, ref),
          icon: const Icon(Icons.star_outline, size: 18, color: Colors.white),
          label: const Text('Noter',
              style: TextStyle(color: Colors.white, fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            minimumSize: const Size(0, AppSizes.buttonHeight),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
          ),
        ),
      ]);
    }

    // ── IN_PROGRESS → Marquer DONE + Chat ──────────────────────────
    if (job.isInProgress && (isOwner || isWorker)) {
      return Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _markDone(context, ref),
            icon: const Icon(Icons.check_circle_outline,
                size: 18, color: Colors.white),
            label: const Text('Marquer terminé',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        _chatButton(context, ref),
      ]);
    }

    // ── PENDING → Postuler (non-créateur) ──────────────────────────
    if (job.isPending && !isOwner) {
      return Row(children: [
        Expanded(child: _applyButton(context, ref)),
        const SizedBox(width: AppSizes.sm),
        _chatButton(context, ref),
      ]);
    }

    return const SizedBox.shrink();
  }

  Widget _applyButton(BuildContext context, WidgetRef ref) {
    if (myApplication == null) {
      return ElevatedButton.icon(
        onPressed: isKycVerified ? () => _showApplySheet(context, ref) : null,
        icon: const Icon(Icons.check, size: 18, color: Colors.white),
        label: Text(
          isKycVerified ? 'Postuler' : 'KYC requis',
          style: const TextStyle(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.textHint.withValues(alpha: 0.3),
          minimumSize: const Size(0, AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        ),
      );
    }

    final color = myApplication.isPending
        ? AppColors.warning
        : myApplication.isAccepted
            ? AppColors.success
            : AppColors.error;

    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color,
        minimumSize: const Size(0, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      ),
      child: Text(myApplication.statusLabel,
          style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _chatButton(BuildContext context, WidgetRef ref) {
    return Container(
      height: AppSizes.buttonHeight,
      width: AppSizes.buttonHeight,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: IconButton(
        icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
        onPressed: () => _startChat(context, ref),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _startChat(BuildContext context, WidgetRef ref) async {
    try {
      final msg = await ref.read(messagesRepositoryProvider).startConversation(
            jobId: jobId,
            content: 'Bonjour !',
          );
      if (!context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: msg.conversationId,
          otherUsername: job.creatorUsername,
          otherUserId: msg.receiverId,
          jobId: jobId,
          jobTitle: job.title,
        ),
      ));
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }

  void _showApplySheet(BuildContext context, WidgetRef ref) {
    final coverCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppSizes.radiusXl)),
          ),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: AppSizes.md),
              const Text("Postuler à l'offre",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSizes.lg),
              TextField(
                controller: coverCtrl,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Message au créateur (optionnel)...',
                ),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(applicationsRepositoryProvider)
                          .applyToJob(
                            jobId: jobId,
                            coverLetter:
                                coverCtrl.text.trim().isNotEmpty
                                    ? coverCtrl.text.trim()
                                    : null,
                          );
                      ref.invalidate(myApplicationsProvider);
                      ref.invalidate(applicantsCountProvider(jobId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                          content: Text('Candidature envoyée !'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ErrorHandler.handle(
                          context,
                          e is ApiException
                              ? e
                              : ApiException(message: e.toString()),
                        );
                      }
                    }
                  },
                  child: const Text('Envoyer ma candidature',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markDone(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marquer comme terminé ?'),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(jobsRepositoryProvider).updateJobStatus(jobId, 'DONE');
      ref.invalidate(jobDetailProvider(jobId));
      ref.invalidate(myCreatedJobsProvider);
      ref.invalidate(myAssignedJobsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Job marqué terminé !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payer le worker ?'),
        content: Text(
          'Montant : ${job.price.toStringAsFixed(0)} FCFA\n'
          'Le worker recevra : ${(job.price * 0.95).toStringAsFixed(0)} FCFA\n'
          '(Commission plateforme : 5%)',
          style: const TextStyle(
              color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirmer le paiement',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final payment =
          await ref.read(paymentsRepositoryProvider).initiatePayment(jobId);
      // Mise à jour directe du state sans re-fetch réseau
      ref.read(myPaymentsProvider.notifier).addPayment(payment);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paiement initié ! Confirmez pour finaliser.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }

  Future<void> _confirmPayment(BuildContext context, WidgetRef ref) async {
    if (jobPayment == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer le paiement ?'),
        content: Text(
          'Les fonds seront versés définitivement au worker.\n'
          'Montant : ${jobPayment.netAmount.toStringAsFixed(0)} FCFA',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final updated = await ref
          .read(paymentsRepositoryProvider)
          .confirmPayment(jobPayment.id);
      // Mise à jour directe du paiement sans re-fetch
      ref.read(myPaymentsProvider.notifier).updatePayment(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Paiement confirmé ! ${updated.netAmount.toStringAsFixed(0)} FCFA versés.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final targetId = isOwner ? (job.workerId ?? '') : job.creatorId;
    final targetName =
        isOwner ? (job.workerUsername ?? 'Worker') : job.creatorUsername;
    if (targetId.isEmpty) return;

    int score = 5;
    final commentCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Noter $targetName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    5,
                    (i) => IconButton(
                          icon: Icon(
                            i < score ? Icons.star : Icons.star_border,
                            color: const Color(0xFFF59E0B),
                            size: 32,
                          ),
                          onPressed: () => setState(() => score = i + 1),
                        )),
              ),
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: commentCtrl,
                maxLines: 2,
                maxLength: 500,
                decoration: const InputDecoration(
                    hintText: 'Commentaire (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B)),
              child: const Text('Soumettre',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(ratingsRepositoryProvider).submitRating(
            jobId: jobId,
            targetUserId: targetId,
            score: score,
            comment: commentCtrl.text.trim().isNotEmpty
                ? commentCtrl.text.trim()
                : null,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Note envoyée !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Tag({required this.icon, required this.label, required this.color});

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

// ── User card (créateur ou worker) avec note ──────────────────────────────
class _UserCard extends ConsumerWidget {
  final String userId;
  final String username;
  final String? photoUrl;
  final double? rating;
  final int? totalRatings;
  final String label;
  final Color? labelColor;

  const _UserCard({
    required this.userId,
    required this.username,
    this.photoUrl,
    this.rating,
    this.totalRatings,
    required this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to load fresh data from the API if we don't have rating info
    final userAsync = (rating == null && userId.isNotEmpty)
        ? ref.watch(publicUserProvider(userId))
        : null;

    final displayRating = rating ??
        userAsync?.valueOrNull?.averageRating;
    final displayTotal = totalRatings ??
        userAsync?.valueOrNull?.totalRatings;
    final displayName = username.isNotEmpty ? username : '?';
    final initial = displayName[0].toUpperCase();
    final color = labelColor ?? AppColors.primary;

    return GestureDetector(
      onTap: userId.isNotEmpty
          ? () => context.push('/user/$userId')
          : null,
      child: Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(initial,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: color)),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
              const SizedBox(height: 3),
              Text(displayName,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              // Rating row
              if (displayRating != null)
                Row(children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < displayRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      size: 14,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${displayRating.toStringAsFixed(1)}'
                    '${displayTotal != null ? ' ($displayTotal avis)' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ])
              else if (userAsync?.isLoading == true)
                const SizedBox(
                  height: 14,
                  width: 80,
                  child: LinearProgressIndicator(
                      color: AppColors.primary, minHeight: 2),
                )
              else
                const Text('Pas encore noté',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textHint)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ]),
      ),
    );
  }
}

// ── Deadline banner avec countdown ───────────────────────────────────────
class _DeadlineBanner extends StatefulWidget {
  final Job job;
  const _DeadlineBanner({required this.job});

  @override
  State<_DeadlineBanner> createState() => _DeadlineBannerState();
}

class _DeadlineBannerState extends State<_DeadlineBanner> {
  late final _timer = Stream.periodic(const Duration(minutes: 1))
      .listen((_) => setState(() {}));

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deadline = widget.job.applicationDeadline!;
    final expired = deadline.isBefore(DateTime.now());
    final color = expired ? AppColors.warning : AppColors.primary;
    final icon = expired ? Icons.timer_off : Icons.timer_outlined;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expired
                    ? 'Date limite dépassée'
                    : 'Date limite de candidature',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              Text(
                widget.job.deadlineCountdown,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        ),
        Text(
          '${deadline.day.toString().padLeft(2, '0')}/${deadline.month.toString().padLeft(2, '0')}/${deadline.year}',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ]),
    );
  }
}

// ── Expire button (créateur seulement) ───────────────────────────────────
class _ExpireButton extends ConsumerWidget {
  final String jobId;
  const _ExpireButton({required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmExpire(context, ref),
      icon: const Icon(Icons.timer_off, size: 16, color: AppColors.warning),
      label: const Text('Expirer l\'annonce',
          style: TextStyle(fontSize: 13, color: AppColors.warning)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.warning.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
      ),
    );
  }

  Future<void> _confirmExpire(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Expirer l\'annonce ?'),
        content: const Text(
          'Les candidatures seront fermées. Les candidats en attente seront notifiés.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning),
            child: const Text('Expirer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      // POST /jobs/{id}/expire
      await ref.read(jobsRepositoryProvider).updateJobStatus(jobId, 'EXPIRED');
      ref.invalidate(jobDetailProvider(jobId));
      ref.invalidate(myCreatedJobsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Annonce expirée.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.handle(
          context,
          e is ApiException ? e : ApiException(message: e.toString()),
        );
      }
    }
  }
}
