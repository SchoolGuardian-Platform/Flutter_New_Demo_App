import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class ParentGradesPage extends StatefulWidget {
  const ParentGradesPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/parent/grades';
  final String studentId;

  @override
  State<ParentGradesPage> createState() => _ParentGradesPageState();
}

class _ParentGradesPageState extends State<ParentGradesPage> {
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
        title: const Text('Child Performance & Guidance'),
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
                        const Icon(Icons.family_restroom,
                            size: 28, color: KukieAccent.violet),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Student: Alexander Hayes (${widget.studentId})',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: KukieAccent.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Includes confidential teacher recommendations for parent guidance.',
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
                    'Academic Assessments & Teacher Notes',
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
                          child: Text('No grades posted yet for this student.'),
                        ),
                      ),
                    )
                  else
                    ..._grades.map((grade) => _ParentGradeItem(grade: grade)),
                ],
              ),
            ),
    );
  }
}

class _ParentGradeItem extends StatelessWidget {
  const _ParentGradeItem({required this.grade});

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
            if (grade.parentRecommendation != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_person,
                            size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Text(
                          'Confidential Teacher Recommendation for Parents',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      grade.parentRecommendation!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
