import 'package:flutter/material.dart';

/// Accent tokens matching the Kukie.io reference screenshot, used only by
/// the onboarding flow and the role-select ("landing") screen.
///
/// Deliberately kept in its own file rather than added to
/// `theme/app_theme.dart` — that file is the shared design system used
/// across every existing screen, and this look (brighter violet, rounded-
/// rect rather than pill buttons) is specific to this flow. Font family is
/// untouched: `app_theme.dart` already uses Google Fonts "Inter", which is
/// a close match to the reference, so no font change was needed here.
class KukieAccent {
  KukieAccent._();

  /// The bright indigo/violet from the reference — buttons, links, the
  /// second line of hero headlines.
  static const violet = Color(0xFF6366F1);
  static const violetDark = Color(0xFF4F46E5);

  /// Very light violet tint for the hero gradient background.
  static const violetTint = Color(0xFFEEF0FF);

  static const ink = Color(0xFF15161E); // near-black headline text
  static const bodyGray = Color(0xFF5B5D6B);
  static const cardBorder = Color(0xFFE7E7F2);
  static const success = Color(0xFF16A34A); // checkmark green

  /// Moderate rounded-rect radius — matches the reference buttons, which
  /// are visibly rounded but not full pills.
  static const buttonRadius = 12.0;
  static const cardRadius = 16.0;
}
