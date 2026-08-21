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
          // App Icon Container (Real App Logo)
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.realLogoUrl.isNotEmpty
                  ? const Color(0xFFF8FAFC)
                  : item.category.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.realLogoUrl.isNotEmpty
                    ? const Color(0xFFE2E8F0)
                    : Colors.transparent,
              ),
            ),
            child: item.realLogoUrl.isNotEmpty
                ? Image.network(
                    item.realLogoUrl,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      item.category.icon,
                      color: item.category.color,
                      size: 22,
                    ),
                  )
                : Icon(
                    item.category.icon,
                    color: item.category.color,
                    size: 22,
                  ),
          ),
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
