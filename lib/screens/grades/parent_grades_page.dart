import 'package:flutter/material.dart';
import '../../models/student_course_registration.dart';
import '../../services/course_service.dart';
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
  final _courseService = CourseService();
  List<StudentCourseRegistration> _registrations = [];
  bool _loading = true;
  String _selectedTerm = 'Fall 2026';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final regs = await _courseService.getStudentRegistrations(
      widget.studentId,
      term: _selectedTerm,
    );
    if (!mounted) return;
    setState(() {
      _registrations = regs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gpa = _courseService.calculateGPA(_registrations);
    final totalCredits = _courseService.calculateTotalCredits(_registrations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Semester Performance & Guidance'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _selectedTerm,
                        items: const [
                          DropdownMenuItem(value: 'Fall 2026', child: Text('Fall 2026 Semester')),
                          DropdownMenuItem(value: 'Spring 2027', child: Text('Spring 2027 Semester')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedTerm = val);
                            _loadData();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // --- Automated GPA Summary Banner ---
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [KukieAccent.violet, KukieAccent.violet.withValues(alpha: 0.85)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Child\'s Semester GPA',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              gpa.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              ' / 4.0 GPA',
                              style: TextStyle(fontSize: 16, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Alexander Hayes (${widget.studentId}) · Total Credits: ${totalCredits.toStringAsFixed(1)} Cr',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Multi-Teacher Academic Matrix & Parent Notes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_registrations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text('No courses registered for this semester.'),
                        ),
                      ),
                    )
                  else
                    ..._registrations.map((reg) => _ParentCourseCard(registration: reg)),
                ],
              ),
            ),
    );
  }
}

class _ParentCourseCard extends StatelessWidget {
  const _ParentCourseCard({required this.registration});

  final StudentCourseRegistration registration;

  @override
  Widget build(BuildContext context) {
    final course = registration.course;
    final grade = registration.gradeEntry;

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
                  backgroundColor: grade != null ? KukieAccent.violetTint : Colors.grey.shade200,
                  child: Text(
                    grade != null ? grade.letterGrade : 'Pending',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: grade != null ? KukieAccent.violet : Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course.code}: ${course.title}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Assigned Teacher: ${course.teacherName}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                      ),
                      Text(
                        '${course.credits} Credit Hours (GPA Weighted)',
                        style: const TextStyle(fontSize: 12, color: KukieAccent.violet, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (grade != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KukieAccent.violetTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${grade.score.toStringAsFixed(0)} / ${grade.maxScore.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: KukieAccent.violet,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${grade.gpaPoints.toStringAsFixed(1)} GPA Pts',
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (grade != null && grade.hasBreakdown) ...[
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
            if (grade != null && grade.parentRecommendation != null) ...[
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
                        Expanded(
                          child: Text(
                            'Confidential Teacher Recommendation (${course.teacherName})',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.amber.shade900,
                            ),
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
