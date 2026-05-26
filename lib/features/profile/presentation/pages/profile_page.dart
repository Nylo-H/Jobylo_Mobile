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

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

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
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: AppSizes.lg),

                // ── Avatar + edit ─────────────────────────────────────
                _ProfileAvatar(
                  photoUrl: user.photoProfile != null
                      ? '${ApiConstants.baseUrl}${user.photoProfile}'
                      : null,
                  name: user.displayName,
                  onTap: () => _pickAndUploadPhoto(context, ref),
                ),
                const SizedBox(height: AppSizes.md),

                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // ── Stats ─────────────────────────────────────────────
                Padding(
                  padding: AppSizes.pagePadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '${user.totalRatings ?? 0}',
                          label: 'Jobs créés',
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: _StatCard(
                          value: user.averageRating != null
                              ? user.averageRating!.toStringAsFixed(1)
                              : '–',
                          label: 'Note moyenne',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // ── KYC ──────────────────────────────────────────────
                Padding(
                  padding: AppSizes.pagePadding,
                  child: _KycBanner(
                    isVerified: user.isKycVerified,
                    kycStatus: user.kycStatus,
                    onTap: () => context.push('/kyc'),
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
                          onTap: () =>
                              ref.read(authStateProvider.notifier).logout(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(
      BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (file == null) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.uploadProfilePhoto(file.path);
      ref.read(authStateProvider.notifier).setUser(user);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo mise à jour !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Avatar widget ──────────────────────────────────────────────────────────
class _ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: AppSizes.avatarXl / 2,
            backgroundColor: AppColors.surfaceVariant,
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl!)
                : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
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
              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KYC Banner ────────────────────────────────────────────────────────────
class _KycBanner extends StatelessWidget {
  final bool isVerified;
  final String? kycStatus;
  final VoidCallback onTap;

  const _KycBanner({
    required this.isVerified,
    required this.kycStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? AppColors.success : AppColors.warning;
    final label = isVerified
        ? 'Vérifié'
        : (kycStatus == 'PENDING' ? 'En attente' : 'Soumettre');
    final desc = isVerified
        ? 'Votre profil est sécurisé.'
        : 'Vérifiez votre identité pour postuler.';

    return GestureDetector(
      onTap: isVerified ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified ? Icons.verified_user : Icons.warning_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Vérification d'identité",
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isVerified ? Icons.check_circle : Icons.chevron_right,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 3),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
          const SizedBox(height: AppSizes.xs),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon,
      required this.label,
      this.color,
      required this.onTap});

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
