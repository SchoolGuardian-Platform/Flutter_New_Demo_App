import 'package:flutter/material.dart';
import '../models/stress_tracker_models.dart';
import 'segmented_tick_bar.dart';

class StressOverviewCard extends StatelessWidget {
  const StressOverviewCard({
    super.key,
    required this.breakdowns,
    required this.totalDuration,
    required this.onTapNavigation,
  });

  final List<StressLevelBreakdownItem> breakdowns;
  final String totalDuration;
  final VoidCallback onTapNavigation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Red Indicator Dot + "Stress Overview" + "Duration 10:30:00"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Stress Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Duration $totalDuration',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
                    onPressed: onTapNavigation,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Level Rows (HIGH, MED, LOW)
          for (final item in breakdowns) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  // Level Label (HIGH, MED, LOW)
                  SizedBox(
                    width: 44,
                    child: Text(
                      item.levelName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: item.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Horizontal Segmented Vertical-Tick Bar
                  Expanded(
                    child: SegmentedTickBar(
                      color: item.color,
                      filledRatio: item.filledRatio,
                      totalTicks: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right Metric Column: Percentage & Formatted Duration
                  SizedBox(
                    width: 90,
                    child: Text(
                      '${item.percentage}% ${item.formattedDuration}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
