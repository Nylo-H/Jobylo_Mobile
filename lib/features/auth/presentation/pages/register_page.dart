import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/repository/auth_repository.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(() {
      if (_password != _passwordCtrl.text) {
        setState(() => _password = _passwordCtrl.text);
      }
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ── Password strength ─────────────────────────────────────────────────
  static final _hasUpper = RegExp(r'[A-Z]');
  static final _hasLower = RegExp(r'[a-z]');
  static final _hasDigit = RegExp(r'\d');
  static final _hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=/\\]');

  int _strengthScore(String p) {
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (_hasUpper.hasMatch(p)) s++;
    if (_hasLower.hasMatch(p)) s++;
    if (_hasDigit.hasMatch(p)) s++;
    if (_hasSpecial.hasMatch(p)) s++;
    return s;
  }

  // ── Validation ────────────────────────────────────────────────────────
  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Requis';
    if (v.length < 8) return 'Minimum 8 caractères';
    if (!_hasUpper.hasMatch(v)) return 'Ajoutez au moins une majuscule';
    if (!_hasDigit.hasMatch(v)) return 'Ajoutez au moins un chiffre';
    return null;
  }

  // ── Submit ────────────────────────────────────────────────────────────
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      _showError("Veuillez accepter les conditions générales d'utilisation.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) {
        _showSuccess('Compte créé ! Vérifiez votre email.');
        context.push(
          '/auth/otp?email=${Uri.encodeComponent(_emailCtrl.text.trim())}',
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
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
      duration: const Duration(seconds: 4),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    ));
  }

  @override
  Widget build(BuildContext context) {
    final score = _strengthScore(_password);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.xl),

                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.work_outline,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: AppSizes.md),
                const Text('Jobylo',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(height: AppSizes.xs),
                const Text('Créez votre compte pour commencer',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: AppSizes.xl),

                // Prénom / Nom
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      controller: _firstNameCtrl,
                      hintText: 'Prénom',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: AppTextField(
                      controller: _lastNameCtrl,
                      hintText: 'Nom',
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _usernameCtrl,
                  hintText: "Nom d'utilisateur",
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v.contains(' ')) return "Pas d'espace autorisé";
                    if (v.length < 3) return 'Minimum 3 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                AppTextField(
                  controller: _emailCtrl,
                  hintText: 'Email professionnel',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Adresse email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // Password + strength indicator
                AppTextField(
                  controller: _passwordCtrl,
                  hintText: 'Mot de passe',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: _validatePassword,
                ),
                if (_password.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.sm),
                  _PasswordStrengthBar(score: score),
                  const SizedBox(height: AppSizes.xs),
                  _PasswordRequirements(password: _password),
                ],
                const SizedBox(height: AppSizes.md),

                // Confirm password
                AppTextField(
                  controller: _confirmCtrl,
                  hintText: 'Confirmer le mot de passe',
                  obscureText: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requis';
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSizes.md),

                // CGU checkbox
                GestureDetector(
                  onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (v) =>
                              setState(() => _acceptTerms = v ?? false),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4),
                            children: [
                              TextSpan(text: "J'accepte les "),
                              TextSpan(
                                  text: 'Conditions Générales',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                              TextSpan(text: ' et la '),
                              TextSpan(
                                  text: 'Politique de Confidentialité',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
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
                        : const Text('Créer mon compte',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ? ',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: const Text('Se connecter',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Password strength bar ─────────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final int score;
  const _PasswordStrengthBar({required this.score});

  Color get _color {
    if (score <= 1) return AppColors.error;
    if (score <= 2) return AppColors.warning;
    if (score <= 3) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  String get _label {
    if (score <= 1) return 'Très faible';
    if (score <= 2) return 'Faible';
    if (score <= 3) return 'Moyen';
    if (score == 4) return 'Fort';
    return 'Très fort ✓';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                height: 4,
                decoration: BoxDecoration(
                  color: i < score ? _color : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(_label,
            style: TextStyle(
                fontSize: 12, color: _color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Password requirements checklist ──────────────────────────────────────
class _PasswordRequirements extends StatelessWidget {
  final String password;
  const _PasswordRequirements({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Req(met: password.length >= 8, label: '8 caractères minimum'),
        _Req(
          met: RegExp(r'[A-Z]').hasMatch(password),
          label: '1 lettre majuscule',
        ),
        _Req(
          met: RegExp(r'\d').hasMatch(password),
          label: '1 chiffre',
        ),
      ],
    );
  }
}

class _Req extends StatelessWidget {
  final bool met;
  final String label;
  const _Req({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: met ? AppColors.success : AppColors.textHint)),
      ]),
    );
  }
}
