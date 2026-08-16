import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_page_layout.dart';

class AccountRejectedPage extends StatelessWidget {
  const AccountRejectedPage({super.key, this.reason});

  static const routeName = '/account-rejected';
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return StatusPageLayout(
      icon: Icons.cancel_outlined,
      iconColor: AppColors.error,
      iconBackground: AppColors.errorContainer,
      title: 'Account Not Approved',
      description:
          'Your school administrator was unable to approve this account. '
          'If you believe this is a mistake, please contact your school or '
          'reach out to our support team.',
      infoCard: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.errorContainer),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: AppColors.onErrorContainer, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason provided',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onErrorContainer, letterSpacing: 0)),
                  const SizedBox(height: 4),
                  Text(
                    reason ??
                        'Details did not match this institution\'s enrollment records.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.onErrorContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      primaryActionLabel: 'Contact Support',
      onPrimaryAction: () {},
      secondaryActionLabel: 'Back to Login',
      onSecondaryAction: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => r.isFirst),
    );
  }
}
