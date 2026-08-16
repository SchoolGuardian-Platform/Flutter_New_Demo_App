import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

PasswordStrength scorePassword(String value) {
  if (value.isEmpty) return PasswordStrength.empty;
  int score = 0;
  if (value.length >= 8) score++;
  if (RegExp(r'[0-9]').hasMatch(value)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(value)) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  switch (score) {
    case 0:
    case 1:
      return PasswordStrength.weak;
    case 2:
      return PasswordStrength.fair;
    case 3:
      return PasswordStrength.good;
    default:
      return PasswordStrength.strong;
  }
}

/// Four-segment strength bar + label, as seen under the Password field on
/// the "Create Your Parent Account" screen.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.strength});

  final PasswordStrength strength;

  int get _filledSegments {
    switch (strength) {
      case PasswordStrength.empty:
        return 0;
      case PasswordStrength.weak:
        return 1;
      case PasswordStrength.fair:
        return 2;
      case PasswordStrength.good:
        return 3;
      case PasswordStrength.strong:
        return 4;
    }
  }

  Color get _color {
    switch (strength) {
      case PasswordStrength.empty:
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.fair:
        return AppColors.warning;
      case PasswordStrength.good:
        return AppColors.primaryContainer;
      case PasswordStrength.strong:
        return AppColors.secondary;
    }
  }

  String get _label {
    switch (strength) {
      case PasswordStrength.empty:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.fair:
        return 'Fair';
      case PasswordStrength.good:
        return 'Good';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.empty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = i < _filledSegments;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? _color : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                const TextSpan(text: 'Password strength: '),
                TextSpan(
                  text: _label,
                  style: TextStyle(color: _color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
