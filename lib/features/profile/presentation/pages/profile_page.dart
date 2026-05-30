import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../auth/data/repository/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

// ── Logout confirmation ───────────────────────────────────────────────────
Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      title: const Text('Déconnexion',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: const Text(
        'Voulez-vous vraiment vous déconnecter ?',
        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
          ),
          child: const Text('Déconnecter',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(authStateProvider.notifier).logout();
  }
}

// ── Profile photo upload ──────────────────────────────────────────────────
Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
  final picker = ImagePicker();
  final file =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800);
  if (file == null) return;
  try {
    final user = await ref.read(authRepositoryProvider).uploadProfilePhoto(file.path);
    ref.read(authStateProvider.notifier).setUser(user);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Photo mise à jour !'),
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

// ── Page ──────────────────────────────────────────────────────────────────
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobylo'),
        leading: const SizedBox.shrink(),
        leadingWidth: 0,
      ),
      body: authState.when(
        loading: () => const AppLoading(),
        error: (_, _) => const Center(child: Text('Erreur')),
        data: (user) {
          if (user == null) return const SizedBox.shrink();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: AppSizes.lg),

                  // ── Avatar ───────────────────────────────────────────
                  GestureDetector(
                    onTap: () => _pickAndUploadPhoto(context, ref),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: AppSizes.avatarXl / 2,
                          backgroundColor: AppColors.surfaceVariant,
                          backgroundImage: user.photoProfile != null
                              ? CachedNetworkImageProvider(
                                  '${ApiConstants.baseUrl}${user.photoProfile}')
                              : null,
                          child: user.photoProfile == null
                              ? Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // ── Name + email ─────────────────────────────────────
                  Text(user.displayName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: AppSizes.xs),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: AppSizes.xs),

                  // ── Rating stars ─────────────────────────────────────
                  statsAsync.when(
                    loading: () => const SizedBox(
                      height: 20,
                      child: LinearProgressIndicator(
                          color: AppColors.primary, minHeight: 2),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (stats) {
                      if (stats.averageRating == null || stats.totalRatings == 0) {
                        return const Text(
                          'Pas encore évalué',
                          style: TextStyle(fontSize: 12, color: AppColors.textHint),
                        );
                      }
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) => Icon(
                                i < stats.averageRating!.round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: const Color(0xFFF59E0B),
                                size: 18,
                              )),
                          const SizedBox(width: 6),
                          Text(
                            '${stats.averageRating!.toStringAsFixed(1)} (${stats.totalRatings} avis)',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // ── Stats card ───────────────────────────────────────
                  Padding(
                    padding: AppSizes.pagePadding,
                    child: _StatsCard(statsAsync: statsAsync),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Quick actions ─────────────────────────────────────
                  Padding(
                    padding: AppSizes.pagePadding,
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.campaign_outlined,
                          label: 'Voir mes annonces',
                          onTap: () => context.push('/my-jobs'),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _ActionTile(
                          icon: Icons.inbox_outlined,
                          label: 'Voir mes candidatures',
                          onTap: () => context.push('/my-applications'),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        _KycTile(
                          isVerified: user.isKycVerified,
                          kycStatus: user.kycStatus,
                          onTap: () => context.push('/kyc'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // ── Menu ─────────────────────────────────────────────
                  Padding(
                    padding: AppSizes.pagePadding,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: Icons.star_outline,
                            label: 'Mes évaluations',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            label: 'Paramètres',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 56),
                          _MenuItem(
                            icon: Icons.logout,
                            label: 'Déconnexion',
                            color: AppColors.error,
                            onTap: () => _confirmLogout(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final AsyncValue<dynamic> statsAsync;
  const _StatsCard({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: const Icon(Icons.bar_chart,
                      color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSizes.sm),
                const Text(
                  'Mes statistiques',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          statsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: LinearProgressIndicator(
                  color: AppColors.primary, minHeight: 2),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: Text('Impossible de charger les stats',
                  style: TextStyle(fontSize: 13, color: AppColors.textHint)),
            ),
            data: (stats) => Column(
              children: [
                _StatRow(
                  icon: Icons.add_circle_outline,
                  label: 'Offres créées',
                  value: '${stats.totalJobsCreated}',
                  color: AppColors.primary,
                ),
                _StatRow(
                  icon: Icons.engineering_outlined,
                  label: 'En cours',
                  value: '${stats.totalJobsInProgress}',
                  color: AppColors.warning,
                ),
                _StatRow(
                  icon: Icons.check_circle_outline,
                  label: 'Terminées',
                  value: '${stats.totalJobsCompleted}',
                  color: AppColors.success,
                ),
                _StatRow(
                  icon: Icons.group_outlined,
                  label: 'Candidatures reçues',
                  value: '${stats.totalApplicationsReceived}',
                  color: const Color(0xFF8B5CF6),
                ),
                _StatRow(
                  icon: Icons.send_outlined,
                  label: 'Candidatures envoyées',
                  value: '${stats.totalApplicationsSent}',
                  color: const Color(0xFF0EA5E9),
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLast;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
              ),
              Text(
                value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: AppSizes.md + 32 + AppSizes.md),
      ],
    );
  }
}

// ── Action tile ───────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

// ── KYC tile ──────────────────────────────────────────────────────────────
class _KycTile extends StatelessWidget {
  final bool isVerified;
  final String? kycStatus;
  final VoidCallback onTap;

  const _KycTile({
    required this.isVerified,
    required this.kycStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.success : AppColors.warning;
    final label = isVerified
        ? 'Vérifié ✓'
        : (kycStatus == 'PENDING' ? 'En attente de vérification' : 'Soumettre vos documents');

    return GestureDetector(
      onTap: isVerified ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          Icon(
            isVerified ? Icons.verified_user : Icons.shield_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KYC',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(label,
                    style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
          if (!isVerified)
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary)),
      trailing: Icon(Icons.chevron_right, color: color ?? AppColors.textHint),
      onTap: onTap,
    );
  }
}
