import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../admin/admin_notifications_page.dart';
import '../admin/admin_overview_tab.dart';
import '../admin/admin_profile_page.dart';
import '../admin/class_section_management_page.dart';
import '../admin/guardian_links_page.dart';
import '../admin/manage_users_page.dart';
import '../admin/verified_users_page.dart';
import '../landing_page.dart';
import '../parent/my_students_page.dart';
import '../communication/private_communication_page.dart';
import '../reports/reports_page.dart';
import '../student/guardians_page.dart';
import '../student/student_overview_tab.dart';
import '../student/student_portal_dashboard_page.dart';
import '../student/student_profile_page.dart';
import '../analytics/academic_gpa_progression_page.dart';
import '../biometrics/biometric_health_overview_page.dart';
import '../biometrics/stress_level_dashboard_page.dart';
import '../nutrition/calorie_nutrition_dashboard_page.dart';
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
  /// three ("Manage", "Users", "Profile") are shortcuts that push the
  /// existing full-screen admin pages and then return here, refreshing
  /// Overview's stats so numbers don't go stale after an approve/reject.
  /// See `_onAdminTabTapped`.
  ///
  /// There used to be a dedicated "Approvals" tab here, but approving or
  /// rejecting is already fully doable from the Notifications bell (see
  /// `AdminNotificationsPage._respondToUser` /
  /// `_respondToRelationship`), so the tab was redundant with that and
  /// with the "Manage Users" section. Removed rather than kept as a
  /// second way to do the same thing.
  final _overviewKey = GlobalKey<AdminOverviewTabState>();

  /// Student-only bottom nav, same shape as the admin one above:
  /// "Overview" (index 0) renders inline via [StudentOverviewTab]; "My
  /// Profile", "Guardians", and "Reports" are shortcuts that push their
  /// existing full-screen pages and return here, refreshing Overview's
  /// live guardian count in case it changed (a new guardian got linked,
  /// etc). See `_onStudentTabTapped`.
  final _studentOverviewKey = GlobalKey<StudentOverviewTabState>();

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
          builder: (_) => const VerifiedUsersPage(),
        ));
        break;
      case 3:
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

  Future<void> _onStudentTabTapped(int index) async {
    switch (index) {
      case 0:
        return; // Overview renders inline; nothing to navigate to.
      case 1:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => StudentProfilePage(initialUser: _user),
        ));
        break;
      case 2:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const GuardiansPage(),
        ));
        break;
      case 3:
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ReportsPage(),
        ));
        break;
    }
    // Returning here could follow a guardian-link change, so refresh
    // Overview's live count.
    _studentOverviewKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user.role == UserRole.admin;
    final isStudent = _user.role == UserRole.student;
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
          : isStudent
              ? StudentOverviewTab(key: _studentOverviewKey, user: _user)
              : RefreshIndicator(
                  onRefresh: _refreshProfile,
                  child: ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      _WelcomeCard(user: _user),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Overview & Primary Actions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RoleSections(role: _user.role, user: _user),
                      const SizedBox(height: AppSpacing.xl),
                      _QuickFeatureLaunchHub(user: _user),
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
                  icon: Icon(Icons.groups_outlined),
                  label: 'Users',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            )
          : isStudent
              ? BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: 0,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.outline,
                  onTap: _onStudentTabTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      label: 'Overview',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.badge_outlined),
                      label: 'My Profile',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.family_restroom),
                      label: 'Guardians',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.description_outlined),
                      label: 'Reports',
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
            icon: Icons.link,
            title: 'Linked Students',
            subtitle: 'View and manage students linked to your account.',
            route: 'GET /parents/my-students',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyStudentsPage())),
          ),
          _SectionSpec(
            icon: Icons.forum_rounded,
            title: 'Private Communication Hub',
            subtitle: 'Confidential messaging with class teachers & school admin.',
            route: 'Private Communication',
            onTap: () => Navigator.of(context).pushNamed(
                PrivateCommunicationPage.routeName,
                arguments: user),
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
            icon: Icons.psychology,
            title: 'Teacher Portal',
            subtitle: 'Record student results, guidance & custom subject bars.',
            route: 'Teacher Portal',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TeacherPortalPage())),
          ),
          _SectionSpec(
            icon: Icons.groups_outlined,
            title: 'My Classes & Rosters',
            subtitle: 'Manage class rosters and student attendance.',
            route: 'My Classes',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyClassesPage())),
          ),
          _SectionSpec(
            icon: Icons.forum_rounded,
            title: 'Private Communication Hub',
            subtitle: 'Direct confidential messaging with parents & admin.',
            route: 'Private Communication',
            onTap: () => Navigator.of(context).pushNamed(
                PrivateCommunicationPage.routeName,
                arguments: user),
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
            icon: Icons.manage_accounts_outlined,
            title: 'Manage Users',
            subtitle: 'All account categories, grouped with live counts.',
            route: 'GET /admin/{role}/pending',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageUsersPage())),
          ),
          _SectionSpec(
            icon: Icons.class_outlined,
            title: 'Class & Section Registration',
            subtitle:
                'Register classes, sections, rooms, student rosters & teacher assignments.',
            route: 'GET /school-management/classes',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ClassSectionManagementPage())),
          ),
          _SectionSpec(
            icon: Icons.family_restroom,
            title: 'Guardian Links',
            subtitle:
                'Parent-student links awaiting your decision, plus ones '
                'already approved or rejected.',
            route: 'GET /admin/relationships',
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GuardianLinksPage())),
          ),
          _SectionSpec(
            icon: Icons.forum_rounded,
            title: 'Private Communication Hub',
            subtitle: 'Confidential guardian inquiries & staff announcements.',
            route: 'Private Communication',
            onTap: () => Navigator.of(context).pushNamed(
                PrivateCommunicationPage.routeName,
                arguments: user),
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

class _SectionCard extends StatefulWidget {
  const _SectionCard({required this.spec});

  final _SectionSpec spec;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tappable = widget.spec.onTap != null;
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: tappable ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: tappable ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: tappable ? () => setState(() => _isPressed = false) : null,
        onTap: widget.spec.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: tappable
                    ? const Color(0xFFC7D2FE)
                    : const Color(0xFFE2E8F0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tappable
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.spec.icon,
                    color: tappable ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.spec.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.spec.subtitle,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      if (!tappable) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.spec.route,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (tappable)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickFeatureLaunchHub extends StatelessWidget {
  const _QuickFeatureLaunchHub({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Feature Dashboards Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(
              '5 Modules Available',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Student Portal Dashboard Launcher
        _StylishLauncherCard(
          title: 'Student Portal Dashboard',
          subtitle: 'Classes, tasks, announcements & schedule matrix',
          badgeText: '🎓 ACADEMIC PORTAL',
          badgeColor: Colors.white,
          badgeBgColor: Colors.white24,
          gradientColors: const [Color(0xFF6366F1), Color(0xFF7C3AED)],
          icon: Icons.dashboard_customize_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            StudentPortalDashboardPage.routeName,
            arguments: user,
          ),
        ),
        const SizedBox(height: 12),

        // GPA Progression & Analytics Launcher
        _StylishLauncherCard(
          title: 'GPA Progression & Analytics',
          subtitle: 'Semester trajectory, grades & target track',
          badgeText: '3.84 GPA • Top 5%',
          badgeColor: const Color(0xFF065F46),
          badgeBgColor: const Color(0xFFA7F3D0),
          gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B)],
          icon: Icons.auto_graph_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AcademicGpaProgressionPage.routeName,
            arguments: user,
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Grid for Health & Biometrics
        Row(
          children: [
            Expanded(
              child: _StylishTile(
                title: 'Calorie Tracker',
                subtitle: 'Radial dial & macros',
                badgeText: '🔥 1,232 kcal left',
                accentColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                icon: Icons.local_fire_department_rounded,
                onTap: () => Navigator.of(context).pushNamed(
                  CalorieNutritionDashboardPage.routeName,
                  arguments: user,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StylishTile(
                title: 'Stress Level',
                subtitle: 'Spline & equalizer',
                badgeText: '🛡️ Manageable • 46',
                accentColor: const Color(0xFFF97316),
                bgColor: const Color(0xFFFFEDD5),
                icon: Icons.monitor_heart_rounded,
                onTap: () => Navigator.of(context).pushNamed(
                  StressLevelDashboardPage.routeName,
                  arguments: user,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Full-width Health Overview Tile
        _StylishTile(
          title: 'Biometric Health Overview',
          subtitle: 'Multi-sensor sleep, pulse rate & HRV vitals preview',
          badgeText: '🌙 Sleep 6h 52m • ❤️ 74 bpm • ⚡ HRV 56 ms',
          accentColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFEDE9FE),
          icon: Icons.health_and_safety_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            BiometricHealthOverviewPage.routeName,
            arguments: user,
          ),
        ),
      ],
    );
  }
}

class _StylishLauncherCard extends StatefulWidget {
  const _StylishLauncherCard({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeBgColor,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final Color badgeBgColor;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_StylishLauncherCard> createState() => _StylishLauncherCardState();
}

class _StylishLauncherCardState extends State<_StylishLauncherCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.first.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: Colors.white, size: 20),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badgeBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: widget.badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.subtitle,
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StylishTile extends StatefulWidget {
  const _StylishTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    required this.bgColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_StylishTile> createState() => _StylishTileState();
}

class _StylishTileState extends State<_StylishTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          color: widget.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.accentColor, size: 18),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}