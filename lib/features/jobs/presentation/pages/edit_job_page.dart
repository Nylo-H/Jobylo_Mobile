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
import '../../domain/entities/job.dart';

class EditJobPage extends ConsumerStatefulWidget {
  final Job job;
  const EditJobPage({super.key, required this.job});

  @override
  ConsumerState<EditJobPage> createState() => _EditJobPageState();
}

class _EditJobPageState extends ConsumerState<EditJobPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  final List<File> _newImages = [];
  List<String> _existingImages = [];
  DateTime? _applicationDeadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _titleController = TextEditingController(text: job.title);
    _descController = TextEditingController(text: job.description ?? '');
    _locationController = TextEditingController(text: job.location);
    _priceController = TextEditingController(text: job.price.toStringAsFixed(0));
    _selectedCategoryId = job.categoryId;
    _selectedCategoryName = job.categoryName;
    _existingImages = List.from(job.images);
    _applicationDeadline = job.applicationDeadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80, limit: 5);
    if (files.isEmpty) return;
    setState(() {
      _newImages.addAll(files.map((f) => File(f.path)));
      final total = _existingImages.length + _newImages.length;
      if (total > 5) _newImages.length = 5 - _existingImages.length;
    });
  }

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));

  void _removeExistingImage(int index) =>
      setState(() => _existingImages.removeAt(index));

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _applicationDeadline ?? now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Date limite de candidature',
      confirmText: 'Choisir',
      cancelText: 'Annuler',
    );
    if (picked != null) setState(() => _applicationDeadline = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showError('Veuillez choisir une catégorie.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(jobsRepositoryProvider);
      await repo.updateJob(
        jobId: widget.job.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _selectedCategoryId!,
        images: _existingImages,
        applicationDeadline: _applicationDeadline,
      );

      if (_newImages.isNotEmpty) {
        final dio = ref.read(dioProvider);
        for (final file in _newImages) {
          final formData = FormData.fromMap({
            'file': await MultipartFile.fromFile(file.path),
          });
          await dio.post(
            '${ApiConstants.jobs}/${widget.job.id}/images',
            data: formData,
          );
        }
      }

      ref.invalidate(myCreatedJobsProvider);
      ref.invalidate(availableJobsProvider);
      ref.invalidate(jobDetailProvider(widget.job.id));
      if (mounted) {
        _showSuccess('Annonce modifiée avec succès !');
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
        title: const Text('Modifier l\'annonce',
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
                  : const Text('Enregistrer',
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
            // ── Existing images ──────────────────────────────────────
            if (_existingImages.isNotEmpty) ...[
              const _SectionLabel(label: 'Photos actuelles'),
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImages.length,
                  itemBuilder: (_, i) {
                    final url = _existingImages[i].startsWith('http')
                        ? _existingImages[i]
                        : '${ApiConstants.baseUrl}${_existingImages[i]}';
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
                              image: NetworkImage(url),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removeExistingImage(i),
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
                  },
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],

            // ── New images picker ───────────────────────────────────
            _ImagePickerSection(
              images: _newImages,
              maxTotal: 5 - _existingImages.length,
              onAdd: _pickImages,
              onRemove: _removeNewImage,
            ),
            const SizedBox(height: AppSizes.lg),

            const _SectionLabel(label: 'Informations générales'),
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

            categoriesAsync.when(
              loading: () => const SizedBox(
                  height: 56,
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2))),
              error: (_, __) => const SizedBox.shrink(),
              data: (cats) => GestureDetector(
                onTap: () => _pickCategory(cats),
                child: Container(
                  height: 56,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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
                          _selectedCategoryName ?? 'Choisir une catégorie',
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

            const _SectionLabel(label: 'Lieu & Prix'),
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
            const SizedBox(height: AppSizes.lg),

            const _SectionLabel(label: 'Date limite (optionnelle)'),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _pickDeadline(),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: _applicationDeadline != null
                        ? AppColors.primary
                        : AppColors.border,
                    width: _applicationDeadline != null ? 2 : 1.5,
                  ),
                ),
                child: Row(children: [
                  Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: _applicationDeadline != null
                        ? AppColors.primary
                        : AppColors.textHint,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _applicationDeadline != null
                          ? 'Limite : ${_applicationDeadline!.day.toString().padLeft(2, '0')}/${_applicationDeadline!.month.toString().padLeft(2, '0')}/${_applicationDeadline!.year}'
                          : 'Pas de date limite',
                      style: TextStyle(
                        fontSize: 15,
                        color: _applicationDeadline != null
                            ? AppColors.textPrimary
                            : AppColors.textHint,
                      ),
                    ),
                  ),
                  if (_applicationDeadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _applicationDeadline = null),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textHint),
                    ),
                ]),
              ),
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
                    : const Text('Enregistrer les modifications',
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
  final int maxTotal;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _ImagePickerSection({
    required this.images,
    required this.maxTotal,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (maxTotal <= 0) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Nouvelles photos',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
            const Spacer(),
            Text('${images.length}/$maxTotal',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textHint)),
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (images.length < maxTotal)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
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
                              color: Colors.black54, shape: BoxShape.circle),
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
              separatorBuilder: (_, __) => const Divider(height: 1),
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
