import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl))
          .post(ApiConstants.forgotPassword, data: {
        'email': _emailCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            ResetPasswordPage(email: _emailCtrl.text.trim()),
      ));
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Erreur réseau. Réessayez.';
      if (e.response?.statusCode == 429) {
        final data = e.response?.data;
        if (data is Map) msg = data['error'] as String? ?? msg;
      }
      _showError(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.lg),

                // Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.lock_reset,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: AppSizes.md),

                const Text(
                  'Mot de passe oublié ?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSizes.sm),
                const Text(
                  'Entrez votre adresse email. Un code de vérification vous sera envoyé pour réinitialiser votre mot de passe.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5),
                ),
                const SizedBox(height: AppSizes.xl),

                AppTextField(
                  controller: _emailCtrl,
                  hintText: 'Email professionnel',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.textHint, size: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Adresse email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.xl),

                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendCode,
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
                        : const Text('Envoyer le code',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Retour à la connexion',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
