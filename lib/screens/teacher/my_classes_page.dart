import 'package:flutter/material.dart';
import '../../models/school_class.dart';
import '../../models/teacher_profile.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';
import 'add_grade_page.dart';
import 'mark_attendance_page.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({
    super.key,
    this.initialClassId,
    this.isEmbedded = false,
  });

  static const routeName = '/teacher/classes';
  final String? initialClassId;
  final bool isEmbedded;

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  final _teacherService = TeacherService();
  final _schoolService = SchoolManagementService();

  bool _loading = true;
  String? _errorMessage;
  TeacherProfile? _teacherProfile;
  List<SchoolClass> _assignedClasses = [];
  int _selectedClassIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();

      final filtered = allClasses.where((sc) {
        final isTeacherInClassList = sc.teachers.any((t) =>
            (t.teacherId.isNotEmpty && t.teacherId == profile.id) ||
            (t.teacherName.isNotEmpty && t.teacherName.toLowerCase() == profile.fullName.toLowerCase()));
        final isClassInProfileList = profile.assignedClasses.any((ac) {
          final cleanAc = ac.trim().toLowerCase();
          return cleanAc == sc.displayName.trim().toLowerCase() ||
                 cleanAc == sc.id.trim().toLowerCase() ||
                 cleanAc == sc.shortLabel.trim().toLowerCase();
        });
        return isTeacherInClassList || isClassInProfileList;
      }).toList();

      final classesToUse = filtered.isNotEmpty ? filtered : allClasses;
      int selectedIdx = 0;
      if (widget.initialClassId != null && widget.initialClassId!.isNotEmpty) {
        final matchIdx = classesToUse.indexWhere((c) => c.id == widget.initialClassId);
        if (matchIdx != -1) {
          selectedIdx = matchIdx;
        }
      }

      if (mounted) {
        setState(() {
          _teacherProfile = profile;
          _assignedClasses = classesToUse;
          _selectedClassIndex = selectedIdx;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _getClassSubjectLabel(SchoolClass sc) {
    if (sc.teachers.isNotEmpty) {
      final matched = <String>[];
      if (_teacherProfile != null) {
        for (final t in sc.teachers) {
          final isMe = (t.teacherId.isNotEmpty && t.teacherId == _teacherProfile!.id) ||
              (t.teacherName.isNotEmpty && t.teacherName.toLowerCase() == _teacherProfile!.fullName.toLowerCase());
          if (isMe && t.subjectName.trim().isNotEmpty) {
            matched.add(t.subjectName.trim());
          }
        }
      }
      if (matched.isEmpty) {
        for (final t in sc.teachers) {
          if (t.subjectName.trim().isNotEmpty) {
            matched.add(t.subjectName.trim());
          }
        }
      }
      if (matched.isNotEmpty) {
        return matched.toSet().join(', ');
      }
    }
    if (_teacherProfile != null && _teacherProfile!.assignedSubjects.isNotEmpty) {
      return _teacherProfile!.assignedSubjects.first;
    }
    return 'Maths';
  }

  Future<void> _recordStudentGrade(String studentId, String studentName) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddGradePage(
          initialStudentId: studentId,
          initialStudentName: studentName,
        ),
      ),
    );

    if (updated == true && mounted) {
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Class Rosters & Student 360°',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                  onPressed: _loadClasses,
                  tooltip: 'Refresh Classes',
                ),
              ],
            ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _assignedClasses.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadClasses,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Header Title & Description
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Class Rosters & Student 360°',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'View student cohorts, performance transcripts, behavioral notes, and linked parent contact details.',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF64748B),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.isEmbedded)
                              IconButton(
                                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
                                onPressed: _loadClasses,
                                tooltip: 'Refresh Classes',
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section Label
                        const Text(
                          'ASSIGNED SECTIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Assigned Sections Horizontal Selector Bar
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(_assignedClasses.length, (index) {
                              final cls = _assignedClasses[index];
                              final safeIndex = (_selectedClassIndex >= 0 && _selectedClassIndex < _assignedClasses.length)
                                  ? _selectedClassIndex
                                  : 0;
                              final isSelected = index == safeIndex;
                              final subjectName = _getClassSubjectLabel(cls);
                              final gradeLabel = cls.displayName.isNotEmpty
                                  ? cls.displayName
                                  : 'Grade ${cls.grade}-${cls.section}';
                              final academicYearStr = cls.academicYear.isNotEmpty ? cls.academicYear : '2025-2026';

                              return Container(
                                width: 240,
                                margin: const EdgeInsets.only(right: 12),
                                child: InkWell(
                                  onTap: () => setState(() => _selectedClassIndex = index),
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? KukieAccent.violet : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected ? KukieAccent.violet.withAlpha(25) : const Color(0x05000000),
                                          blurRadius: isSelected ? 12 : 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: KukieAccent.violetTint,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                gradeLabel,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: KukieAccent.violet,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              academicYearStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          subjectName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Selected Class Roster & Details Panel
                        _buildRosterDetailPanel(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.class_outlined, size: 48, color: Color(0xFFD97706)),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Assigned Classes Found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage != null && _errorMessage!.isNotEmpty
                    ? _errorMessage!
                    : 'The school administrator has not assigned you to teach any active classes yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadClasses,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reload Classes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KukieAccent.violet,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ROSTER DETAIL PANEL ──────────────────────────────────────────
  Widget _buildRosterDetailPanel() {
    final safeIndex = (_selectedClassIndex >= 0 && _selectedClassIndex < _assignedClasses.length)
        ? _selectedClassIndex
        : 0;
    final currentClass = _assignedClasses[safeIndex];
    final subjectName = _getClassSubjectLabel(currentClass);
    final students = currentClass.students;
    final gradeLabel = currentClass.displayName.isNotEmpty
        ? currentClass.displayName
        : 'Grade ${currentClass.grade}-${currentClass.section}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Title, Subtitle, and Quick Action Buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$gradeLabel Class Roster',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Subject: $subjectName',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(MarkAttendancePage.routeName).then((_) => _loadClasses());
                      },
                      icon: const Icon(Icons.event_available_outlined, size: 15, color: Color(0xFF334155)),
                      label: const Text(
                        'Take Attendance',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(AddGradePage.routeName).then((_) => _loadClasses());
                      },
                      icon: const Icon(Icons.bookmark_outline_rounded, size: 15, color: Colors.white),
                      label: const Text(
                        'Record Grades',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        backgroundColor: KukieAccent.violet,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Class Information Banner Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: KukieAccent.violet,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Class Information',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        'Class ID: ${currentClass.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Guidance Note
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Use the Quick Attendance and Gradebook buttons above to record scores for this cohort.\nStudents enrolled in this section will appear dynamically in your Attendance Sheet and Gradebook.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF94A3B8),
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Enrolled Student Roster Cards List
          if (students.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Enrolled Roster (${students.length})',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  currentClass.academicYear,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...students.map((student) => _StudentRosterCard(
                  student: student,
                  onRecordGrade: () => _recordStudentGrade(
                    student.studentId,
                    student.studentName,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _StudentRosterCard extends StatelessWidget {
  const _StudentRosterCard({
    required this.student,
    required this.onRecordGrade,
  });

  final StudentClassInfo student;
  final VoidCallback onRecordGrade;

  @override
  Widget build(BuildContext context) {
    final initial = student.studentName.isNotEmpty
        ? student.studentName.substring(0, 1).toUpperCase()
        : 'S';
    final codeDisplay = (student.studentCode != null && student.studentCode!.isNotEmpty)
        ? student.studentCode!
        : student.studentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: KukieAccent.violetTint,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w800, color: KukieAccent.violet, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ID: $codeDisplay',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onRecordGrade,
            icon: const Icon(Icons.assignment_turned_in_outlined, size: 13, color: KukieAccent.violet),
            label: const Text(
              'Record Grade',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              minimumSize: const Size(0, 32),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
