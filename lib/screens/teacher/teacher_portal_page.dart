import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/teacher_profile.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'add_grade_page.dart';

class TeacherPortalPage extends StatefulWidget {
  const TeacherPortalPage({super.key});

  static const routeName = '/teacher/portal';

  @override
  State<TeacherPortalPage> createState() => _TeacherPortalPageState();
}

class _TeacherPortalPageState extends State<TeacherPortalPage> {
  final _teacherService = TeacherService();
  TeacherProfile? _profile;
  List<GradeEntry> _grades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final profile = await _teacherService.getTeacherProfile();
    final grades = await _teacherService.getGradeEntries();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _grades = grades;
      _loading = false;
    });
  }

  Future<void> _openAddGrade() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddGradePage()),
    );
    if (added == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional Teacher Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddGrade,
        icon: const Icon(Icons.add),
        label: const Text('Add Grade & Guidance'),
        backgroundColor: KukieAccent.violet,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _TeacherHeaderCard(profile: _profile!),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsRow(gradesCount: _grades.length),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Student Grades & Guidance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      TextButton.icon(
                        onPressed: _openAddGrade,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Entry'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_grades.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text('No student grades recorded yet.'),
                        ),
                      ),
                    )
                  else
                    ..._grades.map((g) => _TeacherGradeCard(grade: g)),
                ],
              ),
            ),
    );
  }
}

class _TeacherHeaderCard extends StatelessWidget {
  const _TeacherHeaderCard({required this.profile});

  final TeacherProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.psychology, size: 30, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'ID: ${profile.employeeId} · ${profile.department}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              const Icon(Icons.school, size: 18, color: Colors.amberAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Major Field: ${profile.majorField}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: profile.assignedClasses
                .map((cls) => Chip(
                      label: Text(
                        cls,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.gradesCount});

  final int gradesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'Submitted',
            value: '$gradesCount',
            subtitle: 'Grades recorded',
            icon: Icons.assignment_turned_in,
            color: Colors.blue.shade700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatBox(
            title: 'Classes',
            value: '3',
            subtitle: 'Active rosters',
            icon: Icons.class_outlined,
            color: Colors.purple.shade700,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatBox(
            title: 'Parent Notes',
            value: '$gradesCount',
            subtitle: 'Confidential',
            icon: Icons.lock,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
        border: Border.all(color: KukieAccent.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: KukieAccent.ink)),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: KukieAccent.bodyGray)),
        ],
      ),
    );
  }
}

class _TeacherGradeCard extends StatelessWidget {
  const _TeacherGradeCard({required this.grade});

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
                        grade.studentName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'ID: ${grade.studentId} · ${grade.subject}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${grade.score.toStringAsFixed(1)} / ${grade.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: KukieAccent.violet,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Chip(
                  label: Text(grade.assessmentType.label,
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  grade.term,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            if (grade.hasBreakdown) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (grade.attendanceScore != null)
                    _ComponentBadge(label: 'Att: ${grade.attendanceScore!.toStringAsFixed(0)}/10'),
                  if (grade.midtermScore != null)
                    _ComponentBadge(label: 'Mid: ${grade.midtermScore!.toStringAsFixed(0)}/30'),
                  if (grade.assignmentScore != null)
                    _ComponentBadge(label: 'Assig: ${grade.assignmentScore!.toStringAsFixed(0)}/10'),
                  if (grade.finalScore != null)
                    _ComponentBadge(label: 'Final: ${grade.finalScore!.toStringAsFixed(0)}/50'),
                ],
              ),
            ],
            if (grade.parentRecommendation != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: Colors.amber.shade900),
                        const SizedBox(width: 4),
                        Text(
                          'Private Parent Recommendation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      grade.parentRecommendation!,
                      style: TextStyle(fontSize: 12.5, color: Colors.amber.shade900),
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
