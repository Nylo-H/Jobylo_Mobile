import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../applications/presentation/pages/applicants_page.dart';
import '../../../applications/presentation/providers/applications_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../messages/data/repository/messages_repository.dart';
import '../../../messages/presentation/pages/chat_page.dart';
import '../../../applications/data/repository/applications_repository.dart';
import '../../../payments/data/repository/payments_repository.dart';
import '../../../ratings/data/repository/ratings_repository.dart';
import '../../data/repository/jobs_repository.dart';
import '../../domain/entities/job.dart';
import '../providers/jobs_provider.dart';

class JobDetailPage extends ConsumerWidget {
  final String jobId;
  const JobDetailPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final myApp = ref.watch(myApplicationForJobProvider(jobId));
    final countAsync = ref.watch(applicantsCountProvider(jobId));

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

          return CustomScrollView(
            slivers: [
              // ── Image header ───────────────────────────────────────
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
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.share_outlined,
                          color: AppColors.textPrimary, size: 20),
                    ),
                    onPressed: () {},
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

              // ── Content ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(job.title,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: AppSizes.sm),

                      // Tags
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

                      // Location + date
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(job.location,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(width: AppSizes.md),
                        const Icon(Icons.access_time,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(job.timeAgo,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ]),
                      const SizedBox(height: AppSizes.lg),
                      const Divider(),
                      const SizedBox(height: AppSizes.lg),

                      // ── Créateur info ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(AppSizes.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: Row(children: [
                          CircleAvatar(
                            radius: 22,
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
                                const Text('Cameroun',
                                    style: TextStyle(
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

                      // ── Candidatures (créateur only) ───────────────
                      if (isOwner && job.isPending)
                        _ApplicantsCard(
                          jobId: jobId,
                          jobTitle: job.title,
                          count: countAsync.valueOrNull ?? 0,
                        ),
                      if (isOwner && job.isPending)
                        const SizedBox(height: AppSizes.lg),

                      // ── Worker assigné (si IN_PROGRESS / DONE) ─────
                      if (job.workerUsername != null &&
                          job.workerUsername!.isNotEmpty) ...[
                        _InfoTile(
                          icon: Icons.engineering,
                          label: 'Worker assigné',
                          value: job.workerUsername!,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // ── Description ────────────────────────────────
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
                        Chip(
                          label: Text(job.categoryName!),
                          backgroundColor: AppColors.surfaceVariant,
                          side: BorderSide.none,
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      // ── Bottom action bar ──────────────────────────────────────────
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
            )
          : null,
    );
  }

  static IconData _statusIcon(String s) {
    switch (s) {
      case 'PENDING': return Icons.access_time;
      case 'IN_PROGRESS': return Icons.engineering;
      case 'DONE': return Icons.check_circle_outline;
      default: return Icons.info_outline;
    }
  }

  static String _statusLabel(String s) {
    switch (s) {
      case 'PENDING': return 'Disponible';
      case 'IN_PROGRESS': return 'En cours';
      case 'DONE': return 'Terminé';
      default: return s;
    }
  }

  static Color _statusColor(String s) {
    switch (s) {
      case 'PENDING': return AppColors.success;
      case 'IN_PROGRESS': return AppColors.warning;
      case 'DONE': return AppColors.textSecondary;
      default: return AppColors.textHint;
    }
  }
}

// ── Applicants card ───────────────────────────────────────────────────────
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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

// ── Info tile ─────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSizes.sm),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

// ── Bottom actions bar ────────────────────────────────────────────────────
class _BottomActions extends ConsumerWidget {
  final Job job;
  final bool isOwner;
  final bool isWorker;
  final bool isKycVerified;
  final dynamic myApplication;
  final String jobId;

  const _BottomActions({
    required this.job,
    required this.isOwner,
    required this.isWorker,
    required this.isKycVerified,
    required this.myApplication,
    required this.jobId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SafeArea(
        child: _buildActions(context, ref),
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    // ── DONE → Payer (worker) ou Noter ──────────────────────────────
    if (job.isDone) {
      return Row(children: [
        if (isWorker)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _pay(context, ref),
              icon: const Icon(Icons.payment, size: 18, color: Colors.white),
              label: const Text('Payer',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, AppSizes.buttonHeight),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
              ),
            ),
          ),
        if (isWorker) const SizedBox(width: AppSizes.sm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rate(context, ref),
            icon: const Icon(Icons.star_outline, size: 18, color: Colors.white),
            label: const Text('Noter',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              minimumSize: const Size(0, AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
            ),
          ),
        ),
      ]);
    }

    // ── IN_PROGRESS → Marquer DONE ──────────────────────────────────
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

    // ── PENDING → Postuler (worker) ou rien (owner) ─────────────────
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
    final label = myApplication.statusLabel;

    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color,
        minimumSize: const Size(0, AppSizes.buttonHeight),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
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
      if (context.mounted) _snack(context, e.toString(), isError: true);
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
                            coverLetter: coverCtrl.text.trim().isNotEmpty
                                ? coverCtrl.text.trim()
                                : null,
                          );
                      ref.invalidate(myApplicationsProvider);
                      ref.invalidate(applicantsCountProvider(jobId));
                      if (context.mounted) {
                        _snack(context, 'Candidature envoyée !');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        _snack(context, e.toString(), isError: true);
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
        content:
            const Text('Cette action est irréversible.'),
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
      if (context.mounted) _snack(context, 'Job marqué terminé !');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString(), isError: true);
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payer le créateur ?'),
        content: Text(
            'Montant : ${job.price.toStringAsFixed(0)} FCFA\n(Commission 5% déduite)'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Payer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final payment =
          await ref.read(paymentsRepositoryProvider).initiatePayment(jobId);
      // Auto-confirm (simple flow)
      await ref
          .read(paymentsRepositoryProvider)
          .confirmPayment(payment.id);
      if (context.mounted) {
        _snack(context,
            'Paiement confirmé ! ${payment.netAmount.toStringAsFixed(0)} FCFA versés.');
      }
    } catch (e) {
      if (context.mounted) _snack(context, e.toString(), isError: true);
    }
  }

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    final targetId =
        isOwner ? (job.workerId ?? '') : job.creatorId;
    final targetName = isOwner
        ? (job.workerUsername ?? 'Worker')
        : job.creatorUsername;

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
                children: List.generate(5, (i) => IconButton(
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
                  hintText: 'Commentaire (optionnel)',
                ),
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
      if (context.mounted) _snack(context, 'Note envoyée !');
    } catch (e) {
      if (context.mounted) _snack(context, e.toString(), isError: true);
    }
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Tag widget ────────────────────────────────────────────────────────────
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
