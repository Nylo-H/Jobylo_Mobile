import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/jobs_provider.dart';
import '../../data/repository/jobs_repository.dart';

class CreateJobPage extends ConsumerStatefulWidget {
  const CreateJobPage({super.key});

  @override
  ConsumerState<CreateJobPage> createState() => _CreateJobPageState();
}

class _CreateJobPageState extends ConsumerState<CreateJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final List<File> _pickedImages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ── Image picking ────────────────────────────────────────────────────────
  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (files.isEmpty) return;
    setState(() {
      _pickedImages.addAll(files.map((f) => File(f.path)));
      if (_pickedImages.length > 5) _pickedImages.length = 5;
    });
  }

  void _removeImage(int index) =>
      setState(() => _pickedImages.removeAt(index));

  // ── Upload images then create job ─────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showError('Veuillez choisir une catégorie.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 1. Create job first (no images yet)
      final repo = ref.read(jobsRepositoryProvider);
      final job = await repo.createJob(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
      );

      // 2. Upload images one-by-one via POST /jobs/{id}/images
      if (_pickedImages.isNotEmpty) {
        final dio = ref.read(dioProvider);
        for (final file in _pickedImages) {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.path),
          });
          await dio.post(
            '${ApiConstants.jobs}/${job.id}/images',
            data: formData,
          );
        }
      }

      ref.invalidate(myCreatedJobsProvider);
      ref.invalidate(availableJobsProvider);
      if (mounted) {
        _showSuccess('Annonce publiée avec succès !');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ]),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSizes.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
        ),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSizes.md),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm)),
        ),
      );

  void _pickCategory(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryPicker(
        categories: categories,
        selectedId: _selectedCategoryId,
        onSelect: (id, name) {
          setState(() {
            _selectedCategoryId = id;
            _selectedCategoryName = name;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Créer une annonce',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: TextButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Text('Publier',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            // ── Image picker ─────────────────────────────────────────
            _ImagePickerSection(
              images: _pickedImages,
              onAdd: _pickImages,
              onRemove: _removeImage,
            ),
            const SizedBox(height: AppSizes.lg),

            _SectionLabel(label: 'Informations générales'),
            const SizedBox(height: AppSizes.sm),

            AppTextField(
              controller: _titleController,
              hintText: 'Titre de l\'annonce',
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Titre requis' : null,
            ),
            const SizedBox(height: AppSizes.md),

            AppTextField(
              controller: _descController,
              hintText: 'Description détaillée...',
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Description requise' : null,
            ),
            const SizedBox(height: AppSizes.md),

            // Category picker
            categoriesAsync.when(
              loading: () => const SizedBox(
                  height: 56,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, _) => const SizedBox.shrink(),
              data: (cats) => GestureDetector(
                onTap: () => _pickCategory(cats),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: _selectedCategoryId != null
                          ? AppColors.primary
                          : AppColors.border,
                      width: _selectedCategoryId != null ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 20,
                          color: _selectedCategoryId != null
                              ? AppColors.primary
                              : AppColors.textHint),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          _selectedCategoryName ??
                              'Choisir une catégorie',
                          style: TextStyle(
                              fontSize: 15,
                              color: _selectedCategoryId != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            _SectionLabel(label: 'Lieu & Prix'),
            const SizedBox(height: AppSizes.sm),

            AppTextField(
              controller: _locationController,
              hintText: 'Lieu (ex: Akwa, Douala)',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppColors.textHint, size: 20),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Lieu requis' : null,
            ),
            const SizedBox(height: AppSizes.md),

            AppTextField(
              controller: _priceController,
              hintText: 'Prix en FCFA',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: false),
              prefixIcon: const Icon(Icons.sell_outlined,
                  color: AppColors.textHint, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Prix requis';
                if (double.tryParse(v) == null) return 'Nombre invalide';
                if (double.parse(v) <= 0) return 'Le prix doit être > 0';
                return null;
              },
            ),
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
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)))
                    : const Text('Publier l\'annonce',
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

// ── Image picker section ──────────────────────────────────────────────────
class _ImagePickerSection extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImagePickerSection({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photos',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
            const Spacer(),
            Text('${images.length}/5',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Add button
              if (images.length < 5)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(
                          color: AppColors.border,
                          style: BorderStyle.solid),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 22,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        const Text('Ajouter',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              // Picked images
              ...List.generate(images.length, (i) {
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: AppSizes.sm),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                        image: DecorationImage(
                          image: FileImage(images[i]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => onRemove(i),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.8),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedId;
  final void Function(String id, String name) onSelect;

  const _CategoryPicker(
      {required this.categories,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = <_CatItem>[];
    for (final cat in categories) {
      final subs = (cat['subcategories'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      if (subs.isEmpty) {
        items.add(_CatItem(
            id: cat['id'] as String,
            name: cat['name'] as String,
            parent: null));
      } else {
        for (final sub in subs) {
          items.add(_CatItem(
              id: sub['id'] as String,
              name: sub['name'] as String,
              parent: cat['name'] as String));
        }
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.md, AppSizes.lg, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSizes.md),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Choisir une catégorie',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
          const SizedBox(height: AppSizes.md),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = items[i];
                final isSelected = item.id == selectedId;
                return ListTile(
                  title: Text(item.name,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  subtitle: item.parent != null
                      ? Text(item.parent!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textHint))
                      : null,
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppColors.primary, size: 20)
                      : null,
                  onTap: () => onSelect(item.id, item.name),
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.lg),
        ],
      ),
    );
  }
}

class _CatItem {
  final String id;
  final String name;
  final String? parent;
  const _CatItem({required this.id, required this.name, this.parent});
}
