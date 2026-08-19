import 'package:flutter/material.dart';
import '../models/health_overview_models.dart';
import 'weekly_sleep_bar_chart.dart';

class SleepOverviewCard extends StatelessWidget {
  const SleepOverviewCard({
    super.key,
    required this.durationText,
    required this.qualityStatus,
    required this.weeklyDays,
    required this.onTapNavigation,
  });

  final String durationText;
  final String qualityStatus;
  final List<SleepDayMetric> weeklyDays;
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
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sleep Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
                onPressed: onTapNavigation,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Left Metric: Large Duration + Quality Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        qualityStatus,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Right Chart: Segmented Vertical Pill Bars
              SizedBox(
                width: 140,
                child: WeeklySleepBarChart(
                  days: weeklyDays,
                  maxHours: 9.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
