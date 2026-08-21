import 'package:flutter/material.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/homework_entry.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../services/homework_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';
import 'homework_ai_assistant_page.dart';
import 'student_teacher_notes_tab.dart';

class StudentAcademicHubPage extends StatefulWidget {
  const StudentAcademicHubPage({
    super.key,
    required this.user,
    this.initialSubIndex = 0,
  });

  final User user;
  final int initialSubIndex;

  @override
  State<StudentAcademicHubPage> createState() => _StudentAcademicHubPageState();
}

class _StudentAcademicHubPageState extends State<StudentAcademicHubPage> {
  late int _selectedSubIndex;

  final _attendanceService = AttendanceService();
  final _teacherService = TeacherService();
  final _homeworkService = HomeworkService();

  List<AttendanceRecord> _attendanceRecords = [];
  List<GradeEntry> _gradeEntries = [];
  List<HomeworkEntry> _homeworkEntries = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _selectedSubIndex = widget.initialSubIndex;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final code = widget.user.studentId;
      var attendance = await _attendanceService.getStudentAttendance(widget.user.id);
      if (attendance.isEmpty && code != null && code.isNotEmpty) {
        attendance = await _attendanceService.getStudentAttendance(code);
      }

      var grades = await _teacherService.getGradesForStudent(widget.user.id);
      if (grades.isEmpty && code != null && code.isNotEmpty) {
        grades = await _teacherService.getGradesForStudent(code);
      }

      var homeworks = await _homeworkService.getStudentHomeworks(widget.user.id);

      if (!mounted) return;
      setState(() {
        _attendanceRecords = attendance;
        _gradeEntries = grades;
        _homeworkEntries = homeworks;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: const [
            Icon(Icons.school_rounded, color: KukieAccent.violet, size: 24),
            SizedBox(width: 10),
            Text(
              'Academic Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Segmented Sub-Tab Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildSubTab(0, 'Attendance', Icons.calendar_month_rounded),
                  _buildSubTab(1, 'Grades', Icons.assessment_rounded),
                  _buildSubTab(2, 'Homework', Icons.assignment_rounded),
                  _buildSubTab(3, 'Feedback', Icons.rate_review_rounded),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Body Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : IndexedStack(
                    index: _selectedSubIndex,
                    children: [
                      _buildAttendanceView(),
                      _buildGradesView(),
                      _buildHomeworkView(),
                      StudentTeacherNotesTab(user: widget.user),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTab(int index, String label, IconData icon) {
    final selected = _selectedSubIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? KukieAccent.violet : const Color(0xFF64748B),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? KukieAccent.violet : const Color(0xFF64748B),
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

  // ── Attendance Subview ──────────────────────────────────────────
  Widget _buildAttendanceView() {
    int presentCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    int absentCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.absent).length;
    int lateCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.late).length;
    int excusedCount = _attendanceRecords.where((r) => r.status == AttendanceStatus.excused).length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track your daily attendance history, tardiness records, and attendance percentage.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _statMetricCard(
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
                child: _statMetricCard(
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
                child: _statMetricCard(
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
                child: _statMetricCard(
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
          const SizedBox(height: 20),

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
                const Text(
                  'Attendance Log',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      Expanded(flex: 3, child: Text('TEACHER REMARK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_attendanceRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No attendance logs recorded yet.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))),
                  )
                else
                  ..._attendanceRecords.map((r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: Text(r.date, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: r.status == AttendanceStatus.present
                                      ? const Color(0xFFDCFCE7)
                                      : r.status == AttendanceStatus.late
                                          ? const Color(0xFFFFFBEB)
                                          : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  r.status == AttendanceStatus.late ? 'LATE' : r.status.toDbString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: r.status == AttendanceStatus.present
                                        ? const Color(0xFF15803D)
                                        : r.status == AttendanceStatus.late
                                            ? const Color(0xFFD97706)
                                            : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(flex: 3, child: Text((r.note != null && r.note!.isNotEmpty) ? r.note! : '—', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Grades Subview ──────────────────────────────────────────────
  Widget _buildGradesView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Academic Grades & Reports',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Subject scores, term breakdowns, and academic performance.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 16),

          if (_gradeEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('No grade reports submitted by teachers yet.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            ..._gradeEntries.map((g) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: KukieAccent.violetTint,
                        child: Text(
                          g.subject.isNotEmpty ? g.subject[0].toUpperCase() : 'S',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: KukieAccent.violet),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            Text('${g.term} • Score: ${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          g.letterGrade,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: KukieAccent.violet),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ── Homework Subview ────────────────────────────────────────────
  Widget _buildHomeworkView() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Assigned Homework Tasks',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Active homework assignments and AI learning support.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final hw = _homeworkEntries.isNotEmpty
                      ? _homeworkEntries.first
                      : HomeworkEntry(
                          id: 'demo-hw',
                          classId: 'c-1',
                          title: 'General Homework Support',
                          subject: 'General Study',
                          description: 'General study assistant support.',
                          dueDate: DateTime.now().add(const Duration(days: 1)),
                        );
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => HomeworkAiAssistantPage(homework: hw),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KukieAccent.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                label: const Text('AI Help', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_homeworkEntries.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('No active homework tasks assigned.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              ),
            )
          else
            ..._homeworkEntries.map((hw) {
              final dueStr = '${hw.dueDate.year}-${hw.dueDate.month.toString().padLeft(2, '0')}-${hw.dueDate.day.toString().padLeft(2, '0')}';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                        Expanded(
                          child: Text(
                            hw.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hw.subject,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                          ),
                        ),
                      ],
                    ),
                    if (hw.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        hw.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Due Date: $dueStr',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => HomeworkAiAssistantPage(homework: hw),
                            ));
                          },
                          child: Row(
                            children: const [
                              Icon(Icons.auto_awesome, size: 12, color: KukieAccent.violet),
                              SizedBox(width: 4),
                              Text(
                                'Get AI Help',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _statMetricCard({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: labelColor, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: valueColor)),
        ],
      ),
    );
  }
}
