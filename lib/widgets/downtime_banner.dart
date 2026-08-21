import 'package:flutter/material.dart';
import '../models/screen_time_models.dart';
import '../theme/app_theme.dart';

/// Renders active downtime schedule status (e.g. Bedtime lock 21:00 - 07:00)
/// and daily screen time allowance configuration banner.
class DowntimeBanner extends StatelessWidget {
  const DowntimeBanner({
    super.key,
    required this.goal,
    this.onToggleDowntime,
    this.onEditGoal,
    this.isEditable = false,
  });

  final ScreenTimeGoal goal;
  final ValueChanged<bool>? onToggleDowntime;
  final VoidCallback? onEditGoal;
  final bool isEditable;

  @override
  Widget build(BuildContext context) {
    final hours = goal.dailyLimitMinutes ~/ 60;
    final mins = goal.dailyLimitMinutes % 60;
    final limitStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: goal.isDowntimeEnabled
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bedtime_rounded,
                  color: Color(0xFFA5B4FC),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Downtime & Bedtime Lock',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: goal.isDowntimeEnabled
                                ? const Color(0xFF10B981).withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            goal.isDowntimeEnabled ? 'ACTIVE' : 'OFF',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: goal.isDowntimeEnabled
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Schedule: ${goal.downtimeStart} – ${goal.downtimeEnd} daily',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC7D2FE),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (isEditable && onToggleDowntime != null)
                Switch.adaptive(
                  value: goal.isDowntimeEnabled,
                  onChanged: onToggleDowntime,
                  activeThumbColor: const Color(0xFF818CF8),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: Color(0xFF4338CA), height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFFA5B4FC),
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Daily Allowance: $limitStr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isEditable && onEditGoal != null)
                GestureDetector(
                  onTap: onEditGoal,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Edit Goal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
