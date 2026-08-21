import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/homework_entry.dart';
import '../../models/school_class.dart';
import '../../models/teacher_profile.dart';
import '../../models/user.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/homework_service.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';
import '../communication/private_communication_page.dart';
import '../landing_page.dart';
import 'add_grade_page.dart';
import 'manage_homework_page.dart';
import 'mark_attendance_page.dart';
import 'my_classes_page.dart';
import 'teacher_appointments_page.dart';
import 'teacher_notes_page.dart';


class TeacherPortalPage extends StatefulWidget {
  const TeacherPortalPage({super.key});

  static const routeName = '/teacher/portal';

  @override
  State<TeacherPortalPage> createState() => _TeacherPortalPageState();
}

class _TeacherPortalPageState extends State<TeacherPortalPage> {
  final _teacherService = TeacherService();
  final _schoolService = SchoolManagementService();
  final _homeworkService = HomeworkService();
  final _appointmentService = AppointmentService();

  int _currentIndex = 0;
  bool _loading = true;
  String _teacherName = 'Teacher';
  User? _currentUser;
  TeacherProfile? _teacherProfile;
  List<SchoolClass> _assignedClasses = [];
  List<HomeworkEntry> _homeworks = [];
  List<GradeEntry> _grades = [];
  List<AppointmentItem> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService().getMe();
      final name = '${user.firstName} ${user.lastName}'.trim();
      _teacherName = name.isNotEmpty ? name : 'Teacher';

      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();

      final filteredClasses = allClasses.where((sc) {
        final isTeacherInClassList = sc.teachers.any((t) =>
            (t.teacherId.isNotEmpty && t.teacherId == profile.id) ||
            (t.teacherName.isNotEmpty && t.teacherName.toLowerCase() == profile.fullName.toLowerCase()));

        final isClassInProfileList = profile.assignedClasses.any((ac) {
          final cleanAc = ac.trim().toLowerCase();
          return cleanAc == sc.displayName.trim().toLowerCase() ||
                 cleanAc == sc.id.trim().toLowerCase() ||
                 cleanAc == sc.shortLabel.trim().toLowerCase();
        });

        return isTeacherInClassList || isClassInProfileList;
      }).toList();

      final activeClasses = filteredClasses.isNotEmpty ? filteredClasses : allClasses;

