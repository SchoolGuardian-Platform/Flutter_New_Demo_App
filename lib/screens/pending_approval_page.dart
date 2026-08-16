import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_page_layout.dart';
import 'landing_page.dart';

class PendingApprovalPage extends StatelessWidget {
  const PendingApprovalPage({super.key});

  static const routeName = '/pending-approval';

  @override
  Widget build(BuildContext context) {
    return StatusPageLayout(
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningContainer,
      title: 'Pending Approval',
      description:
          'Your account has been created and is now awaiting review by your '
          "school administrator. We'll notify you by email as soon as a "
          'decision is made.',
      infoCard: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.warning, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('In Review',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.onWarningContainer,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(label: 'SUBMITTED', value: 'Just now'),
            const SizedBox(height: AppSpacing.md),
            _InfoRow(
                label: 'REVIEWED BY',
                value: 'School Administrator',
                icon: Icons.verified_user_outlined),
          ],
        ),
      ),
      primaryActionLabel: 'Check Status',
      onPrimaryAction: () {},
      secondaryActionLabel: 'Log Out',
      onSecondaryAction: () => Navigator.of(context)
          .pushNamedAndRemoveUntil(LandingPage.routeName, (r) => false),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.6, color: AppColors.outline)),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
