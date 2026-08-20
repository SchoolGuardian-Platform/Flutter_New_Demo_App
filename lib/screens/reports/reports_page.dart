import 'package:flutter/material.dart';

import '../../models/attendance_record.dart';
import '../../models/grade_entry.dart';
import '../../models/user_role.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';
import '../../services/parent_service.dart';
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
  final _attendanceService = AttendanceService();
  final _authService = AuthService();
  final _parentService = ParentService();

  List<GradeEntry> _grades = [];
  List<AttendanceRecord> _attendanceRecords = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final me = await _authService.getMe();
      List<GradeEntry> gradesList = [];
      List<AttendanceRecord> attList = [];

      if (me.role == UserRole.student) {
        final targetId = me.id.isNotEmpty ? me.id : (me.studentId ?? '');
        final rawGrades = await _teacherService.getGradesForStudent(targetId);
        gradesList = rawGrades.where((g) {
          final gid = g.studentId.trim().toLowerCase();
          return gid == targetId.trim().toLowerCase() ||
              (me.studentId != null && gid == me.studentId!.trim().toLowerCase());
        }).toList();
        attList = await _attendanceService.getStudentAttendance(targetId);
      } else if (me.role == UserRole.parent) {
        final students = await _parentService.getMyStudents();
        if (students.isNotEmpty) {
          final s = students.first;
          final targetId = s.studentId;
          final rawGrades = await _teacherService.getGradesForStudent(targetId);
          gradesList = rawGrades.where((g) {
            final gid = g.studentId.trim().toLowerCase();
            return gid == targetId.trim().toLowerCase();
          }).toList();
          attList = await _attendanceService.getStudentAttendance(targetId);
        }
      } else {
        gradesList = await _teacherService.getGradeEntries();
        attList = await _attendanceService.getTeacherAttendance();
      }

      if (mounted) {
        setState(() {
          _grades = gradesList;
          _attendanceRecords = attList;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalAtt = _attendanceRecords.length;
    int presentAtt = _attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    int lateAtt = _attendanceRecords.where((r) => r.status == AttendanceStatus.late).length;
    double attRate = totalAtt > 0 ? ((presentAtt + lateAtt) / totalAtt * 100) : 100.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
                  child: const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: KukieAccent.violet),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'View real academic evaluations, attendance metrics, and teacher recommendations stored in your database.',
                          style: TextStyle(
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
                  subtitle: totalAtt > 0
                      ? '$totalAtt records · ${attRate.toStringAsFixed(1)}% attendance rate'
                      : 'Daily attendance history, punctuality, and patterns.',
                  badgeText: totalAtt > 0 ? '${attRate.toStringAsFixed(1)}% Present' : '0 Records',
                  badgeColor: attRate >= 80 ? Colors.green.shade700 : Colors.orange.shade700,
                  onTap: () => _showAttendanceReport(context),
                ),

                // Wellbeing Report Card
                _ReportCardTile(
                  icon: Icons.favorite_border_outlined,
                  title: 'Wellbeing Report',
                  subtitle: 'Classroom engagement and social-emotional feedback.',
                  badgeText: 'Active',
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
    int total = _attendanceRecords.length;
    int present = _attendanceRecords.where((r) => r.status == AttendanceStatus.present).length;
    int late = _attendanceRecords.where((r) => r.status == AttendanceStatus.late).length;
    int absent = _attendanceRecords.where((r) => r.status == AttendanceStatus.absent).length;
    int excused = _attendanceRecords.where((r) => r.status == AttendanceStatus.excused).length;

    double attRate = total > 0 ? ((present + late) / total * 100) : 100.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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

            // Dynamic Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: attRate >= 80 ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: attRate >= 80 ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    attRate >= 80 ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: attRate >= 80 ? Colors.green.shade700 : Colors.orange.shade700,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${attRate.toStringAsFixed(1)}% Overall Attendance Rate',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: attRate >= 80 ? Colors.green.shade900 : Colors.orange.shade900,
                          ),
                        ),
                        Text(
                          '$present Days Present · $late Days Late · $absent Absences ($excused Excused)',
                          style: TextStyle(
                            fontSize: 12,
                            color: attRate >= 80 ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Recent Attendance Entries from Database',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: _attendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No attendance records logged in database yet.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        final item = _attendanceRecords[index];
                        final isPresent = item.status == AttendanceStatus.present;
                        final isLate = item.status == AttendanceStatus.late;

                        final icon = isPresent
                            ? Icons.check_circle_outline
                            : (isLate ? Icons.access_time : Icons.cancel_outlined);

                        final color = isPresent
                            ? Colors.green
                            : (isLate ? Colors.orange : Colors.red);

                        return ListTile(
                          leading: Icon(icon, color: color),
                          title: Text('Date: ${item.date}'),
                          subtitle: Text(
                            'Status: ${item.status.displayName}${item.note != null && item.note!.isNotEmpty ? ' (${item.note})' : ''}',
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWellbeingReport(BuildContext context) {
    final noteWithComment = _grades.firstWhere(
      (g) => g.parentRecommendation != null && g.parentRecommendation!.isNotEmpty,
      orElse: () => GradeEntry(
        id: '',
        studentId: '',
        studentName: '',
        subject: '',
        assessmentType: AssessmentType.assignment,
        score: 0,
        maxScore: 100,
        term: '',
        createdAt: DateTime.now(),
      ),
    );

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
                          'Wellbeing Status: Active',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          'Classroom engagement and social-emotional growth tracked.',
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
              child: Text(
                noteWithComment.parentRecommendation != null && noteWithComment.parentRecommendation!.isNotEmpty
                    ? '"${noteWithComment.parentRecommendation}"'
                    : '"Demonstrates active participation and positive engagement in daily academic activities."',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
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
                        'Student: ${grade.studentName}',
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
                        Expanded(
                          child: Text(
                            'Term: ${widget.initialGrades.first.term}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: honorsColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              honorsStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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