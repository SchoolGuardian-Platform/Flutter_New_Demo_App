import 'package:flutter/material.dart';

/// Data Model for Nutrition Calorie Target
class NutritionCalorieSummary {
  const NutritionCalorieSummary({
    required this.baseTarget,
    required this.consumed,
    required this.activeBurned,
  });

  final int baseTarget;
  final int consumed;
  final int activeBurned;

  int get remaining => (baseTarget + activeBurned) - consumed;
  double get progressFraction => (baseTarget > 0) ? (consumed / baseTarget).clamp(0.0, 1.0) : 0.0;
}

/// Data Model for Macro Nutrient Item
class MacroItem {
  const MacroItem({
    required this.name,
    required this.currentGrams,
    required this.targetGrams,
    required this.color,
  });

  final String name;
  final int currentGrams;
  final int targetGrams;
  final Color color;

  double get fraction => targetGrams > 0 ? (currentGrams / targetGrams).clamp(0.0, 1.0) : 0.0;
  int get percentage => (fraction * 100).round();
}

/// Data Model for Active Calorie Activity
class ActiveCalorieActivity {
  const ActiveCalorieActivity({
    required this.totalBurned,
    required this.hourlyTicks, // Values between 0.0 and 1.0 for the equalizer bars
  });

  final int totalBurned;
  final List<double> hourlyTicks;
}
