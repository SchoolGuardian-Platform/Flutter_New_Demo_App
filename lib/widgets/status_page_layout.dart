import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'auth_scaffold.dart';

/// Shared layout for full-screen status states (pending approval, rejected,
/// unauthorized) — a centered icon badge, headline, description, an
/// optional info card, and one or two actions. Mirrors the visual language
/// of the "Waiting for School Approval" Stitch screen.
class StatusPageLayout extends StatelessWidget {
  const StatusPageLayout({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.infoCard,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final Widget? infoCard;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      maxWidth: 440,
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (infoCard != null) ...[
            const SizedBox(height: AppSpacing.xl),
            infoCard!,
          ],
          const SizedBox(height: AppSpacing.xl),
          if (primaryActionLabel != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPrimaryAction,
                child: Text(primaryActionLabel!),
              ),
            ),
          if (secondaryActionLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
