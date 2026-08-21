import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../landing_page.dart';
import '../login_page.dart';
import 'onboarding_data.dart';

/// 5-page first-launch onboarding: Welcome → Features → How did you hear
/// about us → Choose your role → Ready to get started.
///
/// Shown once (see [seenPrefsKey], read by `session_check_page.dart`).
/// Purely presentational + local storage — no backend calls. The role
/// picked on page 4 is used to open the respective role dashboard.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const routeName = '/onboarding';

  static const seenPrefsKey = 'onboarding_seen';
  static const rolePrefsKey = 'onboarding_selected_role';
  static const referralPrefsKey = 'onboarding_referral_source';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;

  String? _selectedReferral;
  UserRole? _selectedRole;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(OnboardingPage.seenPrefsKey, true);
      if (_selectedRole != null) {
        await prefs.setString(
            OnboardingPage.rolePrefsKey, _selectedRole!.apiValue);
      }
      if (_selectedReferral != null) {
        await prefs.setString(
            OnboardingPage.referralPrefsKey, _selectedReferral!);
      }
    } catch (_) {
      // Non-critical — worst case onboarding shows again next launch.
    }
  }

  Future<void> _skipToRoleSelect() async {
    await _markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(LandingPage.routeName);
  }

  Future<void> _finishToLogin() async {
    await _markSeen();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacementNamed(LoginPage.routeName, arguments: _selectedRole);
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _index > 0;
    final showSkip = _index == 1 || _index == 2;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 18, color: AppColors.onSurface),
                        onPressed: () => _goTo(_index - 1),
                      )
                    else
                      const SizedBox(width: 48),
                    const Spacer(),
                    if (showSkip)
                      TextButton(
                        onPressed: _skipToRoleSelect,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            if (_index >= 1 && _index <= 3) _PageDots(index: _index - 1),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _WelcomePage(onGetStarted: () => _goTo(1)),
                  _FeaturesPage(onNext: () => _goTo(2)),
                  _ReferralPage(
                    selected: _selectedReferral,
                    onSelect: (v) => setState(() => _selectedReferral = v),
                    onContinue: () => _goTo(3),
                  ),
                  _RolePage(
                    selected: _selectedRole,
                    onSelect: (r) => setState(() => _selectedRole = r),
                    onContinue: () => _goTo(4),
                  ),
                  _ReadyPage(
                    role: _selectedRole,
                    onContinue: _finishToLogin,
                    onPickRole: () => _goTo(3),
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

class _PageDots extends StatelessWidget {
  const _PageDots({required this.index});

  /// 0-based index within the 3 "flow" pages (features / referral / role).
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          3,
          (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared full-width filled CTA button in the app design style.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton(
      {required this.label, required this.onPressed, this.enabled = true});

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.child, required this.footer});

  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: child,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: footer,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------
// Page 1 — Welcome
// ---------------------------------------------------------------------

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onGetStarted});
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      footer: _PrimaryButton(label: 'Get Started', onPressed: onGetStarted),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: AppColors.primarySoftBg,
              shape: BoxShape.circle,
            ),
            child: const Center(child: AppLogoBadge(size: 84)),
          ),
          const SizedBox(height: AppSpacing.xl2),
          const Text(
            'Welcome to\nSchool Guard',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.4,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'A smarter way to stay connected to your school.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 2 — Features
// ---------------------------------------------------------------------

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      footer: _PrimaryButton(label: 'Next', onPressed: onNext),
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Everything you need\nin one place',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final feature in onboardingFeatures) ...[
            _FeatureCard(feature: feature),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final OnboardingFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primarySoftBg,
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature.body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 3 — How did you hear about us?
// ---------------------------------------------------------------------

class _ReferralPage extends StatelessWidget {
  const _ReferralPage({
    required this.selected,
    required this.onSelect,
    required this.onContinue,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      footer: _PrimaryButton(
        label: 'Continue',
        enabled: selected != null,
        onPressed: onContinue,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        children: [
          const Text(
            'How did you hear about\nSchool Guard?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.3,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final option in referralOptions) ...[
            _SelectableRow(
              icon: option.icon,
              label: option.label,
              selected: selected == option.label,
              onTap: () => onSelect(option.label),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  const _SelectableRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoftBg : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    selected ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.primaryDark : AppColors.onSurface,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  size: 18, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 4 — Choose your role
// ---------------------------------------------------------------------

class _RolePage extends StatelessWidget {
  const _RolePage({
    required this.selected,
    required this.onSelect,
    required this.onContinue,
  });

  final UserRole? selected;
  final ValueChanged<UserRole> onSelect;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      footer: _PrimaryButton(
        label: 'Continue',
        enabled: selected != null,
        onPressed: onContinue,
      ),
      child: ListView(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        children: [
          const Text(
            'What is your role?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final role in UserRole.values) ...[
            _RoleSelectCard(
              role: role,
              selected: selected == role,
              onTap: () => onSelect(role),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RoleSelectCard extends StatelessWidget {
  const _RoleSelectCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoftBg : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.primarySoftBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                role.icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primaryDark
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    onboardingRoleBlurb(role),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Page 5 — Ready to get started
// ---------------------------------------------------------------------

class _ReadyPage extends StatelessWidget {
  const _ReadyPage({
    required this.role,
    required this.onContinue,
    required this.onPickRole,
  });

  final UserRole? role;
  final VoidCallback onContinue;
  final VoidCallback onPickRole;

  @override
  Widget build(BuildContext context) {
    final hasRole = role != null;
    return _PageScaffold(
      footer: hasRole
          ? _PrimaryButton(
              label: 'Continue to ${role!.label} Login',
              onPressed: onContinue,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select a role to continue.',
                  style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.sm),
                _PrimaryButton(label: 'Choose Your Role', onPressed: onPickRole),
              ],
            ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.primarySoftBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.primary, size: 56),
          ),
          const SizedBox(height: AppSpacing.xl2),
          const Text(
            "You're all set!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            "Let's get you started with School Guard.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: AppColors.onSurfaceVariant),
          ),
          if (hasRole) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primarySoftBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                'Role: ${role!.label}',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
