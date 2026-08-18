import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/app_logo.dart';
import '../admin/admin_notifications_page.dart';
import '../admin/admin_overview_tab.dart';
import '../admin/admin_profile_page.dart';
import '../admin/manage_courses_page.dart';
import '../admin/manage_users_page.dart';
import '../grades/parent_grades_page.dart';
import '../grades/student_grades_page.dart';
import '../landing_page.dart';
import '../reports/reports_page.dart';
import '../student/course_registration_page.dart';
import '../teacher/my_classes_page.dart';
import '../teacher/teacher_portal_page.dart';

/// Post-login home screen. One shell, per-role content — the four roles
/// share the same shape (app bar with profile menu + logout, a welcome
/// card, a grid of role-specific sections) rather than four separate
/// screens, since none of the underlying admin/parent/student endpoints
/// have a service layer yet (see PROGRESS.md #5). Each section here is a
/// placeholder that names the backend route it will eventually call.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.user});

  static const routeName = '/dashboard';

  final User user;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  final _adminService = AdminService();
  late User _user = widget.user;
  bool _refreshing = false;
  bool _loggingOut = false;

  /// Only fetched for admins -- powers the notification bell badge in the
  /// app bar. See `AdminService.getPendingSummary` for why this is
  /// assembled client-side rather than from a single endpoint.
  int _pendingCount = 0;

  /// Admin-only bottom nav. "Overview" (index 0) renders inline; the other
  /// two are shortcuts that push the existing full-screen admin pages
  /// and then return here, refreshing Overview's stats so numbers don't
  /// go stale after an approve/reject. See `_onAdminTabTapped`.
  ///
  /// There used to be a dedicated "Approvals" tab here, but approving or
  /// rejecting is already fully doable from the Notifications bell (see
  /// `AdminNotificationsPage._respondToUser` /
  /// `_respondToRelationship`), so the tab was redundant with that and
  /// with the "Manage Users" section. Removed rather than kept as a
  /// second way to do the same thing.
  final _overviewKey = GlobalKey<AdminOverviewTabState>();

  @override
  void initState() {
    super.initState();
    if (_user.role == UserRole.admin) {
      _loadPendingCount();
    }
  }

  Future<void> _loadPendingCount() async {
    try {
      final summary = await _adminService.getPendingSummary();
      if (!mounted) return;
      setState(() => _pendingCount = summary.total);
    } catch (_) {
      // Non-critical for the dashboard shell; the notifications page
      // itself will surface a proper error if this keeps failing.
    }
  }

  /// `GET /auth/me` — re-fetches the profile (pull-to-refresh). Also
  /// doubles as the "is my session still good" check other screens can
  /// reuse the pattern from (see `session_check_page.dart`).
  Future<void> _refreshProfile() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final fresh = await _authService.getMe();
      if (!mounted) return;
      setState(() => _user = fresh);
      if (_user.role == UserRole.admin) _loadPendingCount();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// `POST /auth/logout` — revokes the refresh token server-side and
  /// clears local storage either way (see `AuthService.logout`).
  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
    } on ApiException {
      // Token storage is cleared in AuthService.logout's `finally` even
      // if the server call itself fails, so it's safe to proceed to
      // landing regardless.
    } finally {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LandingPage.routeName,
          (route) => false,
        );
      }
    }
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You\'ll need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Future<void> _onAdminTabTapped(int index) async {
    switch (index) {
      case 0:
        return; // Overview renders inline; nothing to navigate to.
      case 1:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ManageUsersPage(),
        ));
        break;
      case 2:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AdminProfilePage(initialUser: _user),
        ));
        break;
    }
    // Approving/rejecting on any of those screens changes the pending
    // counts, so refresh Overview's stats and the app bar badge on return.
    _overviewKey.currentState?.refresh();
    _loadPendingCount();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user.role == UserRole.admin;
    return Scaffold(
      appBar: AppBar(
        title: const AppWordmark(),
        actions: [
          if (_user.role == UserRole.admin)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    tooltip: 'Notifications',
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const AdminNotificationsPage(),
                      ));
                      _loadPendingCount();
                    },
                  ),
                  if (_pendingCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          _pendingCount > 9 ? '9+' : '$_pendingCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_loggingOut)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (value) {
                if (value == 'logout') {
                  _confirmLogout();
                } else if (value == 'profile') {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AdminProfilePage(initialUser: _user),
                  ));
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(
                    _user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const PopupMenuItem(
                  value: 'profile',
                  child: Text('View profile'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Text('Log Out'),
                ),
              ],
            ),
        ],
      ),
      body: isAdmin
          ? AdminOverviewTab(key: _overviewKey)
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _WelcomeCard(user: _user),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Overview', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  _RoleSections(role: _user.role, user: _user),
                ],
              ),
            ),
      bottomNavigationBar: isAdmin
          ? BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.outline,
              onTap: _onAdminTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Overview',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.manage_accounts_outlined),
                  label: 'Manage',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(user.role.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back, ${user.firstName}',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 2),
                Text(
                  '${user.role.label} · ${user.email}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (user.status != null && user.status != AccountStatus.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Account status: ${user.status!.name}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.warning),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Per-role home sections. Admin's cards now navigate to real, working
/// screens (previously they were static text naming a route that nothing
/// on screen actually opened). Parent/student/teacher cards still name
/// the backend route they stand in for, since those services don't have
/// a Flutter layer yet; Reports is wired for every role since its screen
/// exists regardless of backend status.
class _RoleSections extends StatelessWidget {
  const _RoleSections({required this.role, required this.user});

  final UserRole role;
  final User user;

  List<_SectionSpec> _sections(BuildContext context) {
    switch (role) {
      case UserRole.parent:
        return [
          _SectionSpec(
            icon: Icons.grade_outlined,
            title: 'Child Grades & Recommendations',
            subtitle: 'View grades, assessment scores, and confidential teacher notes.',
            route: 'GET /parents/grades',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ParentGradesPage(
                    studentId: user.studentId ?? 'STU-1001'))),
          ),
          const _SectionSpec(
            icon: Icons.link,
            title: 'Linked Students',
            subtitle: 'View and manage students linked to your account.',
            route: 'GET /parents/my-students',
          ),
          _SectionSpec(
            icon: Icons.description_outlined,
            title: 'Reports',
            subtitle: 'Academic, attendance, and wellbeing reports.',
            route: 'GET /reports/student/:id/*',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
          ),
        ];
      case UserRole.student:
        return [
          _SectionSpec(
            icon: Icons.how_to_reg_outlined,
            title: 'Course Registration',
            subtitle: 'Enroll in Director-approved courses for the semester.',
            route: 'POST /students/register-courses',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CourseRegistrationPage(
                    studentId: user.studentId ?? 'STU-1001'))),
          ),
          _SectionSpec(
            icon: Icons.school_outlined,
            title: 'My Grades & Coursework',
            subtitle: 'View your assessment scores, quizzes, and project results.',
            route: 'GET /students/grades',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => StudentGradesPage(
                    studentId: user.studentId ?? 'STU-1001'))),
          ),
          const _SectionSpec(
            icon: Icons.badge_outlined,
            title: 'My Profile',
            subtitle: 'Student ID, school, and enrollment details.',
            route: 'GET /auth/me',
          ),
          const _SectionSpec(
            icon: Icons.family_restroom,
            title: 'Linked Guardians',
            subtitle: 'Parents/guardians connected to your account.',
            route: 'GET /students/my-guardians',
          ),
          _SectionSpec(
            icon: Icons.description_outlined,
            title: 'Reports',
            subtitle: 'Your academic, attendance, and wellbeing reports.',
            route: 'GET /reports/student/:id/*',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
          ),
        ];
      case UserRole.teacher:
        return [
          _SectionSpec(
            icon: Icons.psychology_outlined,
            title: 'Teacher Professional Portal',
            subtitle:
                'Manage major field of study, input student grades & parent notes.',
            route: 'POST /teacher/grades',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TeacherPortalPage())),
          ),
          _SectionSpec(
            icon: Icons.groups_outlined,
            title: 'My Classes',
            subtitle: 'Class rosters, attendance, and student performance.',
            route: 'GET /teacher/classes',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyClassesPage())),
          ),
          _SectionSpec(
            icon: Icons.description_outlined,
            title: 'Reports',
            subtitle: 'Generate reports for your students.',
            route: 'GET /reports/student/:id/*',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
          ),
        ];
      case UserRole.admin:
        return [
          _SectionSpec(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'New registrations and guardian-link requests.',
            route: 'GET /admin/{role}/pending, /admin/relationships/pending',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AdminNotificationsPage())),
          ),
          _SectionSpec(
            icon: Icons.auto_stories_outlined,
            title: 'Director Course Management',
            subtitle: 'Create semester courses, set credit hours, assign teachers.',
            route: 'POST /admin/courses',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCoursesPage())),
          ),
          _SectionSpec(
            icon: Icons.manage_accounts_outlined,
            title: 'Manage Users',
            subtitle: 'All account categories, grouped with live counts.',
            route: 'GET /admin/{role}/pending',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageUsersPage())),
          ),
          _SectionSpec(
            icon: Icons.description_outlined,
            title: 'Reports',
            subtitle: 'School-wide academic, attendance, and wellbeing data.',
            route: 'GET /reports/student/:id/*',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportsPage())),
          ),
          _SectionSpec(
            icon: Icons.admin_panel_settings_outlined,
            title: 'My Admin Profile',
            subtitle: 'Your account details.',
            route: 'GET /auth/me',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AdminProfilePage(initialUser: user))),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections(context);
    return Column(
      children: sections
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SectionCard(spec: s),
              ))
          .toList(),
    );
  }
}

class _SectionSpec {
  const _SectionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  /// Null for sections that don't have a screen yet (parent/student/
  /// teacher placeholders naming a route with no Flutter service layer).
  final VoidCallback? onTap;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.spec});

  final _SectionSpec spec;

  @override
  Widget build(BuildContext context) {
    final tappable = spec.onTap != null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: tappable
                  ? KukieAccent.violet.withValues(alpha: 0.25)
                  : AppColors.outlineVariant,
            ),
            boxShadow: tappable ? AppColors.cardShadow : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tappable
                      ? KukieAccent.violetTint
                      : AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  spec.icon,
                  color: tappable ? KukieAccent.violet : AppColors.onSurfaceVariant,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(spec.subtitle, style: Theme.of(context).textTheme.bodySmall),
                    if (!tappable) ...[
                      const SizedBox(height: 4),
                      Text(
                        spec.route,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.outline,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (tappable)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.outline),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
