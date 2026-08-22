import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/screen_time_models.dart';

// NOTE: requires the `android_intent_plus` package to deep-link the user to
// Android's "Usage Access" screen. There is no runtime permission dialog for
// this permission (see the doc comment on `openUsageAccessSettings` below),
// and the `app_settings` package does NOT expose this screen — it has no
// `usageAccess` entry in its `AppSettingsType` enum — so a raw Android
// intent is the only way to deep-link there.
// Add to pubspec.yaml:
//   android_intent_plus: ^5.2.0
import 'package:android_intent_plus/android_intent.dart';

/// Manages student screen usage metrics, local telemetry, app limits,
/// and downtime schedules using SharedPreferences and device UsageStats.
class ScreenTimeService {
  factory ScreenTimeService() => _instance;
  ScreenTimeService._internal();
  static final ScreenTimeService _instance = ScreenTimeService._internal();

  static const String _appUsagesKeyPrefix = 'screen_time_apps_v2_';
  static const String _goalKeyPrefix = 'screen_time_goal_v1_';

  /// True after the most recent [fetchRealDeviceUsageStats] call actually
  /// got data back from the OS. False means we're showing generated/mock
  /// data — either because the platform doesn't expose usage stats (iOS,
  /// web) or, on Android, because the "Usage Access" special permission
  /// hasn't been granted yet.
  ///
  /// IMPORTANT (this is almost certainly your real-device issue):
  /// `app_usage` reads Android's UsageStatsManager, which is gated behind
  /// the PACKAGE_USAGE_STATS permission. That permission:
  ///   1. Must be declared in android/app/src/main/AndroidManifest.xml:
  ///        <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
  ///            tools:ignore="ProtectedPermissions" />
  ///   2. CANNOT be granted via a normal runtime permission popup. The user
  ///      must manually enable it in
  ///      Settings > Apps > Special app access > Usage access.
  /// When it isn't granted, `getAppUsage()` does NOT throw — it just
  /// returns an empty list — which is why this was failing silently and
  /// falling back to the bundled mock apps with no visible error.
  ///
  /// Also note: on iOS there is no public API for reading other apps'
  /// usage at all (Apple's DeviceActivity/Screen Time API requires a
  /// special entitlement and doesn't work like this), so this will always
  /// be mock data on iOS regardless of permissions.
  bool lastFetchUsedRealData = false;

