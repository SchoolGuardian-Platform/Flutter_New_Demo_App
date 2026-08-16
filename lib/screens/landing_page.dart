import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../theme/app_theme.dart';
import '../theme/kukie_accent.dart';
import '../widgets/app_logo.dart';

/// "Select your role" screen. Shown after the onboarding intro on a
/// person's very first visit, and directly (skipping onboarding) on every
/// return visit where they're logged out — see `session_check_page.dart`.
/// Visual redesign only; role-selection logic (`_selectRole`) and routing
/// are unchanged from before.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const routeName = '/landing';

  void _selectRole(BuildContext context, UserRole role) {
    Navigator.of(context).pushNamed('/login', arguments: role);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: KukieAccent.cardBorder),
                ),
              ),
              child: const AppWordmark(),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.xl2, AppSpacing.lg, AppSpacing.xl),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [KukieAccent.violetTint, Colors.white],
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          children: [
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'A Safer, Smarter\n',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -0.4,
                                      color: KukieAccent.ink,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'School Community',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                      letterSpacing: -0.4,
                                      color: KukieAccent.violet,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Text(
                              'Connect, monitor, and support learning in a '
                              'secure environment. Select your role below to '
                              'get to your dashboard.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: KukieAccent.bodyGray,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const _TrustRow(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'Who are you?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: KukieAccent.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        child: Column(
                          children: [
                            for (final role in UserRole.values) ...[
                              _RoleCard(
                                role: role,
                                highlighted: role == UserRole.parent,
                                onTap: () => _selectRole(context, role),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _points = [
    'Verified accounts only',
    'Built for K-12 schools',
    'Privacy-first design',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final point in _points)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle,
                  size: 15, color: KukieAccent.success),
              const SizedBox(width: 4),
              Text(point,
                  style: const TextStyle(
                      fontSize: 12.5, color: KukieAccent.bodyGray)),
            ],
          ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.onTap,
    this.highlighted = false,
  });

  final UserRole role;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
          border: Border.all(
            color:
                highlighted ? KukieAccent.violet : KukieAccent.cardBorder,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: KukieAccent.violetTint,
                shape: BoxShape.circle,
              ),
              child: Icon(role.icon, color: KukieAccent.violet, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KukieAccent.ink,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    role.description,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: KukieAccent.bodyGray,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: KukieAccent.bodyGray),
          ],
        ),
      ),
    );
  }
}
