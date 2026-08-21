import 'package:flutter/material.dart';
import '../../models/screen_time_models.dart';
import '../../models/user.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_usage_list_tile.dart';
import '../../widgets/category_breakdown_chart.dart';
import '../../widgets/daily_usage_histogram.dart';
import '../../widgets/downtime_banner.dart';

/// Parent monitoring screen to inspect child app screen time, set per-app time limits,
/// and manage downtime schedules.
class ParentScreenTimePage extends StatefulWidget {
  const ParentScreenTimePage({
    super.key,
    required this.parentUser,
    this.studentUser,
    this.studentId,
    this.studentName,
  });

  static const routeName = '/parent/screen-time';
  final User parentUser;
  final User? studentUser;
  final String? studentId;
  final String? studentName;

  @override
  State<ParentScreenTimePage> createState() => _ParentScreenTimePageState();
}

class _ParentScreenTimePageState extends State<ParentScreenTimePage> {
  final _service = ScreenTimeService();
  bool _loading = true;
  ScreenTimeSummary? _summary;

  String get _targetStudentId =>
      widget.studentUser?.id ?? widget.studentId ?? 'student_demo_1';

  String get _displayName =>
      widget.studentUser?.fullName ?? widget.studentName ?? 'Child';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final summary = await _service.getSummary(_targetStudentId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleDowntime(bool enabled) async {
    final summary = _summary;
    if (summary == null) return;

    final updatedGoal = ScreenTimeGoal(
      dailyLimitMinutes: summary.goal.dailyLimitMinutes,
      downtimeStart: summary.goal.downtimeStart,
      downtimeEnd: summary.goal.downtimeEnd,
      isDowntimeEnabled: enabled,
    );

    await _service.updateGoal(
      studentId: _targetStudentId,
      goal: updatedGoal,
    );
    _loadData();
  }

  Future<void> _showEditGoalDialog() async {
    final summary = _summary;
    if (summary == null) return;

    final controller = TextEditingController(
      text: summary.goal.dailyLimitMinutes.toString(),
    );

    final newLimit = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Daily Screen Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter maximum allowed daily minutes for $_displayName:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Daily Limit (Minutes)',
                hintText: 'e.g. 180 (3 Hours)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Save Limit'),
          ),
        ],
      ),
    );

    if (newLimit != null) {
      final updatedGoal = ScreenTimeGoal(
        dailyLimitMinutes: newLimit,
        downtimeStart: summary.goal.downtimeStart,
        downtimeEnd: summary.goal.downtimeEnd,
        isDowntimeEnabled: summary.goal.isDowntimeEnabled,
      );

      await _service.updateGoal(
        studentId: _targetStudentId,
        goal: updatedGoal,
      );
      _loadData();
    }
  }

  Future<void> _showSetAppLimitDialog(AppUsageItem app) async {
    final controller = TextEditingController(
      text: app.timeLimitMinutes > 0 ? app.timeLimitMinutes.toString() : '30',
    );

    final limitMins = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Limit: ${app.appName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set maximum daily usage allowed for ${app.appName}:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'App Limit (Minutes)',
                hintText: 'e.g. 45',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (app.timeLimitMinutes > 0)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(0),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Remove Limit'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('Save App Limit'),
          ),
        ],
      ),
    );

    if (limitMins != null) {
      await _service.setAppLimit(
        studentId: _targetStudentId,
        appId: app.id,
        limitMinutes: limitMins,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Screen Controls · $_displayName',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh metrics',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : summary == null
              ? const Center(child: Text('Unable to load child screen time data.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Header Card
                      _ParentHeaderCard(
                        displayName: _displayName,
                        summary: summary,
                        onEditLimit: _showEditGoalDialog,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Editable Downtime Banner
                      DowntimeBanner(
                        goal: summary.goal,
                        isEditable: true,
                        onToggleDowntime: _toggleDowntime,
                        onEditGoal: _showEditGoalDialog,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Category Breakdown Chart
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: CategoryBreakdownChart(
                          categoryBreakdown: summary.categoryBreakdown,
                          totalMinutes: summary.todayMinutes,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // 7-day Histogram Chart
                      DailyUsageHistogram(
                        weeklyLogs: summary.weeklyLogs,
                        dailyLimitMinutes: summary.goal.dailyLimitMinutes,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // App usage items with parental controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'App Usage & Per-App Limits',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          Text(
                            'Tap gear to limit',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      for (final app in summary.appUsages)
                        AppUsageListTile(
                          item: app,
                          showLimitControls: true,
                          onTapLimit: () => _showSetAppLimitDialog(app),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _ParentHeaderCard extends StatelessWidget {
  const _ParentHeaderCard({
    required this.displayName,
    required this.summary,
    required this.onEditLimit,
  });

  final String displayName;
  final ScreenTimeSummary summary;
  final VoidCallback onEditLimit;

  @override
  Widget build(BuildContext context) {
    final isExceeded = summary.isLimitExceeded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryFixed,
            child: Icon(Icons.shield_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayName\'s Activity Today',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '${summary.formattedTodayUsage} total · Top: ${summary.topCategory.label}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: onEditLimit,
            icon: const Icon(Icons.tune_rounded, size: 14),
            label: const Text('Limit', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}
