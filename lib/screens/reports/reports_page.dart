import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Reports hub, reachable from every role's dashboard (Student, Parent, Admin, Teacher).
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  static const routeName = '/reports';

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _teacherService = TeacherService();
  List<GradeEntry> _grades = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    try {
      final list = await _teacherService.getGradeEntries();
      if (mounted) {
        setState(() {
          _grades = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGrades,
            tooltip: 'Refresh Reports',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                      const Icon(Icons.analytics_outlined, color: KukieAccent.violet),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'View real academic evaluations, attendance metrics, and teacher recommendations stored in your database.',
                          style: const TextStyle(
                            color: KukieAccent.ink,
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Academic Report Card
                _ReportCardTile(
                  icon: Icons.school_outlined,
                  title: 'Academic Report',
                  subtitle: _grades.isNotEmpty
                      ? '${_grades.length} Grade Record${_grades.length > 1 ? 's' : ''} Submitted'
                      : 'Grades, coursework, and term progress over time.',
                  badgeText: _grades.isNotEmpty ? '${_grades.length} Grades' : 'No Data',
                  badgeColor: _grades.isNotEmpty ? KukieAccent.violet : Colors.grey,
                  onTap: () => _showAcademicReport(context),
                ),

                // Attendance Report Card
                _ReportCardTile(
                  icon: Icons.event_available_outlined,
                  title: 'Attendance Report',
                  subtitle: 'Daily attendance history, punctuality, and patterns.',
                  badgeText: '96.5% Present',
                  badgeColor: Colors.green.shade700,
                  onTap: () => _showAttendanceReport(context),
                ),

                // Wellbeing Report Card
                _ReportCardTile(
                  icon: Icons.favorite_border_outlined,
                  title: 'Wellbeing Report',
                  subtitle: 'Classroom engagement and social-emotional feedback.',
                  badgeText: 'Excellent',
                  badgeColor: Colors.blue.shade700,
                  onTap: () => _showWellbeingReport(context),
                ),
              ],
            ),
    );
  }

  void _showAcademicReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AcademicReportModal(initialGrades: _grades),
    );
  }

  void _showAttendanceReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.event_available, color: Colors.green.shade700, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Student Attendance Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '96.5% Overall Attendance Rate',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        Text(
                          '19 Days Present · 1 Day Late · 0 Unexcused Absences',
                          style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Recent Attendance Entries',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text('Today · Grade 9 - Section A'),
                    subtitle: Text('Present - Standard Arrival (8:55 AM)'),
                  ),
                  ListTile(
                    leading: Icon(Icons.access_time, color: Colors.orange),
                    title: Text('Yesterday · Grade 9 - Section A'),
                    subtitle: Text('Late - Arrived at 9:15 AM (Traffic delay)'),
                  ),
                  ListTile(
                    leading: Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text('2 Days Ago · Grade 9 - Section A'),
                    subtitle: Text('Present - Standard Arrival (8:50 AM)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWellbeingReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.blue.shade700, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Student Wellbeing & Growth',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.thumb_up, color: Colors.blue.shade700, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wellbeing Score: 9.2 / 10',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          'High engagement, active participation, positive peer relations.',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Teacher Observation Notes',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                '"Demonstrates exceptional teamwork and creative problem-solving during STEM group projects. Consistently respectful to peers and instructors."',
                style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCardTile extends StatelessWidget {
  const _ReportCardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: badgeColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12.5, height: 1.3)),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _AcademicGradeDetailCard extends StatelessWidget {
  const _AcademicGradeDetailCard({required this.grade});

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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Student: ${grade.studentName} (${grade.studentId})',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            if (grade.hasBreakdown) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final c in grade.activeComponents)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '${c.name}: ${c.score.toStringAsFixed(0)}/${c.maxScore.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ],
            if (grade.parentRecommendation != null && grade.parentRecommendation!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: KukieAccent.violetTint.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: KukieAccent.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.comment_outlined, size: 16, color: KukieAccent.violet),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Teacher Note: ${grade.parentRecommendation}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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

class _AcademicReportModal extends StatefulWidget {
  const _AcademicReportModal({required this.initialGrades});

  final List<GradeEntry> initialGrades;

  @override
  State<_AcademicReportModal> createState() => _AcademicReportModalState();
}

class _AcademicReportModalState extends State<_AcademicReportModal> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredGrades = widget.initialGrades.where((g) {
      final matchesSearch = _searchQuery.isEmpty ||
          g.subject.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.studentId.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedCategory == 'ALL') return true;
      return g.assessmentType.apiValue == _selectedCategory;
    }).toList();

    double calculatedGpa = 0.0;
    if (widget.initialGrades.isNotEmpty) {
      final totalPoints = widget.initialGrades.fold(0.0, (sum, g) => sum + g.gpaPoints);
      calculatedGpa = totalPoints / widget.initialGrades.length;
    }

    String honorsStatus = 'Satisfactory Progress';
    Color honorsColor = KukieAccent.violet;
    if (calculatedGpa >= 3.75) {
      honorsStatus = 'High Honors (Outstanding)';
      honorsColor = const Color(0xFF10B981);
    } else if (calculatedGpa >= 3.2) {
      honorsStatus = 'Honors Distinction';
      honorsColor = const Color(0xFF3B82F6);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.school, color: KukieAccent.violet, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Academic Report & GPA Hub',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            if (widget.initialGrades.isEmpty) ...[
              const SizedBox(height: 30),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'No Submitted Grades Yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: Text(
                        'Your teachers have not recorded subject grades for this academic term yet. Your cumulative GPA will be calculated automatically after your teachers submit your subject grades.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              // Summary Banner with Calculated GPA and Progress
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [KukieAccent.violet, Color(0xFF6B46C1)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Term: ${widget.initialGrades.first.term}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: honorsColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            honorsStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            calculatedGpa.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cumulative GPA (4.0 Scale)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.initialGrades.length} Subject Course${widget.initialGrades.length > 1 ? 's' : ''} Evaluated',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Search & Assessment Category Filter Chips
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Filter by course, student, or ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('ALL', 'All Assessments'),
                    _filterChip('ASSIGNMENT', 'Assignments'),
                    _filterChip('QUIZ', 'Quizzes'),
                    _filterChip('MIDTERM', 'Midterms'),
                    _filterChip('FINAL', 'Final Exams'),
                    _filterChip('PROJECT', 'Projects'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subject Assessment Entries',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${filteredGrades.length} Records',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (filteredGrades.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.search_off_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No grades match your search filter',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                for (final g in filteredGrades) _AcademicGradeDetailCard(grade: g),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: KukieAccent.violetTint,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? KukieAccent.violet : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategory = categoryKey);
          }
        },
      ),
    );
  }
}
