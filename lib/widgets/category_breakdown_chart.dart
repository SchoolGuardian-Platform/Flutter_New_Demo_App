import 'package:flutter/material.dart';
import '../models/screen_time_models.dart';
import '../theme/app_theme.dart';

/// A segmented horizontal bar and legend displaying screen time usage per category.
class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({
    super.key,
    required this.categoryBreakdown,
    required this.totalMinutes,
  });

  final Map<AppCategory, int> categoryBreakdown;
  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    if (totalMinutes <= 0 || categoryBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        child: Text(
          'No app activity logged yet today.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
      );
    }

    final sortedEntries = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category Distribution',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
            ),
            Text(
              '${sortedEntries.length} Categories',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Segmented Horizontal Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 16,
            child: Row(
              children: sortedEntries.map((entry) {
                final ratio = entry.value / totalMinutes;
                return Expanded(
                  flex: (ratio * 1000).round().clamp(1, 1000),
                  child: Container(
                    color: entry.key.color,
                    margin: const EdgeInsets.only(right: 1.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Grid Legend Items
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: sortedEntries.map((entry) {
            final percentage = ((entry.value / totalMinutes) * 100).round();
            final hours = entry.value ~/ 60;
            final mins = entry.value % 60;
            final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: entry.key.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: entry.key.color.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: entry.key.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(entry.key.icon, size: 14, color: entry.key.color),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key.label} · ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: entry.key.color,
                    ),
                  ),
                  Text(
                    '$timeStr ($percentage%)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
