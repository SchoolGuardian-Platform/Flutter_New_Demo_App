import 'package:flutter/material.dart';
import '../models/screen_time_models.dart';
import '../theme/app_theme.dart';

/// 7-day screen time histogram showing daily minutes vs configured daily limit threshold.
class DailyUsageHistogram extends StatelessWidget {
  const DailyUsageHistogram({
    super.key,
    required this.weeklyLogs,
    required this.dailyLimitMinutes,
  });

  final List<DailyScreenTime> weeklyLogs;
  final int dailyLimitMinutes;

  @override
  Widget build(BuildContext context) {
    if (weeklyLogs.isEmpty) return const SizedBox.shrink();

    // Determine max value for scaling bar heights
    int maxMins = dailyLimitMinutes > 0 ? dailyLimitMinutes : 180;
    for (final log in weeklyLogs) {
      if (log.totalMinutes > maxMins) maxMins = log.totalMinutes;
    }
    if (maxMins <= 0) maxMins = 1;

    final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Usage Trend',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Under Limit',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Exceeded',
                    style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Histogram Bars
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(weeklyLogs.length, (index) {
                final log = weeklyLogs[index];
                final ratio = (log.totalMinutes / maxMins).clamp(0.08, 1.0);
                final isExceeded =
                    dailyLimitMinutes > 0 && log.totalMinutes > dailyLimitMinutes;
                final isToday = index == weeklyLogs.length - 1;

                final dayLabel = isToday ? 'Today' : daysOfWeek[index % 7];

                final hours = log.totalMinutes ~/ 60;
                final mins = log.totalMinutes % 60;
                final durationStr =
                    hours > 0 ? '${hours}h${mins}m' : '${mins}m';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      durationStr,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight:
                            isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isExceeded
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Animated Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isToday ? 22 : 18,
                      height: 80 * ratio,
                      decoration: BoxDecoration(
                        color: isExceeded
                            ? const Color(0xFFEF4444)
                            : (isToday
                                ? AppColors.primary
                                : const Color(0xFF10B981)),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: isToday
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isToday ? FontWeight.w900 : FontWeight.w600,
                        color: isToday
                            ? AppColors.primary
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
