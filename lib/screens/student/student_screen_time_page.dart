import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/screen_time_models.dart';
import '../../models/user.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_usage_list_tile.dart';
import '../../widgets/category_breakdown_chart.dart';
import '../../widgets/daily_usage_histogram.dart';
import '../../widgets/downtime_banner.dart';

/// Full screen time & digital wellness dashboard page for students.
class StudentScreenTimePage extends StatefulWidget {
  const StudentScreenTimePage({super.key, required this.user});

  static const routeName = '/student/screen-time';
  final User user;

  @override
  State<StudentScreenTimePage> createState() => _StudentScreenTimePageState();
}

class _StudentScreenTimePageState extends State<StudentScreenTimePage> {
  final _service = ScreenTimeService();
  bool _loading = true;
  ScreenTimeSummary? _summary;
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Start live tracking timer every 15 seconds for real-time usage ticking
    _liveTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await _service.recordLiveSession(widget.user.id, additionalMinutes: 1);
      if (mounted) {
        final updated = await _service.getSummary(widget.user.id);
        setState(() => _summary = updated);
      }
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final summary = await _service.getSummary(widget.user.id);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Digital Wellness & Screen Time',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          if (summary?.isRealData ?? false)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.circle, size: 7, color: Color(0xFF16A34A)),
                  SizedBox(width: 4),
                  Text(
                    'LIVE TRACKING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ],
              ),
            ),
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
              ? const Center(child: Text('Unable to load screen time data.'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Hero Metric Card
                      _HeroMetricCard(summary: summary),
                      const SizedBox(height: AppSpacing.lg),

                      // Downtime Schedule Banner
                      DowntimeBanner(goal: summary.goal),
                      const SizedBox(height: AppSpacing.lg),

                      // Category Breakdown Section
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

                      // 7-day Histogram
                      DailyUsageHistogram(
                        weeklyLogs: summary.weeklyLogs,
                        dailyLimitMinutes: summary.goal.dailyLimitMinutes,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // App Usage Breakdown List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'App Usage Breakdown',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                          Text(
                            '${summary.appUsages.length} Apps',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: const Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      for (final app in summary.appUsages)
                        AppUsageListTile(item: app),
                    ],
                  ),
                ),
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({required this.summary});

  final ScreenTimeSummary summary;

  @override
  Widget build(BuildContext context) {
    final isExceeded = summary.isLimitExceeded;
    final ratio = summary.todayLimitRatio.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: isExceeded
              ? AppColors.error.withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isExceeded
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phonelink_setup_rounded,
                      color: isExceeded ? AppColors.error : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Screen Time Today',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        summary.formattedTodayUsage,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: isExceeded
                              ? AppColors.error
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isExceeded
                      ? AppColors.error.withValues(alpha: 0.1)
                      : const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isExceeded ? 'Limit Exceeded' : 'Balanced',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isExceeded
                        ? AppColors.error
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Daily Allowance Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Limit (${summary.goal.dailyLimitMinutes ~/ 60}h ${summary.goal.dailyLimitMinutes % 60}m)',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B)),
              ),
              Text(
                '${(ratio * 100).round()}% Used',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isExceeded
                      ? AppColors.error
                      : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExceeded ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}