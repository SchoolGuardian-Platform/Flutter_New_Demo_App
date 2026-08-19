import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/guardian_link.dart';
import '../../models/school_class.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/school_management_service.dart';
import '../../services/student_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

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
  final _attendanceService = AttendanceService();
  final _teacherService = TeacherService();

  List<GuardianLink>? _guardians;
  SchoolClass? _assignedClass;
  List<AttendanceRecord> _attendanceRecords = [];
  List<GradeEntry> _gradeEntries = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardians = await _studentService.getMyGuardians();
      final cls = await _schoolService.getStudentClass(widget.user.id, studentCode: widget.user.studentId);
      final code = widget.user.studentId;
      var attendance = await _attendanceService.getStudentAttendance(widget.user.id);
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

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final guardianCount = _guardians?.length;

    int presentCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    int absentCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.absent).length;
    int lateCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.late).length;
    int excusedCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.excused).length;

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

          // Real Attendance Overview Card
          Card(
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
                          Icon(Icons.calendar_today, color: KukieAccent.violet, size: 20),
                          SizedBox(width: 8),
                          Text('Attendance History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: KukieAccent.violetTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('${_attendanceRecords.length} records', style: const TextStyle(color: KukieAccent.violet, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _attendanceChip('Present', presentCount, KukieAccent.success),
                      _attendanceChip('Absent', absentCount, Colors.red),
                      _attendanceChip('Late', lateCount, Colors.orange),
                      _attendanceChip('Excused', excusedCount, Colors.blue),
                    ],
                  ),
                  if (_attendanceRecords.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Recent Records:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    ..._attendanceRecords.take(3).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(r.date, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: r.status == AttendanceStatus.present
                                      ? KukieAccent.success.withValues(alpha: 0.15)
                                      : r.status == AttendanceStatus.absent
                                          ? Colors.red.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(alpha: 0.15),
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

          // Real Academic Grades Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.assessment_outlined, color: KukieAccent.violet, size: 20),
                      SizedBox(width: 8),
                      Text('Academic Grades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_gradeEntries.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text('No grade reports submitted by teachers yet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ),
                    )
                  else
                    ..._gradeEntries.map((g) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(g.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(
                                    '${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(1)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: KukieAccent.violet, fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${g.assessmentType.label} • Term: ${g.term}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(g.letterGrade, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              if (g.parentRecommendation != null && g.parentRecommendation!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Teacher note: "${g.parentRecommendation}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87)),
                              ],
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _attendanceChip(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
