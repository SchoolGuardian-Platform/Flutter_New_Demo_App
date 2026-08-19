import 'package:flutter/material.dart';

import '../../models/account_status.dart';
import '../../models/guardian_link.dart';
import '../../models/user.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../models/school_class.dart';
import '../../services/school_management_service.dart';
import '../../widgets/class_schedule_timetable.dart';
import '../../widgets/dashboard_grid_cards.dart';
import '../analytics/academic_gpa_progression_page.dart';
import '../biometrics/biometric_health_overview_page.dart';
import '../biometrics/stress_level_dashboard_page.dart';
import '../nutrition/calorie_nutrition_dashboard_page.dart';
import 'student_portal_dashboard_page.dart';

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
    } catch (_) {
      // In demo mode or offline mode, fall back silently so all UI cards render cleanly.
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

          // Features & Quick Dashboards Hub
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Featured Dashboards & Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '5 Live Dashboards',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: KukieAccent.violet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Scrollable Cards Hub
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FeatureHubTile(
                      title: 'GPA Analytics',
                      subtitle: 'Progression Spline',
                      icon: Icons.auto_graph_rounded,
                      color: const Color(0xFF6366F1),
                      bg: const Color(0xFFEEF2FF),
                      onTap: () => Navigator.of(context).pushNamed(
                        AcademicGpaProgressionPage.routeName,
                        arguments: user,
                      ),
                    ),
                    _FeatureHubTile(
                      title: 'Student Portal',
                      subtitle: 'Modern Desktop 2x2',
                      icon: Icons.dashboard_customize_rounded,
                      color: const Color(0xFF0F172A),
                      bg: const Color(0xFFF1F5F9),
                      onTap: () => Navigator.of(context).pushNamed(
                        StudentPortalDashboardPage.routeName,
                        arguments: user,
                      ),
                    ),
                    _FeatureHubTile(
                      title: 'Calorie Tracker',
                      subtitle: 'Radial Gauge & Macros',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFF0D9488),
                      bg: const Color(0xFFCCFBF1),
                      onTap: () => Navigator.of(context).pushNamed(
                        CalorieNutritionDashboardPage.routeName,
                        arguments: user,
                      ),
                    ),
                    _FeatureHubTile(
                      title: 'Stress Tracker',
                      subtitle: 'Spline & Equalizer',
                      icon: Icons.monitor_heart_rounded,
                      color: const Color(0xFFF97316),
                      bg: const Color(0xFFFFEDD5),
                      onTap: () => Navigator.of(context).pushNamed(
                        StressLevelDashboardPage.routeName,
                        arguments: user,
                      ),
                    ),
                    _FeatureHubTile(
                      title: 'Health Overview',
                      subtitle: 'Sleep & Vitals Grid',
                      icon: Icons.health_and_safety_rounded,
                      color: const Color(0xFF7C3AED),
                      bg: const Color(0xFFEDE9FE),
                      onTap: () => Navigator.of(context).pushNamed(
                        BiometricHealthOverviewPage.routeName,
                        arguments: user,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Modern Card Grid Dashboard Section (Tasks, Weekly Goals, Announcements, Upcoming Classes)
          const DashboardGridCardsSection(),
          const SizedBox(height: AppSpacing.lg),

          // Interactive Weekly Timetable Schedule Matrix
          const ClassScheduleTimetableWidget(),
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

class _FeatureHubTile extends StatelessWidget {
  const _FeatureHubTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.black38),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
