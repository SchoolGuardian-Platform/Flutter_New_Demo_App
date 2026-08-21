import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screen_time_models.dart';

/// Manages student screen usage metrics, local telemetry, app limits,
/// and downtime schedules using SharedPreferences.
class ScreenTimeService {
  factory ScreenTimeService() => _instance;
  ScreenTimeService._internal();
  static final ScreenTimeService _instance = ScreenTimeService._internal();

  static const String _appUsagesKeyPrefix = 'screen_time_apps_v1_';
  static const String _goalKeyPrefix = 'screen_time_goal_v1_';
  static const String _logsKeyPrefix = 'screen_time_logs_v1_';

  /// Default mock apps generated for high fidelity offline usage tracking.
  List<AppUsageItem> _generateDefaultApps() {
    final now = DateTime.now();
    return [
      AppUsageItem(
        id: 'app_1',
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        category: AppCategory.social,
        minutesUsed: 65,
        timeLimitMinutes: 45, // Exceeded
        lastUsed: now.subtract(const Duration(minutes: 15)),
      ),
      AppUsageItem(
        id: 'app_2',
        appName: 'Roblox',
        packageName: 'com.roblox.client',
        category: AppCategory.gaming,
        minutesUsed: 50,
        timeLimitMinutes: 60,
        lastUsed: now.subtract(const Duration(minutes: 40)),
      ),
      AppUsageItem(
        id: 'app_3',
        appName: 'Google Classroom',
        packageName: 'com.google.android.apps.classroom',
        category: AppCategory.education,
        minutesUsed: 40,
        timeLimitMinutes: 0,
        lastUsed: now.subtract(const Duration(minutes: 5)),
      ),
      AppUsageItem(
        id: 'app_4',
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        category: AppCategory.entertainment,
        minutesUsed: 35,
        timeLimitMinutes: 30, // Exceeded
        lastUsed: now.subtract(const Duration(minutes: 50)),
      ),
      AppUsageItem(
        id: 'app_5',
        appName: 'Duolingo',
        packageName: 'com.duolingo',
        category: AppCategory.education,
        minutesUsed: 25,
        timeLimitMinutes: 0,
        lastUsed: now.subtract(const Duration(hours: 2)),
      ),
      AppUsageItem(
        id: 'app_6',
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        category: AppCategory.social,
        minutesUsed: 20,
        timeLimitMinutes: 30,
        lastUsed: now.subtract(const Duration(hours: 3)),
      ),
      AppUsageItem(
        id: 'app_7',
        appName: 'Notion & Notes',
        packageName: 'com.notion.id',
        category: AppCategory.productivity,
        minutesUsed: 15,
        timeLimitMinutes: 0,
        lastUsed: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  /// Get total screen time summary for a student ID.
  Future<ScreenTimeSummary> getSummary(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final appsKey = '$_appUsagesKeyPrefix$studentId';
    final goalKey = '$_goalKeyPrefix$studentId';

    // Load App Usages
    List<AppUsageItem> apps = [];
    final rawAppsJson = prefs.getString(appsKey);
    if (rawAppsJson != null && rawAppsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(rawAppsJson);
        apps = decoded
            .map((e) => AppUsageItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        apps = _generateDefaultApps();
      }
    } else {
      apps = _generateDefaultApps();
      await _saveApps(studentId, apps);
    }

    // Load Goal
    ScreenTimeGoal goal = const ScreenTimeGoal();
    final rawGoalJson = prefs.getString(goalKey);
    if (rawGoalJson != null && rawGoalJson.isNotEmpty) {
      try {
        goal = ScreenTimeGoal.fromJson(
            jsonDecode(rawGoalJson) as Map<String, dynamic>);
      } catch (_) {}
    }

    final todayMinutes =
        apps.fold<int>(0, (sum, item) => sum + item.minutesUsed);

    // Calculate category breakdown
    final categoryTotals = <AppCategory, int>{};
    for (final a in apps) {
      categoryTotals[a.category] =
          (categoryTotals[a.category] ?? 0) + a.minutesUsed;
    }

    AppCategory topCat = AppCategory.utilities;
    int maxCatMins = -1;
    categoryTotals.forEach((cat, mins) {
      if (mins > maxCatMins) {
        maxCatMins = mins;
        topCat = cat;
      }
    });

    // Generate 7-day weekly history logs
    final weeklyLogs = _generateWeeklyLogs(apps);
    final weeklyAvg = (weeklyLogs.fold<int>(
                0, (sum, log) => sum + log.totalMinutes) /
            weeklyLogs.length)
        .round();

    return ScreenTimeSummary(
      todayMinutes: todayMinutes,
      yesterdayMinutes: 210, // 3h 30m yesterday
      weeklyAverageMinutes: weeklyAvg,
      topCategory: topCat,
      appUsages: apps,
      weeklyLogs: weeklyLogs,
      goal: goal,
    );
  }

  /// Update individual app limit in minutes (0 means remove limit).
  Future<void> setAppLimit({
    required String studentId,
    required String appId,
    required int limitMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final appsKey = '$_appUsagesKeyPrefix$studentId';
    final summary = await getSummary(studentId);

    final updatedApps = summary.appUsages.map((app) {
      if (app.id == appId) {
        return app.copyWith(timeLimitMinutes: limitMinutes);
      }
      return app;
    }).toList();

    await _saveApps(studentId, updatedApps);
  }

  /// Update overall daily goal & downtime schedule for student.
  Future<void> updateGoal({
    required String studentId,
    required ScreenTimeGoal goal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final goalKey = '$_goalKeyPrefix$studentId';
    await prefs.setString(goalKey, jsonEncode(goal.toJson()));
  }

  Future<void> _saveApps(String studentId, List<AppUsageItem> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final appsKey = '$_appUsagesKeyPrefix$studentId';
    final jsonStr = jsonEncode(apps.map((e) => e.toJson()).toList());
    await prefs.setString(appsKey, jsonStr);
  }

  List<DailyScreenTime> _generateWeeklyLogs(List<AppUsageItem> todayApps) {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mockTotals = [180, 210, 195, 240, 220, 260, 250];

    final logs = <DailyScreenTime>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final total = i == 0
          ? todayApps.fold<int>(0, (sum, a) => sum + a.minutesUsed)
          : mockTotals[6 - i];

      logs.add(DailyScreenTime(
        date: dateStr,
        totalMinutes: total,
        appUsages: i == 0 ? todayApps : [],
      ));
    }
    return logs;
  }
}
