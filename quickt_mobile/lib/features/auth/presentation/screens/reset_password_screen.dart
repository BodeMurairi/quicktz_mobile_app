import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? prefillEmail;
  const ResetPasswordScreen({super.key, this.prefillEmail});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailCtrl =
      TextEditingController(text: widget.prefillEmail ?? '');
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = ref.read(l10nProvider);
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _error = l10n.passwordsDoNotMatch);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _emailCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
            newPassword: _passwordCtrl.text,
          );
      setState(() {
        _done = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is DioException
            ? (e.response?.data is Map
                ? (e.response!.data['detail']?.toString() ??
                    'Could not reset password. Please try again.')
                : 'Could not reset password. Please try again.')
            : 'Could not reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.darkPrimary),
              ),
              const SizedBox(height: 16),
              if (_done) ...[
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 32),
                ),
                const SizedBox(height: 20),
                Text(l10n.passwordResetSuccess,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary)),
                const SizedBox(height: 8),
                Text(l10n.passwordResetSuccessSubtitle,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.grey)),
                const SizedBox(height: 28),
                AppButton(
                  label: l10n.signIn,
                  onPressed: () => context.go('/login'),
                ),
              ] else ...[
                Text(l10n.resetPasswordAction,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary)),
                const SizedBox(height: 8),
                Text(l10n.enterCredentials,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.grey)),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _emailCtrl,
                        label: l10n.email,
                        hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _codeCtrl,
                        label: l10n.resetCode,
                        hint: '123456',
                        prefixIcon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                        validator: Validators.required,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: l10n.newPassword,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          color: AppColors.grey,
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPasswordCtrl,
                        label: l10n.confirmNewPassword,
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                AppButton(
                  label: l10n.resetPasswordAction,
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
