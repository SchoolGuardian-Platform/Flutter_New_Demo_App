import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exception.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'landing_page.dart';
import 'onboarding/onboarding_page.dart';

/// First screen the app shows. If a token pair is already stored, this
/// tries `GET /auth/me` to confirm the session is still valid — the
/// `ApiClient`'s automatic 401-refresh-and-retry (see `core/api_client.dart`)
/// means a merely-expired access token is silently rotated here, so a
/// returning user with a live refresh token skips straight past login.
///
/// If there's no stored token, or `/auth/me` fails even after the refresh
/// attempt (refresh token itself expired/revoked/missing), it falls
/// through to [OnboardingPage] the very first time the app is opened
/// (tracked via [SharedPreferences], see [OnboardingPage.seenPrefsKey]),
/// or straight to [LandingPage] ("select your role") on every launch after
/// that.
class SessionCheckPage extends StatefulWidget {
  const SessionCheckPage({super.key});

  static const routeName = '/';

  @override
  State<SessionCheckPage> createState() => _SessionCheckPageState();
}

class _SessionCheckPageState extends State<SessionCheckPage> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasToken = await _authService.isLoggedIn();
    if (!hasToken) {
      _goToOnboardingOrLanding();
      return;
    }

    try {
      // GET /auth/me — also serves as the "is this session still good"
      // check. A 401 here triggers ApiClient's refresh-and-retry; if that
      // also fails, ApiClient clears the stored tokens for us.
      final user = await _authService.getMe();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        DashboardPage.routeName,
        arguments: user,
      );
    } on ApiException {
      _goToOnboardingOrLanding();
    } catch (_) {
      _goToOnboardingOrLanding();
    }
  }

  Future<void> _goToOnboardingOrLanding() async {
    if (!mounted) return;
    bool seenOnboarding = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seenOnboarding = prefs.getBool(OnboardingPage.seenPrefsKey) ?? false;
    } catch (_) {
      // If prefs can't be read, default to showing onboarding — harmless
      // either way, it's just a one-time intro.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      seenOnboarding ? LandingPage.routeName : OnboardingPage.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogoBadge(),
            SizedBox(height: AppSpacing.lg),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
