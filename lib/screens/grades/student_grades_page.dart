import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class StudentGradesPage extends StatefulWidget {
  const StudentGradesPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/student/grades';
  final String studentId;

  @override
  State<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends State<StudentGradesPage> {
  final _teacherService = TeacherService();
  List<GradeEntry> _grades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _loading = true);
    final grades = await _teacherService.getGradesForStudent(widget.studentId);
    if (!mounted) return;
    setState(() {
      _grades = grades;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Grades & Assessments'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGrades,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: KukieAccent.violetTint,
                      borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                      border: Border.all(color: KukieAccent.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school, size: 28, color: KukieAccent.violet),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student Portal · ID: ${widget.studentId}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: KukieAccent.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Track your coursework, exam scores, and academic progress.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: KukieAccent.bodyGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Course Work & Grades',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_grades.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text('No grades posted yet.'),
                        ),
                      ),
                    )
                  else
                    ..._grades.map((grade) => _StudentGradeItem(grade: grade)),
                ],
              ),
            ),
    );
  }
}

class _StudentGradeItem extends StatelessWidget {
  const _StudentGradeItem({required this.grade});

  final GradeEntry grade;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: KukieAccent.violetTint,
                  child: Text(
                    grade.letterGrade,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: KukieAccent.violet,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grade.subject,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${grade.assessmentType.label} · ${grade.term}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${grade.score.toStringAsFixed(1)} / ${grade.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: KukieAccent.violet,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (grade.hasBreakdown) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final c in grade.activeComponents)
                    _ComponentBadge(
                        label:
                            '${c.name}: ${c.score.toStringAsFixed(0)}/${c.maxScore.toStringAsFixed(0)}'),
                ],
              ),
            ],
            // PRIVACY ENFORCEMENT: Confidential parent recommendations are
            // intentionally OMITTED here for Student view.
          ],
        ),
      ),
    );
  }
}

class _ComponentBadge extends StatelessWidget {
  const _ComponentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: KukieAccent.violetTint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: KukieAccent.violet.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: KukieAccent.violet,
        ),
      ),
    );
  }
}
