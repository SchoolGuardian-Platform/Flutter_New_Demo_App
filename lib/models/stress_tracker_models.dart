import 'package:flutter/material.dart';

/// Data Point for Stress Level Chart
class StressChartPoint {
  const StressChartPoint({
    required this.timestamp,
    required this.value, // 0 to 100
  });

  final String timestamp;
  final double value;
}

/// Data Item for Stress Level Breakdown (HIGH, MED, LOW)
class StressLevelBreakdownItem {
  const StressLevelBreakdownItem({
    required this.levelName, // 'HIGH', 'MED', 'LOW'
    required this.percentage, // 0 to 100
    required this.formattedDuration, // e.g. '0:56:0'
    required this.color,
    required this.filledRatio, // 0.0 to 1.0
  });

  final String levelName;
  final int percentage;
  final String formattedDuration;
  final Color color;
  final double filledRatio;
}

/// Secondary Biometric Trend Metric Item
class BiometricTrendMetric {
  const BiometricTrendMetric({
    required this.title,
    required this.value,
    required this.unit,
    required this.statusText,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String unit;
  final String statusText;
  final IconData icon;
  final Color color;
}
