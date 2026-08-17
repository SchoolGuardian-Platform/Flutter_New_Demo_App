import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class AcademicReportPage extends StatelessWidget {
  const AcademicReportPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/reports/academic';
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Progress Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KukieAccent.violet, KukieAccent.violet.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cumulative GPA',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Top 5% of Class',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '3.84 / 4.0',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: $studentId · Alexander Hayes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Subject Performance Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SubjectBar(subject: 'Advanced Mathematics', score: 91, grade: 'A'),
          const _SubjectBar(subject: 'Computer Science 101', score: 88, grade: 'B+'),
          const _SubjectBar(subject: 'Physics & Lab', score: 94, grade: 'A'),
          const _SubjectBar(subject: 'English Literature', score: 85, grade: 'B'),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Assessment Distribution',
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
                  _BreakdownRow(label: 'Attendance & Participation', weight: '10%', average: '8.5 / 10'),
                  Divider(),
                  _BreakdownRow(label: 'Midterm Examination', weight: '30%', average: '26.4 / 30'),
                  Divider(),
                  _BreakdownRow(label: 'Assignments & Quizzes', weight: '10%', average: '9.2 / 10'),
                  Divider(),
                  _BreakdownRow(label: 'Final Examination', weight: '50%', average: '46.0 / 50'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectBar extends StatelessWidget {
  const _SubjectBar({required this.subject, required this.score, required this.grade});

  final String subject;
  final double score;
  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              Text(subject,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text('$grade (${score.toStringAsFixed(0)}%)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: KukieAccent.violet)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor: KukieAccent.violetTint,
              color: KukieAccent.violet,
            ),
          ),
        ],
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Text(weight, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(width: 16),
          Text(average,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: KukieAccent.ink)),
        ],
      ),
    );
  }
}
