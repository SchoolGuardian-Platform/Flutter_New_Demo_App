import 'package:flutter/material.dart';

import '../../models/user_role.dart';

/// Content for the onboarding flow (`onboarding_page.dart`). Purely
/// presentational — no API calls.

class OnboardingFeature {
  const OnboardingFeature(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
}

const List<OnboardingFeature> onboardingFeatures = [
  OnboardingFeature(
    icon: Icons.campaign_outlined,
    title: 'Stay Connected',
    body: 'Keep up with important school updates and announcements.',
  ),
  OnboardingFeature(
    icon: Icons.bar_chart_outlined,
    title: 'Track Progress',
    body: 'Monitor attendance, grades, and academic performance.',
  ),
  OnboardingFeature(
    icon: Icons.notifications_active_outlined,
    title: 'Stay Informed',
    body: 'Receive important notifications and school information.',
  ),
  OnboardingFeature(
    icon: Icons.forum_outlined,
    title: 'Easy Communication',
    body: 'Stay connected with teachers, parents, students, and admins.',
  ),
];

/// "How did you hear about us?" options. The chosen value is stored
/// locally only (see `OnboardingPage`) — there's no backend field or
/// endpoint for it today.
class ReferralOption {
  const ReferralOption(this.icon, this.label);
  final IconData icon;
  final String label;
}

const List<ReferralOption> referralOptions = [
  ReferralOption(Icons.account_balance_outlined, 'School / Institution'),
  ReferralOption(Icons.school_outlined, 'Teacher'),
  ReferralOption(Icons.people_outline, 'Friend or Family'),
  ReferralOption(Icons.share_outlined, 'Social Media'),
  ReferralOption(Icons.search, 'Google / Search'),
  ReferralOption(Icons.touch_app_outlined, 'Advertisement'),
  ReferralOption(Icons.more_horiz, 'Other'),
];

/// Onboarding-flow-specific copy for each role card (page 4). Distinct
/// from the wording in `models/user_role.dart` (used on the returning-user
/// "select role" screen) since this spec calls for shorter, first-time-user
/// framing — the canonical role metadata (icon, apiValue, etc.) still comes
/// from [UserRole] itself.
String onboardingRoleBlurb(UserRole role) {
  switch (role) {
    case UserRole.parent:
      return "Stay connected with your child's education and school "
          "activities.";
    case UserRole.student:
      return 'Access your classes, attendance, grades, and school '
          'information.';
    case UserRole.teacher:
      return 'Manage your students, classes, attendance, and academic '
          'activities.';
    case UserRole.admin:
      return 'Manage your school, users, students, teachers, and system '
          'settings.';
  }
}
