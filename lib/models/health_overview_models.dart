import 'package:flutter/material.dart';

/// Data Model for Weekly Sleep History Day
class SleepDayMetric {
  const SleepDayMetric({
    required this.dayLabel, // 'M', 'T', 'W', 'T', 'F', 'S', 'S'
    required this.hours, // e.g. 6.8
    this.isHighlighted = false,
  });

  final String dayLabel;
  final double hours;
  final bool isHighlighted;
}

/// Data Model for Vital Metric Card
class VitalMetricItem {
  const VitalMetricItem({
    required this.title,
    required this.value,
    required this.unit,
    required this.trendPercentage, // e.g. '+ 10%' or '↓ 10%'
    required this.isPositiveTrend,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String unit;
  final String trendPercentage;
  final bool isPositiveTrend;
  final IconData icon;
  final Color accentColor;
}

/// Data Model for Today's Digest Recommendation
class DigestRecommendation {
  const DigestRecommendation({
    required this.categoryLabel,
    required this.headline,
    required this.bodyText,
    required this.icon,
  });

  final String categoryLabel;
  final String headline;
  final String bodyText;
  final IconData icon;
}
