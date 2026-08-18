import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/guardian_link.dart';
import '../../models/user.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/status_pie_chart.dart';

/// Bottom-nav "Overview" tab for the student dashboard -- mirrors the
/// admin dashboard's Overview tab (`admin_overview_tab.dart`): a welcome
/// header, a couple of at-a-glance stat cards, then chart(s).
///
/// DATA SOURCE NOTE:
/// - The "Linked Guardians" count is real, live data from
///   `GET /students/my-guardians` (`StudentService.getMyGuardians`),
///   which IS implemented on the backend.
/// - The Grade Status / Wellbeing Status pie charts are NOT backed by a
///   live endpoint: `GET /reports/student/{id}/academic` and
///   `.../wellbeing` are both marked `x-implementation-status: planned`
///   in `SchoolGuardian_Final_OpenAPI.yaml` -- i.e. designed but not
///   built yet, same situation as `screens/reports/reports_page.dart`.
///   Per this task's instructions the backend isn't being touched here,
///   so rather than either hide the charts entirely or quietly show
///   made-up numbers as if they were real, this tab displays clearly
///   labelled SAMPLE data and says so in a banner. Once those two
///   endpoints ship, [_loadReportStatuses] is the only place that needs
///   to change -- swap the two `_sample...` slice lists for a real
///   service call.
class StudentOverviewTab extends StatefulWidget {
  const StudentOverviewTab({super.key, required this.user});

  final User user;

  @override
  State<StudentOverviewTab> createState() => StudentOverviewTabState();
}

class StudentOverviewTabState extends State<StudentOverviewTab> {
  final _studentService = StudentService();

  List<GuardianLink>? _guardians;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Public so the dashboard shell can trigger a refresh when this tab is
  /// re-selected (e.g. after linking/unlinking a guardian elsewhere).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardians = await _studentService.getMyGuardians();
      if (!mounted) return;
      setState(() => _guardians = guardians);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Sample-only distributions -- see class doc for why these aren't a
  // live API call. Grouped into 3 buckets each, matching the kind of
  // breakdown `GET /reports/student/:id/academic` and `.../wellbeing`
  // are documented to eventually return.
  static const _sampleGradeSlices = [
    PieSlice(label: 'Excellent', value: 3, color: AppColors.secondary),
    PieSlice(label: 'Good', value: 4, color: AppColors.primary),
    PieSlice(label: 'Needs attention', value: 1, color: AppColors.warning),
  ];

  static const _sampleWellbeingSlices = [
    PieSlice(label: 'Positive', value: 6, color: AppColors.secondary),
    PieSlice(label: 'Neutral', value: 2, color: AppColors.warning),
    PieSlice(label: 'Flagged', value: 1, color: AppColors.error),
  ];

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final guardianCount = _guardians?.length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Welcome back, ${user.firstName}',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            user.studentId != null && user.studentId!.isNotEmpty
                ? 'Student ID: ${user.studentId}'
                : user.email,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.outline),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.family_restroom,
                  label: 'Linked Guardians',
                  value: _loading && guardianCount == null
                      ? '—'
                      : '${guardianCount ?? 0}',
                  color: KukieAccent.violet,
                  background: KukieAccent.violetTint,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.verified_user_outlined,
                  label: 'Account status',
                  value: user.status != null
                      ? _statusLabel(user.status!)
                      : '—',
                  color: AppColors.secondary,
                  background: AppColors.secondaryContainer.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          if (_error != null && guardianCount == null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!,
                style: const TextStyle(color: AppColors.error, fontSize: 12)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: KukieAccent.violetTint,
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
              border: Border.all(color: KukieAccent.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: KukieAccent.violet),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Grade and wellbeing reporting endpoints are coming soon '
                    'on the backend -- the charts below show sample data so '
                    'you can see the shape of what\'s coming.',
                    style: const TextStyle(
                        color: KukieAccent.ink, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const StatusPieChart(
            title: 'Grade Status (sample)',
            slices: _sampleGradeSlices,
          ),
          const SizedBox(height: AppSpacing.md),
          const StatusPieChart(
            title: 'Wellbeing Status (sample)',
            slices: _sampleWellbeingSlices,
          ),
        ],
      ),
    );
  }

  String _statusLabel(AccountStatus status) =>
      status == AccountStatus.active ? 'Active' : status.name;
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
