import 'package:flutter/material.dart';
import '../../models/gpa_analytics_models.dart';
import '../../models/user.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/gpa_chart_card.dart';
import '../../widgets/gpa_cumulative_hero_card.dart';
import '../../widgets/semester_breakdown_card.dart';

class AcademicGpaProgressionPage extends StatefulWidget {
  const AcademicGpaProgressionPage({super.key, this.user});

  static const routeName = '/gpa-progression-analytics';

  final User? user;

  @override
  State<AcademicGpaProgressionPage> createState() => _AcademicGpaProgressionPageState();
}

class _AcademicGpaProgressionPageState extends State<AcademicGpaProgressionPage> {
  final CumulativeAcademicSummary _summary = const CumulativeAcademicSummary(
    cumulativeGpa: 3.84,
    maxGpa: 4.00,
    trendText: '+0.12 vs last semester',
    honorsBadgeText: "Dean's List (High Honors)",
    totalCreditsEarned: 96.0,
    majorRankText: '#4 / 120',
    currentSemesterText: 'Semester 6',
    targetGpa: 3.80,
  );

  final List<SemesterGpaPoint> _semesters = const [
    SemesterGpaPoint(
      semesterLabel: 'Sem 1',
      termName: 'Fall 2023',
      gpa: 3.65,
      creditsEarned: 16.0,
      gradeDistribution: "3 A's, 2 B's",
      deltaVsPrevious: 'Base',
    ),
    SemesterGpaPoint(
      semesterLabel: 'Sem 2',
      termName: 'Spring 2024',
      gpa: 3.72,
      creditsEarned: 16.0,
      gradeDistribution: "4 A's, 1 B",
      deltaVsPrevious: '+0.07',
    ),
    SemesterGpaPoint(
      semesterLabel: 'Sem 3',
      termName: 'Fall 2024',
      gpa: 3.80,
      creditsEarned: 16.0,
      gradeDistribution: "4 A's, 1 B+",
      deltaVsPrevious: '+0.08',
    ),
    SemesterGpaPoint(
      semesterLabel: 'Sem 4',
      termName: 'Spring 2025',
      gpa: 3.78,
      creditsEarned: 16.0,
      gradeDistribution: "3 A's, 2 B+",
      deltaVsPrevious: '-0.02',
    ),
    SemesterGpaPoint(
      semesterLabel: 'Sem 5',
      termName: 'Fall 2025',
      gpa: 3.85,
      creditsEarned: 16.0,
      gradeDistribution: "4 A's, 1 A-",
      deltaVsPrevious: '+0.07',
    ),
    SemesterGpaPoint(
      semesterLabel: 'Sem 6',
      termName: 'Spring 2026',
      gpa: 3.92,
      creditsEarned: 16.0,
      gradeDistribution: "5 A's (Straight A)",
      deltaVsPrevious: '+0.07',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userName = widget.user != null
        ? '${widget.user!.firstName} ${widget.user!.lastName}'.trim()
        : 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('GPA Analytics & Progression'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: KukieAccent.violet),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Academic GPA report exported successfully!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Top Welcome Sub-Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $userName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Academic progression & semester performance trend',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Text('🎓', style: TextStyle(fontSize: 22)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Cumulative GPA Hero Card
            GpaCumulativeHeroCard(summary: _summary),
            const SizedBox(height: 16),

            // 2. Modernized Semester Progression Spline Area Chart Card
            GpaChartCard(
              points: _semesters,
              targetGpa: _summary.targetGpa,
            ),
            const SizedBox(height: 20),

            // 3. Semester-by-Semester Breakdown Cards Section
            SemesterBreakdownSection(semesters: _semesters),
          ],
        ),
      ),
    );
  }
}
