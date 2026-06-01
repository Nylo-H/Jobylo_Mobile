import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_error.dart';
import '../../../../shared/widgets/app_empty.dart';
import '../../domain/entities/application.dart';
import '../providers/applications_provider.dart';

/// [standalone] = true  → renders with its own Scaffold + AppBar (standalone route)
/// [standalone] = false → renders as bare content inside a TabBarView
class MyApplicationsPage extends ConsumerWidget {
  final bool standalone;
  const MyApplicationsPage({super.key, this.standalone = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    Widget content = applicationsAsync.when(
      loading: () => const AppLoading(),
      error: (e, _) => AppError(
        message: e.toString(),
        onRetry: () => ref.read(myApplicationsProvider.notifier).refresh(),
      ),
      data: (applications) {
        if (applications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(myApplicationsProvider.notifier).refresh(),
            child: const AppEmpty(
              message: 'Vous n\'avez encore postulé à aucune annonce.',
              icon: Icons.inbox_outlined,
            ),
          );
        }

        final pending = applications.where((a) => a.isPending).toList();
        final accepted = applications.where((a) => a.isAccepted).toList();
        final rejected =
            applications.where((a) => a.isRejected || a.isCancelled).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(myApplicationsProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.md),
            children: [
              if (pending.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.hourglass_top,
                  label: 'En attente',
                  count: pending.length,
                  color: AppColors.warning,
                ),
                const SizedBox(height: AppSizes.sm),
                ...pending.map((a) => _ApplicationTile(app: a)),
                const SizedBox(height: AppSizes.lg),
              ],
              if (accepted.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.check_circle_outline,
                  label: 'Acceptées',
                  count: accepted.length,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSizes.sm),
                ...accepted.map((a) => _ApplicationTile(app: a)),
                const SizedBox(height: AppSizes.lg),
              ],
              if (rejected.isNotEmpty) ...[
                _SectionHeader(
                  icon: Icons.cancel_outlined,
                  label: 'Refusées',
                  count: rejected.length,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: AppSizes.sm),
                ...rejected.map((a) => _ApplicationTile(app: a, dimmed: true)),
              ],
            ],
          ),
        );
      },
    );

    if (!standalone) return content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes candidatures'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
        ),
      ]),
    );
  }
}

// ── Application tile ──────────────────────────────────────────────────────
class _ApplicationTile extends StatelessWidget {
  final Application app;
  final bool dimmed;

  const _ApplicationTile({required this.app, this.dimmed = false});

  Color get _statusColor {
    switch (app.status) {
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

  IconData get _statusIcon {
    switch (app.status) {
      case 'PENDING':
        return Icons.hourglass_top;
      case 'ACCEPTED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'CANCELLED':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: ListTile(
          onTap: () => context.push('/jobs/${app.jobId}'),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: AppSizes.xs),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(_statusIcon, color: _statusColor, size: 22),
          ),
          title: Text(
            app.jobTitle ?? 'Annonce supprimée',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(children: [
                if (app.jobPrice != null) ...[
                  Text(
                    '${app.jobPrice!.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.price),
                  ),
                  const SizedBox(width: AppSizes.sm),
                ],
                Text(
                  app.timeAgo,
                  style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ]),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text(
                  app.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right,
              color: AppColors.textHint, size: 20),
        ),
      ),
    );
  }
}
