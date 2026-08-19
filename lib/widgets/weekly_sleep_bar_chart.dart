import 'package:flutter/material.dart';
import '../models/health_overview_models.dart';

/// Weekly Sleep Bar Chart widget with highlighted current/highest day pill bars
class WeeklySleepBarChart extends StatelessWidget {
  const WeeklySleepBarChart({
    super.key,
    required this.days,
    required this.maxHours,
  });

  final List<SleepDayMetric> days;
  final double maxHours;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final day in days)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 10,
                  height: ((day.hours / maxHours) * 44).clamp(10.0, 44.0),
                  decoration: BoxDecoration(
                    color: day.isHighlighted
                        ? const Color(0xFF7C3AED) // Solid Deep Purple
                        : const Color(0xFFE9D5FF), // Soft Lilac
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.dayLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: day.isHighlighted ? FontWeight.bold : FontWeight.w500,
                    color: day.isHighlighted
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
