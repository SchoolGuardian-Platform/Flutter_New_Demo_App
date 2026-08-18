import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _authService = AuthService();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      // POST /auth/forgot-password — email only; the backend has no
      // phone-based reset (see auth.validator.ts `forgotPasswordSchema`).
      // It always returns 200 regardless of whether the email exists, to
      // avoid leaking account existence — so we always show the "sent"
      // state on success.
      await _authService.forgotPassword(_identifierController.text.trim());
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _sent = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  /// The backend's reset link (`{FRONTEND_URL}/reset-password?token=...`,
  /// see `sendPasswordResetEmail` in the mailer) is meant to open this app
  /// via a deep link and land directly on `ResetPasswordPage(token: ...)`.
  /// That native deep-link wiring (custom URL scheme / app link, platform
  /// manifest entries, a listener package like `app_links`) isn't set up
  /// yet — see PROGRESS.md #1. Until it is, this dialog lets the user
  /// paste the reset link (or just the token) from the emailed link by
  /// hand so the reset flow is usable today; swap this for the deep-link
  /// handler later.
  Future<void> _promptForToken(BuildContext context) async {
    final controller = TextEditingController();
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter reset link'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Paste the link from your email',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (pasted == null || pasted.isEmpty || !context.mounted) return;
    // Accept either the full emailed link (…/reset-password?token=XYZ) or
    // just the bare token, in case the user copies only that part.
    final token = _extractToken(pasted);
    if (token.isEmpty || !context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/reset-password', arguments: token);
  }

  /// Pulls the `token` query parameter out of a pasted reset link, or
  /// returns the input unchanged if it doesn't look like a URL.
  String _extractToken(String pasted) {
    final uri = Uri.tryParse(pasted);
    if (uri != null && uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token']!;
    }
    return pasted;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                const AppWordmark(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed.withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Forgot your password?',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _sent
                      ? "We've emailed you a password reset link. Open it on "
                          'this device to continue, or if you opened your '
                          'email elsewhere, paste the link below.'
                      : "Enter the email or phone number associated with your "
                          "School Guard account and we'll help you reset your "
                          'password.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
              boxShadow: AppColors.cardShadow,
            ),
            padding: const EdgeInsets.all(24),
            child: _sent
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_read_outlined,
                              color: AppColors.secondary),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              _identifierController.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => _promptForToken(context),
                        child: const Text('Paste the link instead'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => setState(() => _sent = false),
                        child: const Text('Use a different email or phone'),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          label: 'Email',
                          hint: 'name@school.edu',
                          controller: _identifierController,
                          prefixIcon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
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
                              : const Text('Send Reset Link'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            icon: const Icon(Icons.arrow_back, size: 16),
                            label: const Text('Back to Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}