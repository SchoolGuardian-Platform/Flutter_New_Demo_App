import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/teacher_profile.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../services/auth_service.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'add_grade_page.dart';
import 'mark_attendance_page.dart';
import 'manage_homework_page.dart';

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
  String _selectedSubject = 'ALL';
  final List<String> _customSubjects = [];

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

    final subjectList = List<String>.from(profile.assignedSubjects);
    for (final g in grades) {
      if (g.subject.isNotEmpty && !subjectList.contains(g.subject)) {
        subjectList.add(g.subject);
      }
    }

    setState(() {
      _profile = profile;
      _grades = grades;
      _customSubjects.clear();
      _customSubjects.addAll(subjectList);
      _loading = false;
    });
  }

  Future<void> _showAddSubjectBarDialog() async {
    List<Subject> dbSubjects = [];
    List<SchoolClass> availableClasses = [];
    try {
      dbSubjects = await SchoolManagementService().getSubjects();
      availableClasses = await SchoolManagementService().getClasses();
    } catch (_) {}

    String? selectedDbSubject = dbSubjects.isNotEmpty ? dbSubjects.first.name : null;
    SchoolClass? selectedClass = availableClasses.isNotEmpty ? availableClasses.first : null;
    final customSubjectController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool useCustomSubject = dbSubjects.isEmpty;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: KukieAccent.violetTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_ind_outlined, color: KukieAccent.violet, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Assign Subject to Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select a course created by the Admin in the school database to add to your teaching profile.',
                      style: TextStyle(fontSize: 12.5, color: Colors.black87),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (dbSubjects.isNotEmpty && !useCustomSubject) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedDbSubject,
                        decoration: const InputDecoration(
                          labelText: 'Select Admin Course / Subject *',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                        ),
                        items: dbSubjects.map((s) => DropdownMenuItem(
                          value: s.name,
                          child: Text(s.name),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedDbSubject = val);
                        },
                      ),
                      const SizedBox(height: 6),
                      TextButton.icon(
                        onPressed: () => setDialogState(() => useCustomSubject = true),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add a custom subject name instead', style: TextStyle(fontSize: 12)),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: customSubjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name *',
                          hintText: 'e.g. Chemistry',
                          prefixIcon: Icon(Icons.book_outlined),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      if (dbSubjects.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        TextButton.icon(
                          onPressed: () => setDialogState(() => useCustomSubject = false),
                          icon: const Icon(Icons.list, size: 14),
                          label: const Text('Choose from Admin Courses list', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],

                    const SizedBox(height: AppSpacing.md),
                    if (availableClasses.isNotEmpty) ...[
                      DropdownButtonFormField<SchoolClass>(
                        initialValue: selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Target Class (For DB TeacherClassSubject)',
                          prefixIcon: Icon(Icons.class_outlined),
                        ),
                        items: availableClasses.map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.displayName),
                        )).toList(),
                        onChanged: (val) {
                          setDialogState(() => selectedClass = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final targetSubject = useCustomSubject
                        ? customSubjectController.text.trim()
                        : (selectedDbSubject ?? customSubjectController.text.trim());

                    if (targetSubject.isEmpty) return;

                    // 1. Add to Teacher Profile (My Teaching Subjects)
                    await _teacherService.addAssignedSubject(targetSubject);

                    // 2. Persist to Neon DB TeacherClassSubject table
                    try {
                      final me = await AuthService().getMe();
                      final cls = selectedClass ?? (availableClasses.isNotEmpty ? availableClasses.first : null);

                      if (cls != null) {
                        await SchoolManagementService().assignTeacherToClass(
                          teacherId: me.id,
                          teacherName: '${me.firstName} ${me.lastName}',
                          classId: cls.id,
                          subjectId: targetSubject,
                          subjectName: targetSubject,
                        );
                      } else {
                        await SchoolManagementService().createSubject(name: targetSubject);
                      }
                    } catch (_) {}

                    if (!mounted) return;
                    final nav = Navigator.of(dialogCtx);
                    final messenger = ScaffoldMessenger.of(context);

                    nav.pop();
                    await _loadData();

                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Assigned "$targetSubject" to your teaching profile!'),
                        backgroundColor: KukieAccent.success,
                      ),
                    );
                  }
                },
                child: const Text('Assign to Profile'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAddGrade() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddGradePage()),
    );
    if (added == true) {
      _loadData();
    }
  }

  Future<void> _openEditGrade(GradeEntry entry) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddGradePage(existingEntry: entry)),
    );
    if (updated == true) {
      _loadData();
    }
  }

  Future<void> _deleteGrade(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student Grade?'),
        content: const Text('Are you sure you want to delete this grade record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _teacherService.deleteGradeEntry(id);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Portal'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: KukieAccent.violet,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on Grades / Main Dashboard
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MarkAttendancePage()),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageHomeworkPage()),
              );
              break;
            case 3:
              Navigator.of(context).pushNamed('/reports');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grade_outlined), label: 'Grades'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Homework'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), label: 'Reports'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _TeacherHeaderCard(
                    profile: _profile!,
                    onProfileUpdated: _loadData,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsRow(gradesCount: _grades.length),
                  const SizedBox(height: AppSpacing.md),
                  const SizedBox(height: AppSpacing.lg),

                  // --- Subject / Course Teaching Bars ---
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'My Teaching Subjects',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddSubjectBarDialog,
                        icon: const Icon(Icons.add_card, size: 16),
                        label: const Text('+ Assign Subject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          selected: _selectedSubject == 'ALL',
                          label: Text('All Subjects (${_grades.length})'),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedSubject = 'ALL');
                          },
                          selectedColor: KukieAccent.violetTint,
                          checkmarkColor: KukieAccent.violet,
                        ),
                        const SizedBox(width: 8),
                        ..._customSubjects.map((subject) {
                          final count = _grades
                              .where((g) =>
                                  g.subject.trim().toLowerCase() ==
                                  subject.trim().toLowerCase())
                              .length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: _selectedSubject == subject,
                              label: Text('$subject ($count)'),
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedSubject = subject);
                              },
                              selectedColor: KukieAccent.violetTint,
                              checkmarkColor: KukieAccent.violet,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSubject == 'ALL'
                            ? 'Student Grades (${_grades.length})'
                            : 'Students in $_selectedSubject (${_grades.where((g) => g.subject.trim().toLowerCase() == _selectedSubject.trim().toLowerCase()).length})',
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
                  Builder(
                    builder: (context) {
                      final filtered = _selectedSubject == 'ALL'
                          ? _grades
                          : _grades
                              .where((g) =>
                                  g.subject.trim().toLowerCase() ==
                                  _selectedSubject.trim().toLowerCase())
                              .toList();

                      if (filtered.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Center(
                              child: Text(_selectedSubject == 'ALL'
                                  ? 'No student grades recorded yet. Click "+ Add Grade & Guidance" to add the first result!'
                                  : 'No students graded for "$_selectedSubject" yet.'),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: filtered
                            .map(
                              (g) => _TeacherGradeCard(
                                grade: g,
                                onEdit: () => _openEditGrade(g),
                                onDelete: () => _deleteGrade(g.id),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _TeacherHeaderCard extends StatelessWidget {
  const _TeacherHeaderCard({
    required this.profile,
    required this.onProfileUpdated,
  });

  final TeacherProfile profile;
  final VoidCallback onProfileUpdated;

  void _editMajorField(BuildContext context) {
    final controller = TextEditingController(text: profile.majorField);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Major Field of Study'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Major Field of Study',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await TeacherService().updateMajorField(controller.text.trim());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  onProfileUpdated();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.amberAccent),
                onPressed: () => _editMajorField(context),
                tooltip: 'Edit Major Field of Study',
              ),
            ],
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
            title: 'Assigned Classes',
            value: 'Active',
            subtitle: 'Class management',
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
              Icon(icon, color: color, size: 22),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
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
  const _TeacherGradeCard({
    required this.grade,
    required this.onEdit,
    required this.onDelete,
  });

  final GradeEntry grade;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
                            fontSize: 15, fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'ID: ${grade.studentId} · ${grade.subject}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${grade.score.toStringAsFixed(1)} / ${grade.maxScore.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: KukieAccent.violet,
                      fontSize: 12,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Student Grade'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Record', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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
                Expanded(
                  child: Text(
                    grade.term,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            if (grade.hasBreakdown) ...[
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
            if (grade.parentRecommendation != null && grade.parentRecommendation!.isNotEmpty) ...[
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
