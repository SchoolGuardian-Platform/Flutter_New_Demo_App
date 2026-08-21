import 'package:flutter/material.dart';

/// Categories of app usage on a student's device.
enum AppCategory {
  social,
  gaming,
  education,
  productivity,
  entertainment,
  utilities,
}

extension AppCategoryExtension on AppCategory {
  String get label {
    switch (this) {
      case AppCategory.social:
        return 'Social Media';
      case AppCategory.gaming:
        return 'Gaming';
      case AppCategory.education:
        return 'Educational';
      case AppCategory.productivity:
        return 'Productivity';
      case AppCategory.entertainment:
        return 'Entertainment';
      case AppCategory.utilities:
        return 'Utilities & System';
    }
  }

  IconData get icon {
    switch (this) {
      case AppCategory.social:
        return Icons.chat_bubble_rounded;
      case AppCategory.gaming:
        return Icons.sports_esports_rounded;
      case AppCategory.education:
        return Icons.school_rounded;
      case AppCategory.productivity:
        return Icons.assignment_turned_in_rounded;
      case AppCategory.entertainment:
        return Icons.movie_creation_rounded;
      case AppCategory.utilities:
        return Icons.build_circle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AppCategory.social:
        return const Color(0xFF8B5CF6); // Violet / Purple
      case AppCategory.gaming:
        return const Color(0xFFEF4444); // Red / Orange
      case AppCategory.education:
        return const Color(0xFF10B981); // Emerald / Green
      case AppCategory.productivity:
        return const Color(0xFF3B82F6); // Blue
      case AppCategory.entertainment:
        return const Color(0xFFF59E0B); // Amber
      case AppCategory.utilities:
        return const Color(0xFF64748B); // Slate
    }
  }
}

/// Represents individual app usage on a student's device.
class AppUsageItem {
  final String id;
  final String appName;
  final String packageName;
  final AppCategory category;
  final int minutesUsed;
  final int timeLimitMinutes; // 0 means no explicit limit set
  final DateTime lastUsed;

  const AppUsageItem({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.category,
    required this.minutesUsed,
    this.timeLimitMinutes = 0,
    required this.lastUsed,
  });

  bool get isLimitExceeded =>
      timeLimitMinutes > 0 && minutesUsed > timeLimitMinutes;

  double get limitRatio => timeLimitMinutes > 0
      ? (minutesUsed / timeLimitMinutes).clamp(0.0, 1.5)
      : 0.0;

  AppUsageItem copyWith({
    String? id,
    String? appName,
    String? packageName,
    AppCategory? category,
    int? minutesUsed,
    int? timeLimitMinutes,
    DateTime? lastUsed,
  }) {
    return AppUsageItem(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      category: category ?? this.category,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appName': appName,
      'packageName': packageName,
      'category': category.name,
      'minutesUsed': minutesUsed,
      'timeLimitMinutes': timeLimitMinutes,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory AppUsageItem.fromJson(Map<String, dynamic> json) {
    return AppUsageItem(
      id: json['id'] as String? ?? '',
      appName: json['appName'] as String? ?? 'Unknown App',
      packageName: json['packageName'] as String? ?? '',
      category: AppCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AppCategory.utilities,
      ),
      minutesUsed: (json['minutesUsed'] as num?)?.toInt() ?? 0,
      timeLimitMinutes: (json['timeLimitMinutes'] as num?)?.toInt() ?? 0,
      lastUsed: json['lastUsed'] != null
          ? DateTime.tryParse(json['lastUsed'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
