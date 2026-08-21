import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/guardian_link.dart';
import '../../models/homework_entry.dart';
import '../../models/school_class.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/homework_service.dart';
import '../../services/school_management_service.dart';
import '../../services/student_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'homework_ai_assistant_page.dart';
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
  final _attendanceService = AttendanceService();
  final _teacherService = TeacherService();
  final _homeworkService = HomeworkService();

  final _scrollController = ScrollController();
  final _attendanceKey = GlobalKey();
  final _homeworkKey = GlobalKey();
  final _gradesKey = GlobalKey();

  List<GuardianLink>? _guardians;
  SchoolClass? _assignedClass;
  List<AttendanceRecord> _attendanceRecords = [];
  List<GradeEntry> _gradeEntries = [];
  List<HomeworkEntry> _homeworkEntries = [];
  List<HomeworkEntry> _newHomeworks = [];   // homework not yet seen
  bool _notificationDismissed = false;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToSection(String section) {
    if (section == 'top') {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return;
    }

    GlobalKey? key;
    if (section == 'attendance') key = _attendanceKey;
    if (section == 'homework') key = _homeworkKey;
    if (section == 'grades') key = _gradesKey;

    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
      // Use the new getMyHomework() which calls /homework/student/me
      var homeworks = await _homeworkService.getStudentHomeworks(widget.user.id);

      // Check for unseen new homework (for notification banner)
      final newHw = await _homeworkService.getNewHomeworks();

      if (!mounted) return;
      setState(() {
        _guardians = guardians;
        _assignedClass = cls;
        _attendanceRecords = attendance;
        _gradeEntries = grades;
        _homeworkEntries = homeworks;
        _newHomeworks = newHw;
        _notificationDismissed = false;
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

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          if (_loading && _guardians == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // Top App Bar & Profile Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Welcome back, ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            TextSpan(
                              text: user.firstName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 6),
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
                          child: Icon(Icons.person_rounded, color: Color(0xFF6366F1), size: 22),
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
                    label: 'Account Status',
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

            // ── Web-Identical My Attendance Records Section ──
            Column(
              key: _attendanceKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'My Attendance Records',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Track your daily attendance history, tardiness records, and attendance percentage.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _load,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 32),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF475569)),
                      label: const Text('Refresh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 4 Web-Style Metric Cards Grid (2x2)
                Row(
                  children: [
                    Expanded(
                      child: _webStatCard(
                        label: 'ATTENDANCE RATE',
                        value: _attendanceRecords.isNotEmpty
                            ? '${(((presentCount + excusedCount) / _attendanceRecords.length) * 100).toStringAsFixed(0)}%'
                            : '100%',
                        labelColor: const Color(0xFF6366F1),
                        valueColor: const Color(0xFF4338CA),
                        bgColor: const Color(0xFFEEF2FF),
                        borderColor: const Color(0xFFE0E7FF),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _webStatCard(
                        label: 'PRESENT',
                        value: '$presentCount days',
                        labelColor: const Color(0xFF10B981),
                        valueColor: const Color(0xFF047857),
                        bgColor: const Color(0xFFECFDF5),
                        borderColor: const Color(0xFFA7F3D0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _webStatCard(
                        label: 'ABSENT',
                        value: '$absentCount days',
                        labelColor: const Color(0xFFEF4444),
                        valueColor: const Color(0xFFB91C1C),
                        bgColor: const Color(0xFFFEF2F2),
                        borderColor: const Color(0xFFFECACA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _webStatCard(
                        label: 'TARDY / LATE',
                        value: '$lateCount days',
                        labelColor: const Color(0xFFD97706),
                        valueColor: const Color(0xFFB45309),
                        bgColor: const Color(0xFFFFFBEB),
                        borderColor: const Color(0xFFFDE68A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Attendance Log Container Table ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attendance Log',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Table Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: const [
                            Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5))),
                            Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5))),
                            Expanded(flex: 3, child: Text('TEACHER REMARK / REASON', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_attendanceRecords.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No attendance logs recorded yet.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        )
                      else
                        ..._attendanceRecords.map((r) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      r.date,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: r.status == AttendanceStatus.present
                                              ? const Color(0xFFDCFCE7)
                                              : r.status == AttendanceStatus.absent
                                                  ? const Color(0xFFFEF2F2)
                                                  : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: r.status == AttendanceStatus.present
                                                  ? const Color(0xFF15803D)
                                                  : r.status == AttendanceStatus.absent
                                                      ? const Color(0xFFDC2626)
                                                      : const Color(0xFFD97706),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              r.status == AttendanceStatus.late ? 'LATE' : r.status.toDbString(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: r.status == AttendanceStatus.present
                                                    ? const Color(0xFF15803D)
                                                    : r.status == AttendanceStatus.absent
                                                        ? const Color(0xFFDC2626)
                                                        : const Color(0xFFD97706),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      (r.note != null && r.note!.isNotEmpty) ? r.note! : '—',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── New Homework Notification Banner ──
            if (_newHomeworks.isNotEmpty && !_notificationDismissed)
              _buildNewHomeworkBanner(),

            // Assigned Homework Card
            _buildHomeworkSection(),
            const SizedBox(height: AppSpacing.md),

            // ── Modern Academic Grades Card ──
            Container(
              key: _gradesKey,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assessment_rounded,
                                  color: KukieAccent.violet, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Academic Grades & Reports',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${_gradeEntries.length} Subjects',
                          style: const TextStyle(
                            color: KukieAccent.violet,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_gradeEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No grade reports submitted by teachers yet.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        ),
                      ),
                    )
                  else
                    ..._gradeEntries.map((g) {
                      final progress = (g.maxScore > 0) ? (g.score / g.maxScore).clamp(0.0, 1.0) : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
                                        child: Text(
                                          g.subject.isNotEmpty ? g.subject[0].toUpperCase() : 'S',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              g.subject,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${g.assessmentType.label} • Term ${g.term}',
                                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF6366F1),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Grade ${g.letterGrade}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                              ),
                            ),
                            if (g.parentRecommendation != null && g.parentRecommendation!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: const Border(
                                    left: BorderSide(color: Color(0xFF6366F1), width: 3),
                                  ),
                                ),
                                child: Text(
                                  'Teacher remark: "${g.parentRecommendation}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _webStatCard({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: labelColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewHomeworkBanner() {
    final count = _newHomeworks.length;
    final label = count == 1
        ? '1 new homework assignment from your teacher!'
        : '$count new homework assignments from your teachers!';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Scroll or highlight the homework section
            _homeworkService.markAllSeen();
            setState(() => _notificationDismissed = true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('📚', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to dismiss • Scroll down to view',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _homeworkService.markAllSeen();
                    setState(() => _notificationDismissed = true);
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(AccountStatus status) =>
      status == AccountStatus.active ? 'Active' : status.name;

  Widget _buildHomeworkSection() {
    return Card(
      key: _homeworkKey,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Icon(Icons.assignment_rounded, color: KukieAccent.violet, size: 20),
                    SizedBox(width: 8),
                    Text('Assigned Homework', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_homeworkEntries.length} Active',
                    style: const TextStyle(color: KukieAccent.violet, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_homeworkEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.task_alt_rounded, size: 40, color: Colors.green.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'All caught up! No pending homework.',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (int index = 0; index < _homeworkEntries.length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        final hw = _homeworkEntries[index];
                        final isPastDue = hw.dueDate.isBefore(DateTime.now());
                        final dueFormatted = DateFormat('MMM d, yyyy').format(hw.dueDate);
                        final isNew = _newHomeworks.any((n) => n.id == hw.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isNew
                                  ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                                  : const Color(0xFFF3F4F6),
                              width: isNew ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── New badge + subject/due row ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        if (isNew) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('NEW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: KukieAccent.violetTint,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            hw.subject,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPastDue ? Colors.red.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 12, color: isPastDue ? Colors.red : Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            isPastDue ? 'Past Due: $dueFormatted' : 'Due: $dueFormatted',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isPastDue ? Colors.red : Colors.orange.shade800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // ── Title + description ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              if (hw.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                  child: Text(
                                    hw.description,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              // ── AI Help button ──
                              Padding(
                                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => HomeworkAiAssistantPage(homework: hw),
                                      ));
                                    },
                                    icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                                    label: const Text('Get AI Help', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E1B4B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
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