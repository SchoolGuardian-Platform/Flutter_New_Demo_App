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
import '../admin/manage_users_page.dart';
import '../landing_page.dart';
import '../parent/parent_my_children_page.dart';
import '../student_attendance_page.dart';
import '../teacher/teacher_attendance_page.dart';
import '../teacher/teacher_grades_page.dart';
import '../teacher/teacher_homework_page.dart';

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
  int _pendingCount = 0;
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
    } catch (_) {}
  }

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

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
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
        return;
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
                          ?.copyWith(color: AppColors.error),
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

class _RoleSections extends StatelessWidget {
  const _RoleSections({required this.role, required this.user});

  final UserRole role;
  final User user;

  List<_SectionSpec> _buildSpecs(BuildContext context) {
    final specs = <_SectionSpec>[];
    switch (role) {
      case UserRole.student:
        specs.addAll([
          _SectionSpec(
            icon: Icons.event_available_outlined,
            title: 'My Attendance',
            subtitle: 'View your attendance history and records.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => StudentAttendancePage(user: user),
            )),
          ),
          _SectionSpec(
            icon: Icons.class_outlined,
            title: 'My Classes',
            subtitle: 'See your enrolled classes and schedule.',
            onTap: () {},
          ),
        ]);
        break;
      case UserRole.parent:
        specs.addAll([
          _SectionSpec(
            icon: Icons.people_outline,
            title: 'My Children',
            subtitle: 'View your linked students\' information.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ParentMyChildrenPage(),
            )),
          ),
          _SectionSpec(
            icon: Icons.event_available_outlined,
            title: 'Attendance Records',
            subtitle: 'Review your child\'s attendance history.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const ParentMyChildrenPage(),
            )),
          ),
        ]);
        break;
      case UserRole.teacher:
        specs.addAll([
          _SectionSpec(
            icon: Icons.check_circle_outline,
            title: 'Attendance',
            subtitle: 'Record and manage class attendance.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const TeacherAttendancePage(),
            )),
          ),
          _SectionSpec(
            icon: Icons.grade_outlined,
            title: 'Grades',
            subtitle: 'Enter and review student grades.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const TeacherGradesPage(),
            )),
          ),
          _SectionSpec(
            icon: Icons.assignment_outlined,
            title: 'Homework',
            subtitle: 'Post and manage homework assignments.',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const TeacherHomeworkPage(),
            )),
          ),
        ]);
        break;
      default:
        specs.add(
          _SectionSpec(
            icon: Icons.dashboard_customize_outlined,
            title: 'Getting Started',
            subtitle: 'Your personalized tools will appear here.',
            onTap: () {},
          ),
        );
    }
    return specs;
  }

  @override
  Widget build(BuildContext context) {
    final specs = _buildSpecs(context);
    return Column(
      children: [
        for (final spec in specs)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _SectionCard(spec: spec),
          ),
      ],
    );
  }
}



class _SectionSpec {
  const _SectionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.spec});

  final _SectionSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: spec.onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(spec.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spec.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spec.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}