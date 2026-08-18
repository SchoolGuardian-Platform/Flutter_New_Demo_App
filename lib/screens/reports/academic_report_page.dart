import 'package:flutter/material.dart';
import '../../models/student_course_registration.dart';
import '../../services/course_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class AcademicReportPage extends StatefulWidget {
  const AcademicReportPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/reports/academic';
  final String studentId;

  @override
  State<AcademicReportPage> createState() => _AcademicReportPageState();
}

class _AcademicReportPageState extends State<AcademicReportPage> {
  final _courseService = CourseService();
  List<StudentCourseRegistration> _registrations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final regs = await _courseService.getStudentRegistrations(
      widget.studentId,
      term: 'Fall 2026',
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
        title: const Text('Academic Progress Report'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // --- GPA Banner ---
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
                            const Text(
                              'Semester Cumulative GPA (Fall 2026)',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Official Report',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87),
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
                        const SizedBox(height: 4),
                        Text(
                          'Student ID: ${widget.studentId} · Alexander Hayes · Total Credits: ${totalCredits.toStringAsFixed(1)} Cr',
                          style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ==========================================
                  // 📊 ALL REGISTERED SUBJECTS PERFORMANCE
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Registered Subjects (${_registrations.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Fall 2026 Semester',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
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
                    ..._registrations.map((reg) => _SubjectProgressCard(registration: reg)),

                  const SizedBox(height: AppSpacing.lg),

                  // ==========================================
                  // 📑 WEIGHTED ASSESSMENT DISTRIBUTION
                  // ==========================================
                  Text(
                    'Overall Assessment Category Averages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: const [
                          _BreakdownRow(
                              label: 'Attendance & Class Participation',
                              weight: '10%',
                              average: '8.4 / 10 (84%)'),
                          Divider(),
                          _BreakdownRow(
                              label: 'Midterm Examination',
                              weight: '30%',
                              average: '25.0 / 30 (83.3%)'),
                          Divider(),
                          _BreakdownRow(
                              label: 'Assignments & Projects',
                              weight: '20%',
                              average: '16.8 / 20 (84%)'),
                          Divider(),
                          _BreakdownRow(
                              label: 'Final Examination',
                              weight: '40%',
                              average: '41.2 / 50 (82.4%)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SubjectProgressCard extends StatelessWidget {
  const _SubjectProgressCard({required this.registration});

  final StudentCourseRegistration registration;

  @override
  Widget build(BuildContext context) {
    final c = registration.course;
    final g = registration.gradeEntry;

    final score = g?.score ?? 0;
    final maxScore = g?.maxScore ?? 100;
    final pct = g?.percentage ?? 0;
    final gradeStr = g?.letterGrade ?? 'Pending';
    final gpaPts = g?.gpaPoints ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: g != null ? KukieAccent.violet : Colors.grey.shade300,
                  radius: 18,
                  child: Text(
                    gradeStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${c.code}: ${c.title}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      Text(
                        'Teacher: ${c.teacherName} · ${c.credits} Credit Hours',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      g != null
                          ? '${score.toStringAsFixed(0)}/${maxScore.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)'
                          : 'Pending',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: KukieAccent.violet,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      g != null ? '${gpaPts.toStringAsFixed(2)} GPA Pts' : 'Unassigned',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                backgroundColor: KukieAccent.violetTint,
                color: KukieAccent.violet,
                minHeight: 6,
              ),
            ),
            if (g != null && g.hasBreakdown) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final comp in g.activeComponents)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${comp.name}: ${comp.score.toStringAsFixed(0)}/${comp.maxScore.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.weight,
    required this.average,
  });

  final String label;
  final String weight;
  final String average;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: KukieAccent.violetTint,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(weight, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: KukieAccent.violet)),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(average, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
