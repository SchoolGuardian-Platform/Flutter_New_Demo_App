import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/guardian_link.dart';
import '../../models/user.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../models/school_class.dart';
import '../../services/school_management_service.dart';
import '../../widgets/dashboard_grid_cards.dart';

/// Bottom-nav "Overview" tab for the student dashboard
class StudentOverviewTab extends StatefulWidget {
  const StudentOverviewTab({super.key, required this.user});

  final User user;

  @override
  State<StudentOverviewTab> createState() => StudentOverviewTabState();
}

class StudentOverviewTabState extends State<StudentOverviewTab> {
  final _studentService = StudentService();
  final _schoolService = SchoolManagementService();

  List<GuardianLink>? _guardians;
  SchoolClass? _assignedClass;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Public so the dashboard shell can trigger a refresh when this tab is
  /// re-selected.
  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardians = await _studentService.getMyGuardians();
      final cls = await _schoolService.getStudentClass(widget.user.id, studentCode: widget.user.studentId);
      if (!mounted) return;
      setState(() {
        _guardians = guardians;
        _assignedClass = cls;
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
          const SizedBox(height: AppSpacing.md),

          // Assigned Class Banner Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KukieAccent.violet, KukieAccent.violetDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _assignedClass != null ? _assignedClass!.displayName : 'Class Assignment Pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _assignedClass != null
                            ? 'Room: ${_assignedClass!.roomNumber ?? 'Unassigned'} • Year: ${_assignedClass!.academicYear}'
                            : 'Contact your school admin to get enrolled in a class section.',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

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

          // Modern Card Grid Dashboard Section (Tasks, Weekly Goals, Announcements, Upcoming Classes)
          const DashboardGridCardsSection(),
          const SizedBox(height: AppSpacing.lg),
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
