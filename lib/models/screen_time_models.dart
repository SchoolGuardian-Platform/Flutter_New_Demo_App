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

/// Represents total screen time for a specific date.
class DailyScreenTime {
  final String date; // 'YYYY-MM-DD'
  final int totalMinutes;
  final List<AppUsageItem> appUsages;

  const DailyScreenTime({
    required this.date,
    required this.totalMinutes,
    required this.appUsages,
  });

  Map<AppCategory, int> get categoryTotals {
    final totals = <AppCategory, int>{};
    for (final app in appUsages) {
      totals[app.category] = (totals[app.category] ?? 0) + app.minutesUsed;
    }
    return totals;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalMinutes': totalMinutes,
      'appUsages': appUsages.map((e) => e.toJson()).toList(),
    };
  }

  factory DailyScreenTime.fromJson(Map<String, dynamic> json) {
    final list = json['appUsages'] is List
        ? (json['appUsages'] as List)
            .map((e) => AppUsageItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : <AppUsageItem>[];
    return DailyScreenTime(
      date: json['date'] as String? ?? '',
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      appUsages: list,
    );
  }
}

/// Parent or student configured daily screen time goal & downtime schedule.
class ScreenTimeGoal {
  final int dailyLimitMinutes; // Total daily screen time limit in minutes
  final String downtimeStart; // e.g. "21:00"
  final String downtimeEnd; // e.g. "07:00"
  final bool isDowntimeEnabled;

  const ScreenTimeGoal({
    this.dailyLimitMinutes = 180, // Default 3 hours
    this.downtimeStart = '21:00',
    this.downtimeEnd = '07:00',
    this.isDowntimeEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'dailyLimitMinutes': dailyLimitMinutes,
      'downtimeStart': downtimeStart,
      'downtimeEnd': downtimeEnd,
      'isDowntimeEnabled': isDowntimeEnabled,
    };
  }

  factory ScreenTimeGoal.fromJson(Map<String, dynamic> json) {
    return ScreenTimeGoal(
      dailyLimitMinutes:
          (json['dailyLimitMinutes'] as num?)?.toInt() ?? 180,
      downtimeStart: json['downtimeStart'] as String? ?? '21:00',
      downtimeEnd: json['downtimeEnd'] as String? ?? '07:00',
      isDowntimeEnabled: json['isDowntimeEnabled'] as bool? ?? true,
    );
  }
}

/// Overall screen time analytics summary.
class ScreenTimeSummary {
  final int todayMinutes;
  final int yesterdayMinutes;
  final int weeklyAverageMinutes;
  final AppCategory topCategory;
  final List<AppUsageItem> appUsages;
  final List<DailyScreenTime> weeklyLogs;
  final ScreenTimeGoal goal;

  const ScreenTimeSummary({
    required this.todayMinutes,
    required this.yesterdayMinutes,
    required this.weeklyAverageMinutes,
    required this.topCategory,
    required this.appUsages,
    required this.weeklyLogs,
    required this.goal,
  });

  bool get isLimitExceeded => todayMinutes > goal.dailyLimitMinutes;

  double get todayLimitRatio =>
      goal.dailyLimitMinutes > 0 ? (todayMinutes / goal.dailyLimitMinutes) : 0.0;

  String get formattedTodayUsage {
    final hours = todayMinutes ~/ 60;
    final mins = todayMinutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours}h ${mins}m';
  }

  Map<AppCategory, int> get categoryBreakdown {
    final map = <AppCategory, int>{};
    for (final app in appUsages) {
      map[app.category] = (map[app.category] ?? 0) + app.minutesUsed;
    }
    return map;
  }
}

