import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/student_link.dart';
import '../../services/attendance_service.dart';
import '../../services/parent_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'link_student_page.dart';

/// Parent's "Linked Students" tab -- the verified students connected to
/// this parent's account. Backed by `GET /parents/my-students`
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
      setState(() => _error = 'Something went wrong loading your students.');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Linked Students')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLinkStudent,
        icon: const Icon(Icons.add),
        label: const Text('Link a Student'),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (students == null || students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(
              height: 320,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No linked students yet. Tap "Link a Student" below to '
                    'send a request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.outline),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl2),
        itemCount: students.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _StudentLinkCard(link: students[index]),
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

  Future<void> _toggleExpand() async {
    final newExpanded = !_expanded;
    setState(() => _expanded = newExpanded);

    if (newExpanded && _attendance.isEmpty && _grades.isEmpty) {
      setState(() => _loadingDetails = true);
      try {
        final attList = await AttendanceService().getStudentAttendance(widget.link.studentId);
        final gradeList = await TeacherService().getGradesForStudent(widget.link.studentId);
        if (mounted) {
          setState(() {
            _attendance = attList;
            _grades = gradeList;
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpand,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: KukieAccent.violetTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_outlined, color: KukieAccent.violet, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(link.fullName,
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                  color: AppColors.secondary.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              link.relationshipType.name,
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(link.email, style: Theme.of(context).textTheme.bodySmall),
                      if (link.status != null && link.status != AccountStatus.active)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Student account status: ${link.status!.name}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.warning),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const Divider(height: 20),
            if (_loadingDetails)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              // Attendance Section for Parent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('${_attendance.length} total records', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _chip('Present', presentCount, KukieAccent.success),
                  _chip('Absent', absentCount, Colors.red),
                  _chip('Late', lateCount, Colors.orange),
                ],
              ),
              const SizedBox(height: 12),

              // Grades Section for Parent
              const Row(
                children: [
                  Icon(Icons.assessment_outlined, size: 16, color: KukieAccent.violet),
                  SizedBox(width: 6),
                  Text('Academic Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              if (_grades.isEmpty)
                const Text('No grades posted yet.', style: TextStyle(fontSize: 12, color: Colors.grey))
              else
                ..._grades.map((g) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('${g.assessmentType.label} (${g.term})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Text('${g.score.toStringAsFixed(1)} / ${g.maxScore.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: KukieAccent.violet, fontSize: 13)),
                        ],
                      ),
                    )),
            ],
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, int val, Color c) {
    return Column(
      children: [
        Text('$val', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: c)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
