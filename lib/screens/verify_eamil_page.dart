import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_page_layout.dart';
import 'landing_page.dart';
import 'pending_approval_page.dart';

/// Shown right after sign-up, before admin review — mirrors how
/// `PendingApprovalPage` mirrors "Waiting for School Approval": same
/// `StatusPageLayout` shell, same "waiting on something async, check back"
/// framing, just for the inbox step instead of the admin-review step.
///
/// Two ways to land here:
/// 1. Straight after `registerStudent`/`registerParent`/`registerTeacher`
///    succeeds — [email] is set, [token] is null. Shows the "check your
///    inbox" waiting state with a resend action.
/// 2. Via the emailed verification link
///    (`schoolguardian://verify-email?token=...`, mirroring how
///    `RESET_PASSWORD_URL` drives `ResetPasswordPage`) — [token] is set.
///    Confirms automatically on load, same idea as `resetPasswordConfirm`
///    but with no form to fill in first.
///
/// NOTE: `POST /auth/verify-email/resend` and
/// `POST /auth/verify-email/confirm` are not yet in `auth.routes.ts` —
/// this screen is written against the naming convention the existing
/// `/auth/reset-password/request` + `/auth/reset-password/confirm` pair
/// already established, for whoever wires up the backend side next.
class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, this.email, this.token});

  static const routeName = '/verify-email';

  /// The address the verification link was sent to. Only used to display
  /// it and to resend — the backend call itself only ever needs the token.
  final String? email;

  /// Present when this screen was opened from the emailed link.
  final String? token;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

enum _VerifyStatus { awaitingClick, confirming, confirmed, failed }

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _authService = AuthService();
  late _VerifyStatus _status;
  bool _resending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _status = widget.token != null
        ? _VerifyStatus.confirming
        : _VerifyStatus.awaitingClick;
    if (widget.token != null) {
      // Fire-and-await right away, same as ResetPasswordPage would if it
      // auto-submitted on having a token instead of waiting for a form.
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirm(widget.token!));
    }
  }

  Future<void> _confirm(String token) async {
    setState(() {
      _status = _VerifyStatus.confirming;
      _errorMessage = null;
    });
    try {
      await _authService.verifyEmailConfirm(token);
      if (!mounted) return;
      setState(() => _status = _VerifyStatus.confirmed);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _VerifyStatus.failed;
        _errorMessage = e.message;
      });
    }
  }

  Future<void> _resend() async {
    final email = widget.email;
    if (email == null || email.isEmpty) return;
    setState(() => _resending = true);
    try {
      await _authService.resendVerificationEmail(email);
      if (!mounted) return;
      setState(() => _resending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  void _continueToPendingApproval() {
    // Same next step as SignUpPage's own success path — new accounts are
    // always PENDING (registration.service.ts) regardless of email
    // verification, so this is still the correct place to land.
    Navigator.of(context).pushNamedAndRemoveUntil(
      PendingApprovalPage.routeName,
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_status) {
      case _VerifyStatus.confirming:
        return StatusPageLayout(
          icon: Icons.mark_email_read_outlined,
          iconColor: AppColors.primary,
          iconBackground: AppColors.primaryFixed,
          title: 'Verifying Your Email',
          description: 'Hang on while we confirm your email address...',
          infoCard: const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: CircularProgressIndicator(),
          ),
        );

      case _VerifyStatus.confirmed:
        return StatusPageLayout(
          icon: Icons.check_circle_outline,
          iconColor: AppColors.secondary,
          iconBackground: AppColors.secondaryContainer,
          title: 'Email Verified',
          description:
              'Your email address has been confirmed. Your account is now '
              'awaiting review by your school administrator.',
          primaryActionLabel: 'Continue',
          onPrimaryAction: _continueToPendingApproval,
        );

      case _VerifyStatus.failed:
        return StatusPageLayout(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          iconBackground: AppColors.errorContainer,
          title: 'Verification Failed',
          description: _errorMessage ??
              'This verification link is invalid or has expired.',
          primaryActionLabel:
              _resending ? 'Sending...' : 'Resend Verification Email',
          onPrimaryAction: (_resending || widget.email == null)
              ? null
              : _resend,
          secondaryActionLabel: 'Back to Login',
          onSecondaryAction: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(LandingPage.routeName, (r) => false),
        );

      case _VerifyStatus.awaitingClick:
        return StatusPageLayout(
          icon: Icons.mark_email_unread_outlined,
          iconColor: AppColors.primary,
          iconBackground: AppColors.primaryFixed,
          title: 'Verify Your Email',
          description: widget.email != null
              ? "We've sent a verification link to ${widget.email}. Open it "
                  'on this device to confirm your address before your '
                  'account can be reviewed.'
              : "We've sent a verification link to your email. Open it on "
                  'this device to confirm your address before your account '
                  'can be reviewed.',
          infoCard: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.primary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('Awaiting Verification',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          primaryActionLabel: "I've Verified, Continue",
          onPrimaryAction: _continueToPendingApproval,
          secondaryActionLabel: _resending ? 'Sending...' : 'Resend Email',
          onSecondaryAction: (_resending || widget.email == null)
              ? null
              : _resend,
        );
    }
  }
}