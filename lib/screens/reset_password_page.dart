import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.token});

  static const routeName = '/reset-password';
  final String? token;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  // Mirrors backend `isStrongPassword` in src/utils/password.ts exactly:
  // >=8 chars, upper, lower, digit, and any non-alphanumeric character.
  bool get _hasMinLength => _password.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_password.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_password.text);
  bool get _hasSpecialChar =>
      RegExp(r'[^A-Za-z0-9]').hasMatch(_password.text);
  bool get _requirementsMet =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_requirementsMet) return;

    final token = widget.token;
    if (token == null || token.isEmpty) {
      // The backend needs the reset token from the emailed link
      // (POST /auth/reset-password/confirm with { token, newPassword }) —
      // see resetPasswordConfirmSchema. Without a token this call cannot
      // succeed. TODO: this screen currently has no way to receive that
      // token — see PROGRESS.md for the deep-link work still needed.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Missing reset token. Please use the link from your email.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _authService.resetPasswordConfirm(
        token: token,
        newPassword: _password.text,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login', (r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: Column(
          children: [
            const AppLogoBadge(filled: true, shape: BoxShape.circle),
            const SizedBox(height: AppSpacing.md),
            Text('SchoolGuardian',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: AppColors.primary)),
            const SizedBox(height: AppSpacing.xl),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create a New Password',
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Please choose a strong password to secure your account.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    controller: _password,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => (v == null || v.length < 8)
                        ? 'At least 8 characters'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: 'Confirm New Password',
                    hint: 'Confirm new password',
                    controller: _confirmPassword,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.replay_outlined,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password requirements:',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(letterSpacing: 0)),
                        const SizedBox(height: AppSpacing.sm),
                        _Requirement(
                            met: _hasMinLength,
                            label: 'At least 8 characters long'),
                        _Requirement(met: _hasNumber, label: 'Contains a number'),
                        _Requirement(
                            met: _hasSpecialChar,
                            label:
                                'Contains a special character (!@#\$%^&*)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Reset Password'),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (r) => r.isFirst),
                      child: const Text('Back to Login'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: met ? AppColors.secondary : AppColors.outline,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: met ? AppColors.onSurface : AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
