import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../features/jobs/presentation/providers/jobs_provider.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../domain/entities/application.dart';
import '../providers/applications_provider.dart';

class ApplicantsPage extends ConsumerWidget {
  final String jobId;
  final String jobTitle;

  const ApplicantsPage({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncApplicants = ref.watch(jobApplicantsProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text(jobTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: asyncApplicants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) {
          debugPrint('=== APPLICANTS ERROR ===');
          debugPrint('$e');
          debugPrint('$stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSizes.md),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: AppSizes.md),
                  ElevatedButton(
                    onPressed: () =>
                        ref.invalidate(jobApplicantsProvider(jobId)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (applicants) {
          debugPrint('=== APPLICANTS DATA: ${applicants.length} items ===');
          if (applicants.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(jobApplicantsProvider(jobId)),
              child: const AppEmpty(
                message: 'Aucune candidature pour le moment.',
                icon: Icons.group_off_outlined,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(jobApplicantsProvider(jobId)),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSizes.md),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                final app = applicants[index];
                debugPrint(
                    '=== BUILDING CARD $index: ${app.workerUsername} ===');
                return _buildCard(context, ref, app);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, WidgetRef ref, Application app) {
    final name = (app.workerUsername != null && app.workerUsername!.isNotEmpty)
        ? app.workerUsername!
        : 'Candidat';
    final initial = name[0].toUpperCase();
    final statusColor = _colorForStatus(app.status);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(initial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    if (app.timeAgo.isNotEmpty)
                      Text(app.timeAgo,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  app.statusLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor),
                ),
              ),
            ],
          ),

          // ── Cover letter ───────────────────────────────────────────
          if (app.coverLetter != null && app.coverLetter!.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                '« ${app.coverLetter} »',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // ── Actions ────────────────────────────────────────────────
          if (app.isPending) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reject(context, ref, app),
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.error),
                    label: const Text('Refuser',
                        style:
                            TextStyle(fontSize: 13, color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _assign(context, ref, app),
                    icon: const Icon(Icons.check,
                        size: 16, color: Colors.white),
                    label: const Text('Choisir',
                        style:
                            TextStyle(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _assign(
      BuildContext context, WidgetRef ref, Application app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer'),
        content: Text(
            'Choisir ${app.workerUsername ?? "ce candidat"} ?\nLes autres seront refusés automatiquement.'),
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
      await ref
          .read(jobApplicantsProvider(jobId).notifier)
          .assign(app.workerId);
      // Le job passe en IN_PROGRESS et le compteur change
      ref.invalidate(jobDetailProvider(jobId));
      ref.invalidate(applicantsCountProvider(jobId));
      ref.invalidate(myCreatedJobsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Candidat sélectionné !'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _reject(
      BuildContext context, WidgetRef ref, Application app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser ?'),
        content: Text(
            '${app.workerUsername ?? "Ce candidat"} sera notifié du refus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Refuser',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref
          .read(jobApplicantsProvider(jobId).notifier)
          .reject(app.workerId);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  static Color _colorForStatus(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'ACCEPTED':
        return AppColors.success;
      case 'REJECTED':
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }
}