      final homeworks = await _homeworkService.getTeacherHomeworks();
      final grades = await _teacherService.getGradeEntries();
      final appointments = await _appointmentService.getTeacherAppointments();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _teacherProfile = profile;
          _assignedClasses = activeClasses;
          _homeworks = homeworks;
          _grades = grades;
          _appointments = appointments;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _navigateToMyClasses([String? classId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyClassesPage(initialClassId: classId),
      ),
    ).then((_) => _loadData());
  }

  void _navigateToAddGrade() {
    Navigator.of(context).pushNamed(AddGradePage.routeName).then((_) => _loadData());
  }

  void _navigateToManageHomework() {
    Navigator.of(context).pushNamed(ManageHomeworkPage.routeName).then((_) => _loadData());
  }

  void _navigateToMarkAttendance() {
    Navigator.of(context).pushNamed(MarkAttendancePage.routeName).then((_) => _loadData());
  }

  void _navigateToTeacherNotes() {
    Navigator.of(context).pushNamed(TeacherNotesPage.routeName).then((_) => _loadData());
  }

  void _navigateToAppointments() {
    Navigator.of(context).pushNamed(TeacherAppointmentsPage.routeName).then((_) => _loadData());
  }

  void _navigateToChat() {
    if (_currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PrivateCommunicationPage(user: _currentUser!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User profile loading, please wait...')),
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Teacher Portal?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService().logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(LandingPage.routeName, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _teacherName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: KukieAccent.violetTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: KukieAccent.violet, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Portal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Faculty Hub • $firstName',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(firstName),
                _buildAcademicHubTab(),
                _buildParentTab(),
                _buildProfileTab(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: KukieAccent.violet,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school_rounded),
              label: 'Academic Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt_rounded),
              label: 'Parents',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ── 1. HOME TAB ─────────────────────────────────────────────────────────────
  Widget _buildHomeTab(String firstName) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          _TopWelcomeBanner(
            firstName: firstName,
            onTakeAttendance: _navigateToMarkAttendance,
            onCreateHomework: _navigateToManageHomework,
          ),
          const SizedBox(height: 16),

          // Metrics
          _MetricsRow(
            assignedClassesCount: _assignedClasses.length,
            activeHomeworksCount: _homeworks.length,
            gradeEntriesCount: _grades.length,
            pendingAppointmentsCount: _appointments.where((a) => a.status.toUpperCase() == 'PENDING').length,
            onClassesTap: () => setState(() => _currentIndex = 1),
            onHomeworkTap: _navigateToManageHomework,
            onGradesTap: _navigateToAddGrade,
            onAppointmentsTap: _navigateToAppointments,
          ),
          const SizedBox(height: 16),

          // Teaching Classes Card
          _TeachingScheduleCard(
            classes: _assignedClasses,
            onViewRoster: () => _navigateToMyClasses(),
            onSelectClass: (id) => _navigateToMyClasses(id),
          ),
          const SizedBox(height: 16),

          // Appointments Card
          _ParentAppointmentsCard(
            appointments: _appointments,
            onViewAll: _navigateToAppointments,
          ),
          const SizedBox(height: 16),

          // Homework Card
          _RecentHomeworkCard(
            homeworks: _homeworks,
            onViewAll: _navigateToManageHomework,
          ),
        ],
      ),
    );
  }

  // ── 2. ACADEMIC HUB TAB ─────────────────────────────────────────────────────
  Widget _buildAcademicHubTab() {
    final classCount = _assignedClasses.length;
    final classesSummaryStr = classCount > 0
        ? _assignedClasses.map((c) => c.displayName.isNotEmpty ? c.displayName : 'Grade ${c.grade}-${c.section}').take(2).join(', ') + (classCount > 2 ? ' +${classCount - 2} more' : '')
        : 'No classes assigned yet';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F4F46E5),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Hub 🎓',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Central management hub for class rosters, attendance sheet, gradebook entry, homework, and student observation notes.',
                  style: TextStyle(fontSize: 12, color: Color(0xE6FFFFFF), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Featured Hero Card: Class Rosters & Student 360°
          InkWell(
            onTap: () => _navigateToMyClasses(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KukieAccent.violet.withAlpha(90), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A5B4FE0),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KukieAccent.violetTint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.groups_rounded, color: KukieAccent.violet, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Class Rosters & Student 360°',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              classesSummaryStr,
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: KukieAccent.violet),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: KukieAccent.violet),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'View student cohorts, performance transcripts, behavioral notes, and linked parent contact details.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$classCount Assigned Cohort${classCount == 1 ? '' : 's'}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                      ),
                      const Text(
                        'Open Roster 360° →',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Section Header for Quick Actions
          const Text(
            'QUICK ACADEMIC ACTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // 2. Quick Actions Grid (4 Cards)
          Row(
            children: [
              Expanded(
                child: _AcademicHubActionCard(
                  icon: Icons.star_outline_rounded,
                  iconBg: const Color(0xFFF0EEFF),
                  iconColor: KukieAccent.violet,
                  title: 'Record Grade',
                  subtitle: 'Log test/quiz score',
                  onTap: _navigateToAddGrade,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AcademicHubActionCard(
                  icon: Icons.assignment_outlined,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF0284C7),
                  title: 'Post Homework',
                  subtitle: 'Assign homework task',
                  onTap: _navigateToManageHomework,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AcademicHubActionCard(
                  icon: Icons.fact_check_outlined,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  title: 'Daily Attendance',
                  subtitle: 'Mark student status',
                  onTap: _navigateToMarkAttendance,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AcademicHubActionCard(
                  icon: Icons.edit_note_rounded,
                  iconBg: const Color(0xFFFEF3C7),
                  iconColor: const Color(0xFFD97706),
                  title: 'Student Notes',
                  subtitle: 'Log behavioral note',
                  onTap: _navigateToTeacherNotes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. PARENT TAB ───────────────────────────────────────────────────────────
  Widget _buildParentTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parent Engagement Hub 💬',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 6),
                Text(
                  'Direct messaging with parents, meeting appointment requests, and student progress notes.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE0F2FE)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parent Chat Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Direct Parent Messaging', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      SizedBox(height: 2),
                      Text('Chat with registered parents about student performance', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _navigateToChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text('Open Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Appointments Card
          _ParentAppointmentsCard(
            appointments: _appointments,
            onViewAll: _navigateToAppointments,
          ),
        ],
      ),
    );
  }

  // ── 4. PROFILE TAB ──────────────────────────────────────────────────────────
  Widget _buildProfileTab() {
    final profile = _teacherProfile ?? TeacherProfile.sample();
    final teacherNameStr = _teacherName.trim().isNotEmpty ? _teacherName.trim() : 'Teacher';
    final initial = teacherNameStr.substring(0, 1).toUpperCase();
    final emailStr = profile.email.isNotEmpty ? profile.email : (_currentUser?.email ?? 'teacher@schoolguardian.app');
    final empIdStr = profile.employeeId.isNotEmpty ? profile.employeeId : 'TCH-1001';
    final deptStr = profile.department.isNotEmpty ? profile.department : 'Academic Faculty';
    final majorStr = profile.majorField.isNotEmpty ? profile.majorField : 'Educational Pedagogy';
    final subsList = profile.assignedSubjects;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: KukieAccent.violet,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(teacherNameStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(emailStr, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Faculty ID: $empIdStr',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Academic Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Academic Identity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                _ProfileDetailRow(icon: Icons.domain_rounded, label: 'Department', value: deptStr),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _ProfileDetailRow(icon: Icons.school_outlined, label: 'Major Field', value: majorStr),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Assigned Subjects Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Assigned Subjects', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                if (subsList.isEmpty)
                  const Text('No specific subjects assigned.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: subsList.map((sub) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: KukieAccent.violetTint,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: KukieAccent.violet.withAlpha(50)),
                        ),
                        child: Text(
                          sub,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 18),
            label: const Text('Sign Out of Teacher Portal', style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFFECDD3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Components ───────────────────────────────────────────────────────────────

class _ProfileDetailRow extends StatelessWidget {
  const _ProfileDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: KukieAccent.violet),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }
}

class _TopWelcomeBanner extends StatelessWidget {
  const _TopWelcomeBanner({
    required this.firstName,
    required this.onTakeAttendance,
    required this.onCreateHomework,
  });

  final String firstName;
  final VoidCallback onTakeAttendance;
  final VoidCallback onCreateHomework;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334F46E5),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome back, $firstName! 👋',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Faculty Portal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Manage student attendance, publish homework, log grades, and communicate with parents.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xE6FFFFFF),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTakeAttendance,
                  icon: const Icon(Icons.fact_check_outlined, size: 15, color: Color(0xFF4F46E5)),
                  label: const Text(
                    'Take Attendance',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCreateHomework,
                  icon: const Icon(Icons.add, size: 15, color: Colors.white),
                  label: const Text(
                    'Create Homework',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.assignedClassesCount,
    required this.activeHomeworksCount,
    required this.gradeEntriesCount,
    required this.pendingAppointmentsCount,
    required this.onClassesTap,
    required this.onHomeworkTap,
    required this.onGradesTap,
    required this.onAppointmentsTap,
  });

  final int assignedClassesCount;
  final int activeHomeworksCount;
  final int gradeEntriesCount;
  final int pendingAppointmentsCount;
  final VoidCallback onClassesTap;
  final VoidCallback onHomeworkTap;
  final VoidCallback onGradesTap;
  final VoidCallback onAppointmentsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Assigned Classes',
                value: '$assignedClassesCount',
                icon: Icons.class_outlined,
                accentColor: KukieAccent.violet,
                bgColor: KukieAccent.violetTint,
                onTap: onClassesTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Active Homeworks',
                value: '$activeHomeworksCount',
                icon: Icons.assignment_outlined,
                accentColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                onTap: onHomeworkTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Grade Records',
                value: '$gradeEntriesCount',
                icon: Icons.grade_outlined,
                accentColor: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
                onTap: onGradesTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                title: 'Pending Appts',
                value: '$pendingAppointmentsCount',
                icon: Icons.calendar_today_outlined,
                accentColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFFFBEB),
                onTap: onAppointmentsTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeachingScheduleCard extends StatelessWidget {
  const _TeachingScheduleCard({
    required this.classes,
    required this.onViewRoster,
    this.onSelectClass,
  });

  final List<SchoolClass> classes;
  final VoidCallback onViewRoster;
  final void Function(String classId)? onSelectClass;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Teaching Classes',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Assigned sections & enrollment list',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewRoster,
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: KukieAccent.violet, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: KukieAccent.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No assigned classes yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            Column(
              children: classes.take(3).map((c) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      if (onSelectClass != null) {
                        onSelectClass!(c.id);
                      } else {
                        onViewRoster();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: KukieAccent.violetTint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Grade ${c.grade}-${c.section}',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.displayName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Academic Year: ${c.academicYear}',
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${c.studentCount} Students',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}



class _ParentAppointmentsCard extends StatelessWidget {
  const _ParentAppointmentsCard({
    required this.appointments,
    required this.onViewAll,
  });

  final List<AppointmentItem> appointments;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parent Appointment Requests',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Scheduled meetings with parents',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: KukieAccent.violet, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: KukieAccent.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (appointments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No active appointment requests right now.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ),
            )
          else
            Column(
              children: appointments.take(3).map((apt) {
                final parentInitial = (apt.parentName.trim().isNotEmpty)
                    ? apt.parentName.trim().substring(0, 1).toUpperCase()
                    : 'P';
                final displayName = (apt.parentName.trim().isNotEmpty) ? apt.parentName.trim() : 'Parent';
                final studentDisplayName = (apt.studentName.trim().isNotEmpty) ? apt.studentName.trim() : 'Student';
                final statusStr = apt.status.isNotEmpty ? apt.status : 'PENDING';
                final dateStr = apt.date.isNotEmpty ? apt.date : 'Scheduled';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: KukieAccent.violetTint,
                        child: Text(
                          parentInitial,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Student: $studentDisplayName • $dateStr',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusStr == 'ACCEPTED' ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusStr,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusStr == 'ACCEPTED' ? const Color(0xFF10B981) : const Color(0xFFD97706),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _RecentHomeworkCard extends StatelessWidget {
  const _RecentHomeworkCard({
    required this.homeworks,
    required this.onViewAll,
  });

  final List<HomeworkEntry> homeworks;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final recent = homeworks.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Homework Assignments',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Active tasks & published submissions',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, color: KukieAccent.violet, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: KukieAccent.violet),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No homework assignments created yet.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            Column(
              children: recent.map((hw) {
                final titleStr = hw.title.isNotEmpty ? hw.title : 'Homework Task';
                final subjectStr = hw.subject.isNotEmpty ? hw.subject : 'General';
                final dueStr = hw.dueDate.toString().split(' ')[0];

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF0284C7), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleStr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$subjectStr • Due: $dueStr',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AcademicHubActionCard extends StatelessWidget {
  const _AcademicHubActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x04000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
