import 'package:flutter/material.dart';
import '../../models/student_course_registration.dart';
import '../../services/course_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../student/course_registration_page.dart';

class StudentGradesPage extends StatefulWidget {
  const StudentGradesPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/student/grades';
  final String studentId;

  @override
  State<StudentGradesPage> createState() => _StudentGradesPageState();
}

class _StudentGradesPageState extends State<StudentGradesPage> {
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

  void _showGradingScaleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Official Grading Scale & GPA Points'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScaleRow(grade: 'A+', range: '90% - 100%', points: '4.0'),
            _ScaleRow(grade: 'A', range: '85% - 89%', points: '4.0'),
            _ScaleRow(grade: 'A-', range: '80% - 84%', points: '3.75'),
            _ScaleRow(grade: 'B+', range: '75% - 79%', points: '3.5'),
            _ScaleRow(grade: 'B', range: '70% - 74%', points: '3.0'),
            _ScaleRow(grade: 'B-', range: '65% - 69%', points: '2.75'),
            _ScaleRow(grade: 'C+', range: '60% - 64%', points: '2.5'),
            _ScaleRow(grade: 'C', range: '50% - 59%', points: '2.0'),
            _ScaleRow(grade: 'C-', range: '45% - 49%', points: '1.75'),
            _ScaleRow(grade: 'D', range: '40% - 44%', points: '1.0'),
            _ScaleRow(grade: 'F (Fail)', range: '< 40%', points: '0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gpa = _courseService.calculateGPA(_registrations);
    final totalCredits = _courseService.calculateTotalCredits(_registrations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Semester Courses & GPA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGradingScaleDialog,
            tooltip: 'View Grading Scale',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // Term Selector & Action Row
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
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).pushNamed(CourseRegistrationPage.routeName);
                          _loadData();
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Register Courses'),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Semester GPA ($_selectedTerm)',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            InkWell(
                              onTap: _showGradingScaleDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Grading Scale Info',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
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
                          'Student ID: ${widget.studentId} · Total Credits: ${totalCredits.toStringAsFixed(1)} Cr · ${_registrations.length} Enrolled Courses',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Multi-Teacher Course Grade Matrix',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_registrations.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          children: [
                            const Text('No courses registered for this semester.'),
                            const SizedBox(height: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.of(context).pushNamed(CourseRegistrationPage.routeName);
                                _loadData();
                              },
                              icon: const Icon(Icons.how_to_reg),
                              label: const Text('Register Courses Now'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._registrations.map((reg) => _StudentCourseCard(registration: reg)),
                ],
              ),
            ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.grade,
    required this.range,
    required this.points,
  });

  final String grade;
  final String range;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(grade, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(range, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text('$points Points',
              style: const TextStyle(fontWeight: FontWeight.w700, color: KukieAccent.violet)),
        ],
      ),
    );
  }
}

class _StudentCourseCard extends StatelessWidget {
  const _StudentCourseCard({required this.registration});

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
                        'Teacher: ${course.teacherName} · ${course.credits} Credits',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
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
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Pending Grade',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
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
