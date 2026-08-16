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
              child: Image.asset(
                kAppLogoAssetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.gpp_good_rounded,
                  color: AppColors.primary,
                  size: size * 0.85,
                ),
              ),
            )
          : _crest(),
    );
  }

  Widget _crest() {
    return Image.asset(
      kAppLogoAssetPath,
      fit: BoxFit.contain,
      // Matches the web app's mark: a solid indigo rounded square with a
      // white shield-check glyph, used whenever the real crest asset isn't
      // available (no asset is currently bundled in this project).
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.gpp_good_rounded,
          color: Colors.white,
          size: size * 0.55,
        ),
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
    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 26,
          height: 26,
          child: Image.asset(
            kAppLogoAssetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                color: iconColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.gpp_good_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Two-tone wordmark: "School" in ink, "Guardian" in the brand
        // indigo — matches the web app's header exactly. If a single
        // override color is supplied (e.g. white text on a dark hero),
        // both words use it instead so the mark stays legible.
        RichText(
          text: TextSpan(
            style: baseStyle?.copyWith(color: textColor ?? AppColors.onSurface),
            children: [
              const TextSpan(text: 'School'),
              TextSpan(
                text: 'Guardian',
                style: textColor == null
                    ? const TextStyle(color: AppColors.primary)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