  /// Opens the OS screen where the user grants Usage Access. There's no
  /// way to grant this permission programmatically or via a normal
  /// permission_handler-style dialog — an explicit Android intent to
  /// `Settings.ACTION_USAGE_ACCESS_SETTINGS` is the only option, and only
  /// works on Android (no iOS equivalent exists).
  Future<void> openUsageAccessSettings() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;
    const intent = AndroidIntent(
      action: 'android.settings.USAGE_ACCESS_SETTINGS',
    );
    await intent.launch();
  }

  /// Query native Android/iOS OS for real device app usage statistics today.
  Future<List<AppUsageItem>> fetchRealDeviceUsageStats() async {
    if (kIsWeb) {
      lastFetchUsedRealData = false;
      return [];
    }

    try {
      final now = DateTime.now();
      // Look back from 24 hours ago to cover today's full device session
      final startDate = now.subtract(Duration(hours: now.hour, minutes: now.minute, seconds: now.second));
      final endDate = now;

      final infoList = await AppUsage().getAppUsage(startDate, endDate);
      if (infoList.isEmpty) {
        // Empty result on a real device almost always means the Usage
        // Access permission isn't granted yet (see doc comment above) —
        // app_usage doesn't throw for this, it just returns nothing.
        lastFetchUsedRealData = false;
        return [];
      }

      final realApps = <AppUsageItem>[];
      for (int i = 0; i < infoList.length; i++) {
        final info = infoList[i];
        final seconds = info.usage.inSeconds;
        if (seconds <= 5) continue; // Ignore system noise < 5 sec

        final pkg = info.packageName.toLowerCase();

        // Exclude Android internal system OS noise, launchers, and keyboards
        if (_isSystemPackage(pkg)) continue;

        final mins = info.usage.inMinutes > 0 ? info.usage.inMinutes : 1;
        final resolvedName = _resolveAppName(info.packageName, info.appName);

        // Determine category based on package or app name
        AppCategory cat = AppCategory.utilities;
        if (pkg.contains('social') || pkg.contains('musically') || pkg.contains('instagram') || pkg.contains('facebook') || pkg.contains('twitter') || pkg.contains('tiktok') || pkg.contains('snapchat') || pkg.contains('whatsapp')) {
          cat = AppCategory.social;
        } else if (pkg.contains('game') || pkg.contains('roblox') || pkg.contains('minecraft') || pkg.contains('pubg') || pkg.contains('clash') || pkg.contains('chess') || pkg.contains('lichess') || pkg.contains('puzzle') || pkg.contains('arcade') || pkg.contains('sudoku') || pkg.contains('cards') || pkg.contains('play')) {
          cat = AppCategory.gaming;
        } else if (pkg.contains('youtube') || pkg.contains('netflix') || pkg.contains('hulu') || pkg.contains('video') || pkg.contains('spotify')) {
          cat = AppCategory.entertainment;
        } else if (pkg.contains('classroom') || pkg.contains('duolingo') || pkg.contains('canvas') || pkg.contains('learn') || pkg.contains('school')) {
          cat = AppCategory.education;
        } else if (pkg.contains('note') || pkg.contains('notion') || pkg.contains('office') || pkg.contains('doc') || pkg.contains('chrome') || pkg.contains('browser')) {
          cat = AppCategory.productivity;
        }

        realApps.add(AppUsageItem(
          id: 'real_app_${info.packageName}_$i',
          appName: resolvedName,
          packageName: info.packageName,
          category: cat,
          minutesUsed: mins,
          timeLimitMinutes: cat == AppCategory.social ? 45 : (cat == AppCategory.gaming ? 60 : 0),
          lastUsed: info.endDate,
        ));
      }

      realApps.sort((a, b) => b.minutesUsed.compareTo(a.minutesUsed));
      lastFetchUsedRealData = realApps.isNotEmpty;
      return realApps;
    } catch (e) {
      debugPrint('Real device AppUsage query notice: $e');
      lastFetchUsedRealData = false;
      return [];
    }
  }

  /// Checks if a package is internal Android OS background noise (System UI, Launcher, Keyboards)
  static bool _isSystemPackage(String pkg) {
    if (pkg.contains('systemui') ||
        pkg.contains('launcher') ||
        pkg.contains('inputmethod') ||
        pkg.contains('keyboard') ||
        pkg.contains('honeyboard') ||
        pkg.contains('providers.') ||
        pkg.contains('permissioncontroller') ||
        pkg.contains('packageinstaller') ||
        pkg.contains('qualcomm') ||
        pkg.contains('incallui') ||
        pkg.contains('android.settings') ||
        pkg == 'android' ||
        pkg == 'com.android.phone') {
      return true;
    }
    return false;
  }

  /// Maps Android raw package names to clean human-readable application titles.
  static String _resolveAppName(String packageName, String rawAppName) {
    if (rawAppName.isNotEmpty && !rawAppName.contains('.')) return rawAppName;
    final pkg = packageName.toLowerCase();

    if (pkg.contains('musically') || pkg.contains('tiktok')) return 'TikTok';
    if (pkg.contains('roblox')) return 'Roblox';
    if (pkg.contains('youtube')) return 'YouTube';
    if (pkg.contains('classroom')) return 'Google Classroom';
    if (pkg.contains('instagram')) return 'Instagram';
    if (pkg.contains('duolingo')) return 'Duolingo';
    if (pkg.contains('notion')) return 'Notion & Notes';
    if (pkg.contains('whatsapp')) return 'WhatsApp';
    if (pkg.contains('facebook')) return 'Facebook';
    if (pkg.contains('snapchat')) return 'Snapchat';
    if (pkg.contains('spotify')) return 'Spotify';
    if (pkg.contains('chrome')) return 'Google Chrome';
    if (pkg.contains('lichess')) return 'Lichess';
    if (pkg.contains('chess.clock')) return 'Chess Clock';
    if (pkg.contains('chess')) return 'Chess';
    if (pkg.contains('schoolguardian')) return 'School Guardian';
    if (pkg.contains('settings')) return 'Device Settings';

    // Fallback: extract last segment of package name & capitalize
    final parts = packageName.split('.');
    if (parts.isNotEmpty) {
      final last = parts.last;
      if (last.length > 1) {
        return last[0].toUpperCase() + last.substring(1);
      }
    }
    return packageName;
  }

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

    // Try fetching real device screen time usage statistics from the device OS first
    final realDeviceApps = await fetchRealDeviceUsageStats();

    // Load App Usages
    List<AppUsageItem> apps = [];
    if (realDeviceApps.isNotEmpty) {
      apps = realDeviceApps;
    } else {
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

    // Generate 7-day weekly history logs from native device OS or default
    List<DailyScreenTime> weeklyLogs = [];
    if (realDeviceApps.isNotEmpty) {
      weeklyLogs = await fetchRealWeeklyDeviceLogs(apps);
    } else {
      weeklyLogs = _generateDefaultWeeklyLogs(apps);
    }

    final yesterdayMins = weeklyLogs.length >= 2
        ? weeklyLogs[weeklyLogs.length - 2].totalMinutes
        : 0;

    final weeklyAvg = (weeklyLogs.fold<int>(
                0, (sum, log) => sum + log.totalMinutes) /
            weeklyLogs.length)
        .round();

    return ScreenTimeSummary(
      todayMinutes: todayMinutes,
      yesterdayMinutes: yesterdayMins,
      weeklyAverageMinutes: weeklyAvg,
      topCategory: topCat,
      appUsages: apps,
      weeklyLogs: weeklyLogs,
      goal: goal,
      isRealData: realDeviceApps.isNotEmpty,
    );
  }

  /// Query native Android OS UsageStats for each of the past 7 days to compile actual weekly historical logs.
  Future<List<DailyScreenTime>> fetchRealWeeklyDeviceLogs(List<AppUsageItem> todayApps) async {
    if (kIsWeb) return _generateDefaultWeeklyLogs(todayApps);

    try {
      final now = DateTime.now();
      final logs = <DailyScreenTime>[];

      for (int i = 6; i >= 0; i--) {
        final dayTarget = now.subtract(Duration(days: i));
        final dateStr =
            '${dayTarget.year}-${dayTarget.month.toString().padLeft(2, '0')}-${dayTarget.day.toString().padLeft(2, '0')}';

        if (i == 0) {
          final todayTotal = todayApps.fold<int>(0, (sum, a) => sum + a.minutesUsed);
          logs.add(DailyScreenTime(
            date: dateStr,
            totalMinutes: todayTotal,
            appUsages: todayApps,
          ));
          continue;
        }

        // Expand window slightly before midnight so UsageStatsManager matches the daily bucket
        final dayStart = DateTime(dayTarget.year, dayTarget.month, dayTarget.day, 0, 0, 0).subtract(const Duration(minutes: 30));
        final dayEnd = DateTime(dayTarget.year, dayTarget.month, dayTarget.day, 23, 59, 59);

        final dayInfo = await AppUsage().getAppUsage(dayStart, dayEnd);
        int dayTotal = 0;

        for (int j = 0; j < dayInfo.length; j++) {
          final info = dayInfo[j];
          if (info.usage.inSeconds <= 5) continue;
          if (_isSystemPackage(info.packageName.toLowerCase())) continue;
          final mins = info.usage.inMinutes > 0 ? info.usage.inMinutes : 1;
          dayTotal += mins;
        }

        logs.add(DailyScreenTime(
          date: dateStr,
          totalMinutes: dayTotal,
          appUsages: const [],
        ));
      }
      return logs;
    } catch (e) {
      debugPrint('Real weekly AppUsage query notice: $e');
      return _generateDefaultWeeklyLogs(todayApps);
    }
  }

  /// Update individual app limit in minutes (0 means remove limit).
  Future<void> setAppLimit({
    required String studentId,
    required String appId,
    required int limitMinutes,
  }) async {
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

  /// Increment live active screen time for student (defaults to active School Guardian session)
  Future<void> recordLiveSession(String studentId, {int additionalMinutes = 1}) async {
    final summary = await getSummary(studentId);
    final apps = List<AppUsageItem>.from(summary.appUsages);

    int eduIndex = apps.indexWhere((a) => a.packageName == 'com.google.android.apps.classroom' || a.category == AppCategory.education);

    if (eduIndex != -1) {
      final app = apps[eduIndex];
      apps[eduIndex] = app.copyWith(
        minutesUsed: app.minutesUsed + additionalMinutes,
        lastUsed: DateTime.now(),
      );
    } else if (apps.isNotEmpty) {
      final app = apps[0];
      apps[0] = app.copyWith(
        minutesUsed: app.minutesUsed + additionalMinutes,
        lastUsed: DateTime.now(),
      );
    }

    await _saveApps(studentId, apps);
  }

  Future<void> _saveApps(String studentId, List<AppUsageItem> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final appsKey = '$_appUsagesKeyPrefix$studentId';
    final jsonStr = jsonEncode(apps.map((e) => e.toJson()).toList());
    await prefs.setString(appsKey, jsonStr);
  }

  /// Default weekly logs generated strictly from saved local history or 0m (no fake numbers).
  List<DailyScreenTime> _generateDefaultWeeklyLogs(List<AppUsageItem> todayApps) {
    final now = DateTime.now();
    final logs = <DailyScreenTime>[];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final total = i == 0
          ? todayApps.fold<int>(0, (sum, a) => sum + a.minutesUsed)
          : 0;

      logs.add(DailyScreenTime(
        date: dateStr,
        totalMinutes: total,
        appUsages: i == 0 ? todayApps : [],
      ));
    }
    return logs;
  }
}