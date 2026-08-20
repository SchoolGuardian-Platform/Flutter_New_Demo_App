import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/school_class.dart';
import '../../models/subject.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/school_management_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Comprehensive Admin page for Class & Section Registration and Management.
/// Exposes all database fields from the Prisma schema and allows assigning
/// students and teachers to specific classes/sections.
class ClassSectionManagementPage extends StatefulWidget {
  const ClassSectionManagementPage({super.key});

  static const routeName = '/admin/class-sections';

  @override
  State<ClassSectionManagementPage> createState() => _ClassSectionManagementPageState();
}

class _ClassSectionManagementPageState extends State<ClassSectionManagementPage> {
  final _schoolService = SchoolManagementService();
  final _adminService = AdminService();

  List<SchoolClass> _classes = [];
  List<Subject> _subjects = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final classes = await _schoolService.getClasses();
      final subjects = await _schoolService.getSubjects();
      if (!mounted) return;
      setState(() {
        _classes = classes;
        _subjects = subjects;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load class & section records.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRegisterClassDialog() {
    final formKey = GlobalKey<FormState>();
    int selectedGrade = 9;
    final sectionController = TextEditingController(text: 'A');
    final roomController = TextEditingController(text: 'Room 101');
    final capacityController = TextEditingController(text: '35');
    final yearController = TextEditingController(text: '2025/2026');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: KukieAccent.violetTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.school, color: KukieAccent.violet, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Register Class & Section',
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
                DropdownButtonFormField<int>(
                  initialValue: selectedGrade,
                  dropdownColor: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  menuMaxHeight: 280,
                  decoration: const InputDecoration(
                    labelText: 'Grade Level (1 - 12) *',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.grade_outlined),
                  ),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Grade ${i + 1}'),
                    ),
                  ),
                  onChanged: (val) {
                    if (val != null) selectedGrade = val;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Section Name / Code *',
                    hintText: 'e.g. A, B, C, 101',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Section is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: roomController,
                        decoration: const InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'e.g. Room 204',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max Capacity',
                          hintText: '35',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null;
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return 'Invalid capacity';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: yearController,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    hintText: '2025/2026',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description / Notes (Optional)',
                    hintText: 'e.g. Natural Science Stream Section',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              try {
                final created = await _schoolService.createClass(
                  grade: selectedGrade,
                  section: sectionController.text.trim(),
                  roomNumber: roomController.text.trim(),
                  maxCapacity: int.tryParse(capacityController.text.trim()) ?? 35,
                  academicYear: yearController.text.trim(),
                  description: descController.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Class ${created.displayName} registered successfully!')),
                );
                _loadData();
              } on ApiException catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
              } catch (_) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not create class.')),
                );
              }
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _showManageSubjectsDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'STEM');

    showDialog(
      context: context,
      builder: (ctx) {
        List<Subject> dialogSubjects = List.from(_subjects);
        bool isLoading = true;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            if (isLoading) {
              isLoading = false;
              _schoolService.getSubjects().then((updated) {
                if (ctx.mounted) {
                  setDialogState(() {
                    dialogSubjects = updated;
                    _subjects = updated;
                  });
                }
              });
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.book_outlined, color: KukieAccent.violet),
                  SizedBox(width: 8),
                  Text('School Subjects'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add New Subject',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subject Name *',
                          hintText: 'e.g. Mathematics',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: codeCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Code',
                                hintText: 'MATH-101',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: catCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                hintText: 'STEM / Languages',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: KukieAccent.violet,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Subject'),
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            try {
                              await _schoolService.createSubject(
                                name: nameCtrl.text.trim(),
                                code: codeCtrl.text.trim(),
                                category: catCtrl.text.trim(),
                              );
                              nameCtrl.clear();
                              codeCtrl.clear();
                              final updated = await _schoolService.getSubjects();
                              setDialogState(() {
                                dialogSubjects = updated;
                                _subjects = updated;
                              });
                              _loadData();
                            } on ApiException catch (e) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.message)));
                            }
                          },
                        ),
                      ),
                      const Divider(height: 24),
                      const Text(
                        'Existing Subjects',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (dialogSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No subjects created yet.',
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...dialogSubjects.map(
                          (s) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: KukieAccent.violetTint,
                              child: Text(
                                s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : 'S',
                                style: const TextStyle(
                                  color: KukieAccent.violet,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            title: Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: Text('${s.code ?? 'No Code'} • ${s.category ?? 'General'}', style: const TextStyle(fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () async {
                                await _schoolService.deleteSubject(s.id);
                                final updated = await _schoolService.getSubjects();
                                setDialogState(() {
                                  dialogSubjects = updated;
                                  _subjects = updated;
                                });
                                _loadData();
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAllDbFieldsModal(SchoolClass cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (ctx, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: KukieAccent.violetTint,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.class_outlined, color: KukieAccent.violet, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cls.displayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Academic Year: ${cls.academicYear}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Database Schema Fields (Prisma Record)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _DbFieldRow(label: 'Class ID (UUID)', value: cls.id),
                    _DbFieldRow(label: 'Grade Level', value: '${cls.grade}'),
                    _DbFieldRow(label: 'Section Code', value: cls.section),
                    _DbFieldRow(label: 'Academic Year', value: cls.academicYear),
                    _DbFieldRow(label: 'Room / Location', value: cls.roomNumber ?? 'Unassigned'),
                    _DbFieldRow(label: 'Max Capacity', value: '${cls.studentCount} / ${cls.maxCapacity} Seats'),
                    _DbFieldRow(label: 'Description', value: cls.description ?? 'None'),
                    _DbFieldRow(
                      label: 'Created At',
                      value: cls.createdAt != null ? cls.createdAt!.toLocal().toString().split('.')[0] : 'N/A',
                    ),
                    _DbFieldRow(
                      label: 'Updated At',
                      value: cls.updatedAt != null ? cls.updatedAt!.toLocal().toString().split('.')[0] : 'N/A',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Enrolled Students Roster
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Enrolled Students (${cls.studentCount})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showAssignStudentDialog(cls);
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Add Student'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (cls.students.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text('No students currently enrolled in this class.', style: TextStyle(color: AppColors.outline)),
                  ),
                )
              else
                ...cls.students.map(
                  (st) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    elevation: 0,
                    color: AppColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: KukieAccent.violetTint,
                        child: Icon(Icons.school, color: KukieAccent.violet, size: 18),
                      ),
                      title: Text(st.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        'Code: ${st.studentCode ?? st.studentId} • Enrolled: ${st.academicYear ?? cls.academicYear}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                        tooltip: 'Unassign Student',
                        onPressed: () async {
                          final nav = Navigator.of(ctx);
                          await _schoolService.removeStudentFromClass(
                            classId: cls.id,
                            enrollmentId: st.id,
                          );
                          _loadData();
                          nav.pop();
                        },
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.lg),

              // Assigned Teachers & Subjects
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Teachers & Subjects (${cls.teacherCount})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showAssignTeacherDialog(cls);
                    },
                    icon: const Icon(Icons.person_add_alt_1, size: 16),
                    label: const Text('Assign Teacher'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (cls.teachers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(
                    child: Text('No teachers assigned to this class yet.', style: TextStyle(color: AppColors.outline)),
                  ),
                )
              else
                ...cls.teachers.map(
                  (tc) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    elevation: 0,
                    color: AppColors.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: AppColors.outlineVariant),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.menu_book, color: AppColors.primary, size: 18),
                      ),
                      title: Text(tc.teacherName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        'Subject: ${tc.subjectName} • Year: ${tc.academicYear ?? cls.academicYear}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                        tooltip: 'Unassign Teacher',
                        onPressed: () async {
                          final nav = Navigator.of(ctx);
                          await _schoolService.removeTeacherFromClass(
                            classId: cls.id,
                            assignmentId: tc.id,
                          );
                          _loadData();
                          nav.pop();
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignStudentDialog(SchoolClass cls) async {
    List<User> existingStudents = [];
    try {
      final active = await _adminService.getActive(UserRole.student);
      final pending = await _adminService.getPending(UserRole.student);
      final byId = <String, User>{};
      for (final s in [...active, ...pending]) {
        byId[s.id] = s;
      }
      existingStudents = byId.values.toList();
    } catch (_) {}

    User? selectedStudent = existingStudents.isNotEmpty ? existingStudents.first : null;
    int selectedTab = 0; // 0: Select Existing, 1: Register New

    final newNameCtrl = TextEditingController();
    final newCodeCtrl = TextEditingController();
    final newEmailCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: cls.academicYear);
    final formKey = GlobalKey<FormState>();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: KukieAccent.violetTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_alt_1, color: KukieAccent.violet, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Register Student to ${cls.displayName}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Academic Year: ${cls.academicYear}',
                      style: const TextStyle(fontSize: 11, color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedTab == 0 ? AppColors.surfaceContainerLowest : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                boxShadow: selectedTab == 0 ? AppColors.cardShadow : null,
                              ),
                              child: Text(
                                'Select Existing',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                  color: selectedTab == 0 ? KukieAccent.violet : AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedTab == 1 ? AppColors.surfaceContainerLowest : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                                boxShadow: selectedTab == 1 ? AppColors.cardShadow : null,
                              ),
                              child: Text(
                                'Register New',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                  color: selectedTab == 1 ? KukieAccent.violet : AppColors.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (selectedTab == 0) ...[
                    if (existingStudents.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'No registered students found. Switch to "Register New" to add a student to this class.',
                          style: TextStyle(color: AppColors.outline, fontSize: 13),
                        ),
                      )
                    else
                      DropdownButtonFormField<User>(
                        isExpanded: true,
                        initialValue: selectedStudent,
                        dropdownColor: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        menuMaxHeight: 280,
                        decoration: const InputDecoration(
                          labelText: 'Select Registered Student *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: existingStudents
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  '${s.fullName} (${s.studentId ?? 'ID: ${s.id.substring(0, 6)}'})',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setDialogState(() => selectedStudent = v);
                        },
                      ),
                  ] else ...[
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: newNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student Full Name *',
                              hintText: 'e.g. Abebe Bikila',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Full Name is required' : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: newCodeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student ID / Roll Code',
                              hintText: 'e.g. STU-2025-010',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: newEmailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address (Optional)',
                              hintText: 'e.g. abebe@school.edu',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
              onPressed: () async {
                if (selectedTab == 1 && !formKey.currentState!.validate()) return;
                if (selectedTab == 0 && selectedStudent == null) return;

                final nav = Navigator.of(ctx);
                final realCode = selectedTab == 0
                    ? (selectedStudent!.studentId ?? 'SG-${DateTime.now().year}-${selectedStudent!.id.hashCode.abs().toString().padLeft(6, '0')}')
                    : (newCodeCtrl.text.trim().isNotEmpty
                        ? newCodeCtrl.text.trim()
                        : 'SG-${DateTime.now().year}-${(100000 + (DateTime.now().millisecondsSinceEpoch % 899999))}');

                final studentId = selectedTab == 0
                    ? selectedStudent!.id
                    : realCode;
                final studentName = selectedTab == 0
                    ? selectedStudent!.fullName
                    : newNameCtrl.text.trim();
                final studentCode = realCode;

                nav.pop();
                try {
                  await _schoolService.assignStudentToClass(
                    studentId: studentId,
                    studentName: studentName,
                    studentCode: studentCode,
                    classId: cls.id,
                    academicYear: yearCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$studentName registered & assigned to ${cls.displayName}!')),
                  );
                  _loadData();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not assign student to class.')),
                  );
                }
              },
              child: Text(selectedTab == 0 ? 'Assign Student' : 'Register & Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignTeacherDialog(SchoolClass cls) async {
    List<User> activeTeachers = [];
    try {
      activeTeachers = await _adminService.getActive(UserRole.teacher);
    } catch (_) {}

    if (activeTeachers.isEmpty) {
      activeTeachers = [
        User(
          id: 'tch-001',
          firstName: 'Teacher',
          lastName: 'Account',
          email: 'teacher@school.edu',
          role: UserRole.teacher,
          status: AccountStatus.active,
          createdAt: DateTime.now(),
        )
      ];
    }
    User? selectedTeacher = activeTeachers.isNotEmpty ? activeTeachers.first : null;
    Subject? selectedSubject = _subjects.isNotEmpty ? _subjects.first : null;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Teacher to ${cls.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<User>(
                isExpanded: true,
                initialValue: selectedTeacher,
                dropdownColor: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                menuMaxHeight: 280,
                decoration: const InputDecoration(
                  labelText: 'Select Teacher',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                items: activeTeachers
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.fullName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setDialogState(() => selectedTeacher = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<Subject>(
                isExpanded: true,
                initialValue: selectedSubject,
                dropdownColor: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                menuMaxHeight: 280,
                decoration: const InputDecoration(
                  labelText: 'Select Subject Taught',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
                items: _subjects
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(
                          '${s.name} (${s.code ?? 'Gen'})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setDialogState(() => selectedSubject = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
              onPressed: (selectedTeacher == null || selectedSubject == null)
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      try {
                        await _schoolService.assignTeacherToClass(
                          teacherId: selectedTeacher!.id,
                          teacherName: selectedTeacher!.fullName,
                          subjectId: selectedSubject!.id,
                          subjectName: selectedSubject!.name,
                          classId: cls.id,
                          academicYear: cls.academicYear,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${selectedTeacher!.fullName} assigned to teach ${selectedSubject!.name} in ${cls.displayName}!',
                            ),
                          ),
                        );
                        _loadData();
                      } on ApiException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                      }
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteClass(SchoolClass cls) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class & Section?'),
        content: Text(
          'Are you sure you want to delete ${cls.displayName}? This will remove all student enrollments and teacher assignments for this class.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _schoolService.deleteClass(cls.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cls.displayName} deleted.')),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalStudents = _classes.fold(0, (sum, c) => sum + c.studentCount);
    int totalTeachers = _classes.fold(0, (sum, c) => sum + c.teacherCount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Class & Section Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined),
            tooltip: 'Manage Subjects',
            onPressed: _showManageSubjectsDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRegisterClassDialog,
        backgroundColor: KukieAccent.violet,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Top Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KukieAccent.violet, KukieAccent.violetDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.class_outlined, color: Colors.white, size: 30),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${_classes.length} Active Class & Section Records',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HeaderStat(label: 'Classes', value: '${_classes.length}', icon: Icons.meeting_room_outlined),
                      _HeaderStat(label: 'Students Enrolled', value: '$totalStudents', icon: Icons.school_outlined),
                      _HeaderStat(label: 'Teachers Assigned', value: '$totalTeachers', icon: Icons.menu_book_outlined),
                      _HeaderStat(label: 'Subjects', value: '${_subjects.length}', icon: Icons.auto_stories_outlined),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            if (_loading && _classes.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _classes.isEmpty)
              Center(
                child: Column(
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_classes.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.school_outlined, size: 48, color: KukieAccent.violet),
                      const SizedBox(height: 12),
                      const Text(
                        'No classes or sections registered yet.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Click "+ New Class" below to add your first class section.',
                        style: TextStyle(color: AppColors.outline, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
                        onPressed: _showRegisterClassDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Register First Class'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._classes.map(
                (cls) => _ClassCard(
                  cls: cls,
                  onViewDbFields: () => _showAllDbFieldsModal(cls),
                  onAssignStudent: () => _showAssignStudentDialog(cls),
                  onAssignTeacher: () => _showAssignTeacherDialog(cls),
                  onDelete: () => _confirmDeleteClass(cls),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.cls,
    required this.onViewDbFields,
    required this.onAssignStudent,
    required this.onAssignTeacher,
    required this.onDelete,
  });

  final SchoolClass cls;
  final VoidCallback onViewDbFields;
  final VoidCallback onAssignStudent;
  final VoidCallback onAssignTeacher;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      elevation: 0,
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: KukieAccent.violetTint,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'G${cls.grade}',
                      style: const TextStyle(
                        color: KukieAccent.violet,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cls.roomNumber ?? 'No Room'} • Academic Year: ${cls.academicYear}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete Class',
                ),
              ],
            ),
            if (cls.description != null && cls.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                cls.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatusChip(
                  icon: Icons.school_outlined,
                  label: '${cls.studentCount} / ${cls.maxCapacity} Students',
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                _StatusChip(
                  icon: Icons.menu_book_outlined,
                  label: '${cls.teacherCount} Teachers',
                  color: AppColors.secondary,
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewDbFields,
                  icon: const Icon(Icons.storage, size: 16),
                  label: const Text('View All DB Fields'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.person_add_alt, size: 20, color: KukieAccent.violet),
                      tooltip: 'Assign Student',
                      onPressed: onAssignStudent,
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, size: 20, color: AppColors.primary),
                      tooltip: 'Assign Teacher',
                      onPressed: onAssignTeacher,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DbFieldRow extends StatelessWidget {
  const _DbFieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
