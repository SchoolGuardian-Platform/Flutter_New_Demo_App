import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/status_page_layout.dart';
import 'landing_page.dart';

class UnauthorizedPage extends StatelessWidget {
  const UnauthorizedPage({super.key});

  static const routeName = '/unauthorized';

  @override
  Widget build(BuildContext context) {
    return StatusPageLayout(
      icon: Icons.block_outlined,
      iconColor: AppColors.onSurfaceVariant,
      iconBackground: AppColors.surfaceContainerHigh,
      title: "You Don't Have Access",
      description:
          "Your account doesn't have permission to view this page. If you "
          "think this is a mistake, try signing in with a different account "
          'or contact your school administrator.',
      primaryActionLabel: 'Back to Login',
      onPrimaryAction: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => r.isFirst),
      secondaryActionLabel: 'Go to Home',
      onSecondaryAction: () => Navigator.of(context)
          .pushNamedAndRemoveUntil(LandingPage.routeName, (r) => false),
    );
  }
}
