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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(_emailCtrl.text.trim());
      setState(() {
        _sent = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e is DioException
            ? (e.response?.data is Map
                ? (e.response!.data['detail']?.toString() ??
                    'Something went wrong. Please try again.')
                : 'Something went wrong. Please try again.')
            : 'Something went wrong. Please try again.';
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
              if (_sent) ...[
                const SizedBox(height: 12),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_read_outlined,
                      color: AppColors.success, size: 32),
                ),
                const SizedBox(height: 20),
                Text(l10n.checkYourEmail,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary)),
                const SizedBox(height: 8),
                Text(l10n.resetCodeSentMessage(_emailCtrl.text.trim()),
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.grey)),
                const SizedBox(height: 28),
                AppButton(
                  label: l10n.iHaveMyCode,
                  onPressed: () => context.push('/reset-password',
                      extra: _emailCtrl.text.trim()),
                ),
              ] else ...[
                Text(l10n.resetYourPassword,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkPrimary)),
                const SizedBox(height: 8),
                Text(l10n.forgotPasswordSubtitle,
                    style:
                        const TextStyle(fontSize: 14, color: AppColors.grey)),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: AppTextField(
                    controller: _emailCtrl,
                    label: l10n.email,
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
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
                  label: l10n.sendResetCode,
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
