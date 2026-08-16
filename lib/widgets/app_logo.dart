import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The SchoolGuardian brand mark.
///
/// Uses the official crest artwork (`assets/images/logo.png` — the
/// "Blue & Gold" badge) everywhere the app previously drew a generic
/// `Icons.shield_outlined` glyph. Requires the asset to be registered in
/// `pubspec.yaml`:
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/logo.png
/// ```
/// See HANDOFF.md for the full pubspec snippet. If the asset can't load
/// for any reason (e.g. not yet wired into pubspec.yaml), both widgets
/// fall back to the old shield icon so the app never crashes on a missing
/// asset.
///
/// THIS IS THE FIX for "the logo shows up embedded in a rectangle
/// instead of just the icon": the source PNG used to be a plain white
/// square with the shield drawn on it (no transparency), and on top of
/// that this widget wrapped it in its own `Container` with a background
/// color + drop shadow + rounded corners -- so you got a white/colored
/// box around a white square, i.e. a visible rectangle around the crest
/// everywhere it appeared. The asset now has a real transparent
/// background (only the shield artwork itself is opaque), and this
/// widget no longer draws any surrounding box -- it just renders the
/// crest at the requested size, nothing else.
const String kAppLogoAssetPath = 'assets/images/logo.png';

class AppLogoBadge extends StatelessWidget {
  const AppLogoBadge({
    super.key,
    this.size = 72,
    this.shape = BoxShape.rectangle,
    this.filled = false,
  });

  final double size;

  /// Kept for backwards compatibility with existing call sites; no longer
  /// affects rendering now that there's no background box to shape.
  final BoxShape shape;

  /// If true, renders the crest as a solid-color silhouette (useful on a
  /// colored hero background). If false, renders the crest in its full
  /// original color. Either way, no background box is drawn.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: filled
          ? ColorFiltered(
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
              child: _crest(),
            )
          : _crest(),
    );
  }

  Widget _crest() {
    return Image.asset(
      kAppLogoAssetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.shield_outlined,
        color: filled ? AppColors.primary : AppColors.primary,
        size: size * 0.85,
      ),
    );
  }
}

/// Small inline wordmark: crest glyph + "SchoolGuardian" text, used in the
/// top nav/header of full-page flows like the landing page and dashboard.
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key, this.iconColor, this.textColor});

  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Image.asset(
            kAppLogoAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.shield_outlined,
              color: iconColor ?? AppColors.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'SchoolGuardian',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: textColor ?? AppColors.onSurface,
              ),
        ),
      ],
    );
  }
}
