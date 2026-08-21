import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/homework_entry.dart';
import '../../models/relationship.dart';
import '../../models/student_link.dart';
import '../../services/attendance_service.dart';
import '../../services/homework_service.dart';
import '../../services/parent_service.dart';
import '../../services/teacher_note_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';
import 'link_student_page.dart';

/// Parent's "My Child" page -- verified students connected to
/// this parent's account. Backed by `GET /parents/my-students`.
class MyStudentsPage extends StatefulWidget {
  const MyStudentsPage({super.key});

  static const routeName = '/parent/my-students';

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  final _parentService = ParentService();
  List<StudentLink>? _students;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _parentService.getMyStudents();
      if (!mounted) return;
      setState(() => _students = students);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong loading your connected students.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLinkStudent() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LinkStudentPage()),
    );
    if (linked == true) _load();
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
            Icon(Icons.family_restroom_rounded, color: KukieAccent.violet, size: 24),
            SizedBox(width: 10),
            Text(
              'My Child Portal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Refresh Students',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLinkStudent,
        icon: const Icon(Icons.add_link_rounded, size: 20),
        label: const Text('Link a Student', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: KukieAccent.violet,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  Widget _buildBody() {
    final students = _students;

    if (_loading && students == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && students == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF475569))),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          // ── Hero Banner Card ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KukieAccent.violet, KukieAccent.violetDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: KukieAccent.violet.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'GUARDIAN PORTAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (students != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${students.length} Student${students.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: KukieAccent.violet,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Connected Students',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Monitor real-time academic evaluations, daily attendance metrics, homework assignments, and teacher feedback notes.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (students == null || students.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: KukieAccent.violetTint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 36, color: KukieAccent.violet),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Linked Students Yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Link your student account using their Student ID (e.g. SG-2026-000001) or registered email to view their progress.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _openLinkStudent,
                    style: FilledButton.styleFrom(
                      backgroundColor: KukieAccent.violet,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_link_rounded, size: 18),
                    label: const Text('Link Student Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _StudentLinkCard(link: students[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudentLinkCard extends StatefulWidget {
  const _StudentLinkCard({required this.link});

  final StudentLink link;

  @override
  State<_StudentLinkCard> createState() => _StudentLinkCardState();
}

class _StudentLinkCardState extends State<_StudentLinkCard> {
  bool _expanded = false;
  bool _loadingDetails = false;
  List<AttendanceRecord> _attendance = [];
  List<GradeEntry> _grades = [];
  List<HomeworkEntry> _homework = [];
  List<TeacherNoteItem> _teacherNotes = [];

  Future<void> _toggleExpand() async {
    final newExpanded = !_expanded;
    setState(() => _expanded = newExpanded);

    if (newExpanded && _attendance.isEmpty && _grades.isEmpty && _homework.isEmpty) {
      setState(() => _loadingDetails = true);
      try {
        final attList = await AttendanceService().getStudentAttendance(widget.link.studentId);
        final gradeList = await TeacherService().getGradesForStudent(widget.link.studentId);
        final hwList = await HomeworkService().getStudentHomeworks(widget.link.studentId);
        final noteList = await TeacherNoteService().getStudentNotes(widget.link.studentId);
        if (mounted) {
          setState(() {
            _attendance = attList;
            _grades = gradeList;
            _homework = hwList;
            _teacherNotes = noteList;
            _loadingDetails = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final link = widget.link;
    int presentCount = _attendance.where((r) => r.status == AttendanceStatus.present).length;
    int absentCount = _attendance.where((r) => r.status == AttendanceStatus.absent).length;
    int lateCount = _attendance.where((r) => r.status == AttendanceStatus.late).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: KukieAccent.violetTint,
                      shape: BoxShape.circle,
                      border: Border.all(color: KukieAccent.violet.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        link.fullName.isNotEmpty ? link.fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: KukieAccent.violet,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                link.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: KukieAccent.violetTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                link.relationshipType.label.toUpperCase(),
                                style: const TextStyle(
                                  color: KukieAccent.violet,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          link.email,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        if (link.status != null && link.status != AccountStatus.active)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Account Status: ${link.status!.name}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF64748B),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _loadingDetails
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Attendance Metrics ──
                        const Text(
                          'Attendance Overview',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _statusCard('Present', '$presentCount', const Color(0xFFDCFCE7), const Color(0xFF15803D))),
                            const SizedBox(width: 8),
                            Expanded(child: _statusCard('Absent', '$absentCount', const Color(0xFFFEF2F2), const Color(0xFFDC2626))),
                            const SizedBox(width: 8),
                            Expanded(child: _statusCard('Late', '$lateCount', const Color(0xFFFFFBEB), const Color(0xFFD97706))),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // ── Academic Performance ──
                        Row(
                          children: const [
                            Icon(Icons.assessment_rounded, size: 18, color: KukieAccent.violet),
                            SizedBox(width: 8),
                            Text(
                              'Academic Performance',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_grades.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('No grade records posted yet.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          )
                        else
                          ..._grades.map((g) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: KukieAccent.violetTint,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          g.letterGrade,
                                          style: const TextStyle(fontWeight: FontWeight.w900, color: KukieAccent.violet, fontSize: 13),
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
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                          ),
                                          Text(
                                            '${g.assessmentType.label} • ${g.term}',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w900, color: KukieAccent.violet, fontSize: 13),
                                    ),
                                  ],
                                ),
                              )),
                        const SizedBox(height: 18),

                        // ── Pending Homework ──
                        Row(
                          children: const [
                            Icon(Icons.assignment_rounded, size: 18, color: KukieAccent.violet),
                            SizedBox(width: 8),
                            Text(
                              'Homework Assignments',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_homework.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('No pending homework assignments.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          )
                        else
                          ..._homework.map((hw) {
                            final dueFormatted = DateFormat('MMM d').format(hw.dueDate);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hw.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          '${hw.subject} • Due $dueFormatted',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: KukieAccent.violetTint,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hw.subject,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const SizedBox(height: 18),

                        // ── Teacher Notes & Feedback ──
                        Row(
                          children: const [
                            Icon(Icons.rate_review_rounded, size: 18, color: KukieAccent.violet),
                            SizedBox(width: 8),
                            Text(
                              'Teacher Notes & Feedback',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_teacherNotes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Text('No teacher observation notes recorded.', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          )
                        else
                          ..._teacherNotes.map((note) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        note.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      ),
                                      if (note.teacherName != null)
                                        Text(
                                          'By ${note.teacherName}',
                                          style: const TextStyle(fontSize: 11, color: KukieAccent.violet, fontWeight: FontWeight.bold),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    note.content,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(String label, String value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textCol)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }
}
