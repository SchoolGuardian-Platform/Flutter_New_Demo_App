import 'package:flutter/material.dart';
import '../models/screen_time_models.dart';
import '../theme/app_theme.dart';

/// Renders a single application usage row with duration, category tag, limit ratio,
/// and optional parental limit edit trigger.
class AppUsageListTile extends StatelessWidget {
  const AppUsageListTile({
    super.key,
    required this.item,
    this.onTapLimit,
    this.showLimitControls = false,
  });

  final AppUsageItem item;
  final VoidCallback? onTapLimit;
  final bool showLimitControls;

  @override
  Widget build(BuildContext context) {
    final hours = item.minutesUsed ~/ 60;
    final mins = item.minutesUsed % 60;
    final timeDisplay = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    final hasLimit = item.timeLimitMinutes > 0;
    final ratio = item.limitRatio.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: item.isLimitExceeded
              ? AppColors.error.withValues(alpha: 0.5)
              : const Color(0xFFE2E8F0),
          width: item.isLimitExceeded ? 1.5 : 1.0,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          // App Icon Container (Authentic Brand Logos & Emblems)
          _RealAppLogo(item: item),
          const SizedBox(width: AppSpacing.md),

          // App info & progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.appName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isLimitExceeded) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Limit Exceeded',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: item.isLimitExceeded
                            ? AppColors.error
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Category Tag & Limit text
                Row(
                  children: [
                    Text(
                      item.category.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: item.category.color,
                      ),
                    ),
                    if (hasLimit) ...[
                      const Text(
                        ' · ',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        'Limit: ${item.timeLimitMinutes}m',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: item.isLimitExceeded
                              ? AppColors.error
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasLimit) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.isLimitExceeded
                            ? AppColors.error
                            : item.category.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Optional Parental Limit Edit Action
          if (showLimitControls && onTapLimit != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onTapLimit,
              icon: Icon(
                hasLimit ? Icons.tune_rounded : Icons.add_circle_outline_rounded,
                size: 20,
                color: hasLimit ? AppColors.primary : const Color(0xFF64748B),
              ),
              tooltip: 'Set app limit',
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders authentic app brand logos with real brand colors, gradients, and emblems.
class _RealAppLogo extends StatelessWidget {
  const _RealAppLogo({required this.item});

  final AppUsageItem item;

  @override
  Widget build(BuildContext context) {
    final name = item.appName.toLowerCase();
    final pkg = item.packageName.toLowerCase();

    // Default container styling
    Color bgColor = item.category.color.withValues(alpha: 0.15);
    Gradient? gradient;
    Widget logoChild = Icon(item.category.icon, color: item.category.color, size: 22);

    if (name.contains('tiktok') || pkg.contains('musically')) {
      bgColor = const Color(0xFF000000);
      logoChild = Stack(
        alignment: Alignment.center,
        children: const [
          Icon(Icons.music_note_rounded, color: Color(0xFF25F4EE), size: 23),
          Icon(Icons.music_note_rounded, color: Color(0xFFFE2C55), size: 22),
          Icon(Icons.music_note_rounded, color: Colors.white, size: 20),
        ],
      );
    } else if (name.contains('roblox') || pkg.contains('roblox')) {
      bgColor = const Color(0xFF000000);
      logoChild = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFE60012),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Transform(
            transform: Matrix4.rotationZ(0.2),
            alignment: Alignment.center,
            child: const Icon(Icons.crop_square_rounded, color: Colors.white, size: 14),
          ),
        ),
      );
    } else if (name.contains('classroom') || pkg.contains('classroom')) {
      bgColor = const Color(0xFF0F9D58);
      logoChild = const Icon(Icons.school_rounded, color: Colors.white, size: 22);
    } else if (name.contains('youtube') || pkg.contains('youtube')) {
      bgColor = const Color(0xFFFF0000);
      logoChild = Container(
        width: 22,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Icon(Icons.play_arrow_rounded, color: Color(0xFFFF0000), size: 14),
        ),
      );
    } else if (name.contains('duolingo') || pkg.contains('duolingo')) {
      bgColor = const Color(0xFF58CC02);
      logoChild = const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22);
    } else if (name.contains('instagram') || pkg.contains('instagram')) {
      gradient = const LinearGradient(
        colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      );
      logoChild = const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22);
    } else if (name.contains('notion') || pkg.contains('notion')) {
      bgColor = const Color(0xFF000000);
      logoChild = const Icon(Icons.edit_note_rounded, color: Colors.white, size: 24);
    } else if (name.contains('snapchat') || pkg.contains('snapchat')) {
      bgColor = const Color(0xFFFFFC00);
      logoChild = const Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.black, size: 22);
    } else if (name.contains('spotify') || pkg.contains('spotify')) {
      bgColor = const Color(0xFF1DB954);
      logoChild = const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 22);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: item.realLogoUrl.isNotEmpty
            ? Image.network(
                item.realLogoUrl,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => logoChild,
              )
            : logoChild,
      ),
    );
  }
}
