import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/school_class.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'add_grade_page.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  static const routeName = '/teacher/classes';

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  final _teacherService = TeacherService();
  final _schoolService = SchoolManagementService();

  bool _loading = true;
  List<SchoolClass> _assignedClasses = [];
  int _selectedClassIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _loading = true);
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

      if (mounted) {
        setState(() {
          _assignedClasses = filtered;
          _selectedClassIndex = 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editStudentGrade(String studentId, String studentName, String className) async {
    final grades = await _teacherService.getGradesForStudent(studentId);
    GradeEntry? existing;
    if (grades.isNotEmpty) {
      existing = grades.first;
    }

    if (!mounted) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddGradePage(
          existingEntry: existing ??
              GradeEntry(
                id: 'ge-${DateTime.now().millisecondsSinceEpoch}',
                studentId: studentId,
                studentName: studentName,
                subject: className,
                assessmentType: AssessmentType.composite,
                score: 0.0,
                maxScore: 100.0,
                term: '2025/2026',
                createdAt: DateTime.now(),
              ),
        ),
      ),
    );

    if (updated == true && mounted) {
      _loadClasses();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Classes & Rosters')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_assignedClasses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Classes & Rosters')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined, size: 64, color: Colors.amber.shade700),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No Assigned Classes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'The school administrator has not assigned you to teach any class yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final safeIndex = (_selectedClassIndex >= 0 && _selectedClassIndex < _assignedClasses.length)
        ? _selectedClassIndex
        : 0;
    final currentClass = _assignedClasses[safeIndex];
    final students = currentClass.students;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes & Rosters'),
      ),
      body: Column(
        children: [
          // Class Tabs - ONLY Assigned Classes
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_assignedClasses.length, (index) {
                  final isSelected = index == safeIndex;
                  final cls = _assignedClasses[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(cls.displayName),
                      selectedColor: KukieAccent.violetTint,
                      labelStyle: TextStyle(
                        color: isSelected ? KukieAccent.violet : KukieAccent.ink,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedClassIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          // Selected Class Info Header
          Expanded(
            child: ListView(
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
                      Text(
                        currentClass.displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentClass.roomNumber} · Academic Year: ${currentClass.academicYear}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${students.length} Enrolled Students',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Class Roster & Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.of(context).pushNamed(AddGradePage.routeName);
                        if (res == true && mounted) _loadClasses();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Grade'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (students.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No students enrolled in ${currentClass.displayName} roster yet.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                else
                  ...students.map((student) => _StudentRosterCard(
                        student: student,
                        onToggleStatus: (newStatus) {
                          setState(() {});
                        },
                        onEditGrade: () => _editStudentGrade(
                          student.studentId,
                          student.studentName,
                          currentClass.displayName,
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRosterCard extends StatefulWidget {
  const _StudentRosterCard({
    required this.student,
    required this.onToggleStatus,
    required this.onEditGrade,
  });

  final StudentClassInfo student;
  final ValueChanged<String> onToggleStatus;
  final VoidCallback onEditGrade;

  @override
  State<_StudentRosterCard> createState() => _StudentRosterCardState();
}

class _StudentRosterCardState extends State<_StudentRosterCard> {
  String _status = 'Present';

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (_status) {
      case 'Present':
        statusColor = Colors.green.shade700;
        break;
      case 'Late':
        statusColor = Colors.orange.shade800;
        break;
      default:
        statusColor = Colors.red.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: KukieAccent.violetTint,
              child: Text(
                widget.student.studentName.isNotEmpty
                    ? widget.student.studentName.substring(0, 1).toUpperCase()
                    : 'S',
                style: const TextStyle(fontWeight: FontWeight.w800, color: KukieAccent.violet),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.studentName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    'ID: ${widget.student.studentId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: KukieAccent.violet),
              onPressed: widget.onEditGrade,
              tooltip: 'Edit Student Grade & Guidance',
            ),
            PopupMenuButton<String>(
              initialValue: _status,
              onSelected: (val) {
                setState(() => _status = val);
                widget.onToggleStatus(val);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      _status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                  ],
                ),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Present', child: Text('Present')),
                PopupMenuItem(value: 'Late', child: Text('Late')),
                PopupMenuItem(value: 'Absent', child: Text('Absent')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
