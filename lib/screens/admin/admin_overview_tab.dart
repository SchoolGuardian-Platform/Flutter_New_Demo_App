import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

/// Bottom-nav "Overview" tab for the admin dashboard.
///
/// THIS IS THE FIX for "the overview is cluttered with every
/// functionality" -- previously the admin dashboard's Overview section
/// was just a long list of tappable cards (Notifications, Pending
/// Approvals, Manage Users, Reports, Profile). Those now live one tap
/// away as their own bottom-nav destinations (see `dashboard_page.dart`),
/// and this tab does exactly one job: show status at a glance -- total
/// pending, a per-category breakdown, and a small chart.
///
/// DATA SOURCE NOTE: the backend does not (yet) expose a single
/// "dashboard stats" endpoint, only the four `GET .../pending` queues
/// that already power `AdminService.getPendingSummary()`. So "Total
/// Pending" and the per-category chart below are real, live numbers from
/// those queues. "Total Approved" is still `AdminService.sessionApprovals`
/// under the hood -- a local, in-memory counter that resets on app
/// restart -- since there's no backend endpoint yet for a real all-time
/// approval count. The label says "Total" per product request, but it is
/// NOT a true historical total; a real one needs a backend change.
class AdminOverviewTab extends StatefulWidget {
  const AdminOverviewTab({super.key});

  @override
  State<AdminOverviewTab> createState() => AdminOverviewTabState();
}

class AdminOverviewTabState extends State<AdminOverviewTab> {
  final _adminService = AdminService();
  PendingSummary? _summary;
  int _approvedTotalCount = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Public so the dashboard shell can trigger a refresh when this tab is
  /// re-selected (e.g. after returning from the Approvals tab having just
  /// approved something).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await _adminService.getPendingSummary();
      final approvedCount = await _adminService.getTotalApprovedCount();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _approvedTotalCount = approvedCount;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Live status of registrations awaiting a decision.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading && summary == null)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xl2),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && summary == null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xl),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.pending_actions_outlined,
                    label: 'Total Pending',
                    value: '${summary?.total ?? 0}',
                    color: AppColors.warning,
                    background: AppColors.warningContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle_outline,
                    // NOTE: there's no backend endpoint for an all-time
                    // approved count (only the four `.../pending` queues
                    // exist) -- this is still
                    // `AdminService.sessionApprovals` under the hood, so
                    // it resets whenever the app restarts, despite the
                    // "Total" label. A real total needs a backend change.
                    label: 'Total Approved',
                    value: '$_approvedTotalCount',
                    color: AppColors.secondary,
                    background: AppColors.secondaryContainer.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Pending by category',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _PendingBarChart(
              bars: [
                _BarData('Students', summary?.students.length ?? 0,
                    AppColors.primary),
                _BarData('Parents', summary?.parents.length ?? 0,
                    KukieBarColor.violet),
                _BarData('Teachers', summary?.teachers.length ?? 0,
                    AppColors.tertiary),
                _BarData('Links', summary?.relationships.length ?? 0,
                    AppColors.warning),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Fixed, explicit height for BOTH cards -- not measured from text
      // metrics, which can vary slightly by device/font and was still
      // leaving them visibly uneven. This guarantees identical boxes
      // regardless of label length or platform.
      height: 132,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarData {
  const _BarData(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;
}

/// A small, dependency-free horizontal bar chart (no charting package
/// required) -- just proportionally-sized `Container`s, consistent with
/// the rest of this codebase's zero-extra-deps approach.
class _PendingBarChart extends StatelessWidget {
  const _PendingBarChart({required this.bars});

  final List<_BarData> bars;

  @override
  Widget build(BuildContext context) {
    final maxCount = bars.map((b) => b.count).fold<int>(0, (a, b) => a > b ? a : b);
    final scale = maxCount == 0 ? 0.0 : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: maxCount == 0
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: Text(
                  'Nothing pending right now.',
                  style: TextStyle(color: AppColors.outline),
                ),
              ),
            )
          : Column(
              children: bars
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _BarRow(
                          data: b,
                          fraction: maxCount == 0 ? 0 : (b.count / maxCount) * scale,
                        ),
                      ))
                  .toList(),
            ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.data, required this.fraction});

  final _BarData data;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            data.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 14,
                    width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
                    decoration: BoxDecoration(
                      color: data.color,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 20,
          child: Text(
            '${data.count}',
            textAlign: TextAlign.end,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Small local color so this file doesn't need to depend on
/// `theme/kukie_accent.dart` just for one bar color.
class KukieBarColor {
  static const violet = AppColors.primary;
}