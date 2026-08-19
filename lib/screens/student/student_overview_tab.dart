import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/guardian_link.dart';
import '../../models/school_class.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/school_management_service.dart';
import '../../services/student_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/bento_grid_section.dart';
import '../../widgets/class_schedule_timetable.dart';
import '../../widgets/dashboard_grid_cards.dart';
import '../landing_page.dart';
import 'student_profile_page.dart';

/// Bento-Grid Front-Page Overview Dashboard for School Guardian
class StudentOverviewTab extends StatefulWidget {
  const StudentOverviewTab({super.key, required this.user});

  final User user;

  @override
  State<StudentOverviewTab> createState() => StudentOverviewTabState();
}

class StudentOverviewTabState extends State<StudentOverviewTab> {
  final _studentService = StudentService();
  final _schoolService = SchoolManagementService();
  final _authService = AuthService();
  final _attendanceService = AttendanceService();
  final _teacherService = TeacherService();

  List<GuardianLink>? _guardians;
  SchoolClass? _assignedClass;
  List<AttendanceRecord> _attendanceRecords = [];
  List<GradeEntry> _gradeEntries = [];

  bool _loading = true;
  bool _loggingOut = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final guardians = await _studentService.getMyGuardians();
      final cls = await _schoolService.getStudentClass(widget.user.id,
          studentCode: widget.user.studentId);
      final code = widget.user.studentId;
      var attendance =
          await _attendanceService.getStudentAttendance(widget.user.id);
      if (attendance.isEmpty && code != null && code.isNotEmpty) {
        attendance = await _attendanceService.getStudentAttendance(code);
      }
      var grades = await _teacherService.getGradesForStudent(widget.user.id);
      if (grades.isEmpty && code != null && code.isNotEmpty) {
        grades = await _teacherService.getGradesForStudent(code);
      }

      if (!mounted) return;
      setState(() {
        _guardians = guardians;
        _assignedClass = cls;
        _attendanceRecords = attendance;
        _gradeEntries = grades;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
    } catch (_) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text(
            'Are you sure you want to log out of your School Guardian account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final guardianCount = _guardians?.length;

    int presentCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.present)
        .length;
    int absentCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.absent)
        .length;
    int lateCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.late)
        .length;
    int excusedCount = _attendanceRecords
        .where((r) => r.status == AttendanceStatus.excused)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Top App Bar & Profile Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Welcome back, ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          user.firstName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.studentId != null && user.studentId!.isNotEmpty
                          ? 'Student ID: ${user.studentId} • ${user.email}'
                          : user.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.circle,
                              size: 8, color: Color(0xFF6366F1)),
                          SizedBox(width: 4),
                          Text(
                            'Student',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => StudentProfilePage(initialUser: user),
                      )),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🥑', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Assigned Class Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KukieAccent.violet, KukieAccent.violetDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: KukieAccent.violet.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _assignedClass != null
                              ? _assignedClass!.displayName
                              : 'Class Assignment Enrolled',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _assignedClass != null
                              ? 'Room: ${_assignedClass!.roomNumber ?? 'Unassigned'} • Year: ${_assignedClass!.academicYear}'
                              : 'Academic Term 2025-2026 • Computer Science Section A',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null && guardianCount == null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
            ],
            const SizedBox(height: 16),

            // Guardians & Account Status Quick Stat Cards
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.family_restroom_rounded,
                    label: 'Linked Guardians',
                    value: _loading && guardianCount == null
                        ? '—'
                        : '${guardianCount ?? 0}',
                    color: KukieAccent.violet,
                    background: KukieAccent.violetTint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.verified_user_rounded,
                    label: 'Account status',
                    value: user.status != null
                        ? _statusLabel(user.status!)
                        : 'Active',
                    color: const Color(0xFF10B981),
                    background: const Color(0xFFD1FAE5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Attendance Overview Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: KukieAccent.violet, size: 20),
                            SizedBox(width: 8),
                            Text('Attendance History',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: KukieAccent.violetTint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${_attendanceRecords.length} records',
                              style: const TextStyle(
                                  color: KukieAccent.violet,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _attendanceChip(
                            'Present', presentCount, KukieAccent.success),
                        _attendanceChip('Absent', absentCount, Colors.red),
                        _attendanceChip('Late', lateCount, Colors.orange),
                        _attendanceChip('Excused', excusedCount, Colors.blue),
                      ],
                    ),
                    if (_attendanceRecords.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Text('Recent Records:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 8),
                      ..._attendanceRecords.take(3).map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.date,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: r.status == AttendanceStatus.present
                                        ? KukieAccent.success
                                            .withValues(alpha: 0.15)
                                        : r.status == AttendanceStatus.absent
                                            ? Colors.red
                                                .withValues(alpha: 0.15)
                                            : Colors.orange
                                                .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    r.status.displayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: r.status == AttendanceStatus.present
                                          ? KukieAccent.success
                                          : r.status == AttendanceStatus.absent
                                              ? Colors.red
                                              : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Academic Grades Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assessment_outlined,
                            color: KukieAccent.violet, size: 20),
                        SizedBox(width: 8),
                        Text('Academic Grades',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_gradeEntries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                              'No grade reports submitted by teachers yet.',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                        ),
                      )
                    else
                      ..._gradeEntries.map((g) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(g.subject,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    Text(
                                      '${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(1)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: KukieAccent.violet,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${g.assessmentType.label} • Term: ${g.term}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text(g.letterGrade,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13)),
                                  ],
                                ),
                                if (g.parentRecommendation != null &&
                                    g.parentRecommendation!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                      'Teacher note: "${g.parentRecommendation}"',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87)),
                                ],
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick-Access Bento / Module Grid
            BentoGridSection(user: user),
            const SizedBox(height: 24),

            // Modern Card Grid Dashboard Section
            const DashboardGridCardsSection(),
            const SizedBox(height: 24),

            // Interactive Weekly Timetable Schedule Matrix
            const ClassScheduleTimetableWidget(),
            const SizedBox(height: 28),

            // Account & Utilities Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account & System Utilities',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // My Profile & Settings Row
                  InkWell(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => StudentProfilePage(initialUser: user),
                    )),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_outline_rounded,
                                color: Color(0xFF475569), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'My Profile & Settings',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B)),
                                ),
                                Text(
                                  'Edit account details & security',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 24),

                  // Log Out Action Button
                  InkWell(
                    onTap: _confirmLogout,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: Color(0xFFEF4444), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEF4444)),
                                ),
                                Text(
                                  'Sign out of School Guardian',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                          if (_loggingOut)
                            const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _attendanceChip(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: background, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}