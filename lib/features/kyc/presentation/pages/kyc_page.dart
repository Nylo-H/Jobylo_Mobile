import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repository/kyc_repository.dart';

class KycPage extends ConsumerStatefulWidget {
  const KycPage({super.key});

  @override
  ConsumerState<KycPage> createState() => _KycPageState();
}

class _KycPageState extends ConsumerState<KycPage> {
  String _selectedDocType = 'ID_CARD';
  File? _pickedFile;
  bool _isLoading = false;

  static const _docTypes = [
    _DocType('ID_CARD', 'Carte Nationale d\'Identité', Icons.credit_card),
    _DocType('PASSPORT', 'Passeport', Icons.book_outlined),
    _DocType('DRIVER_LICENSE', 'Permis de conduire', Icons.drive_eta_outlined),
  ];

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final source = await _showSourcePicker();
    if (source == null) return;

    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file != null) setState(() => _pickedFile = File(file.path));
  }

  Future<ImageSource?> _showSourcePicker() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: AppSizes.md),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pickedFile == null) {
      _showSnack('Veuillez sélectionner un document.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(kycRepositoryProvider);
      await repo.uploadDocument(
        filePath: _pickedFile!.path,
        documentType: _selectedDocType,
      );
      await ref.read(authStateProvider.notifier).refreshUser();
      if (mounted) {
        _showSnack('Document soumis avec succès ! En attente de vérification.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSizes.md),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Vérification d\'identité'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'La vérification KYC est obligatoire pour postuler à des missions et recevoir des paiements.',
                      style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary.withValues(alpha: 0.9),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Doc type selection
            const Text(
              'TYPE DE DOCUMENT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: AppSizes.sm),
            ...(_docTypes.map((dt) => _DocTypeTile(
                  docType: dt,
                  isSelected: _selectedDocType == dt.value,
                  onTap: () =>
                      setState(() => _selectedDocType = dt.value),
                ))),
            const SizedBox(height: AppSizes.xl),

            // Document upload area
            const Text(
              'DOCUMENT',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: _pickDocument,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _pickedFile != null
                      ? Colors.transparent
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: _pickedFile != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: _pickedFile != null ? 2 : 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: _pickedFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_pickedFile!, fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _pickedFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              color: AppColors.primary
                                  .withValues(alpha: 0.85),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle,
                                      color: Colors.white, size: 16),
                                  SizedBox(width: 6),
                                  Text('Document sélectionné',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.md),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.upload_file_outlined,
                                size: 32,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          const Text(
                            'Appuyez pour ajouter le document',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          const Text(
                            'Photo recto ou PDF — Max 10 MB',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Tips
            _TipRow(
                icon: Icons.light_mode_outlined,
                text: 'Prenez la photo dans un endroit bien éclairé'),
            const SizedBox(height: AppSizes.sm),
            _TipRow(
                icon: Icons.crop_free_outlined,
                text:
                    'Tous les coins du document doivent être visibles'),
            const SizedBox(height: AppSizes.sm),
            _TipRow(
                icon: Icons.hd_outlined,
                text: 'L\'image doit être nette et lisible'),
            const SizedBox(height: AppSizes.xl),

            SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.7),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusLg)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)))
                    : const Text('Soumettre le document',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
              ),
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

class _DocTypeTile extends StatelessWidget {
  final _DocType docType;
  final bool isSelected;
  final VoidCallback onTap;

  const _DocTypeTile(
      {required this.docType,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: (isSelected ? AppColors.primary : AppColors.textHint)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(docType.icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textHint),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(docType.label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
          ),
          if (isSelected)
            const Icon(Icons.check_circle,
                color: AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: AppSizes.sm),
      Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary))),
    ]);
  }
}

class _DocType {
  final String value;
  final String label;
  final IconData icon;
  const _DocType(this.value, this.label, this.icon);
}
