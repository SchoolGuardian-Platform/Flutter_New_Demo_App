import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/homework_entry.dart';
import '../../models/school_class.dart';
import '../../services/homework_service.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class ManageHomeworkPage extends StatefulWidget {
  const ManageHomeworkPage({super.key});

  static const routeName = '/teacher/manage-homework';

  @override
  State<ManageHomeworkPage> createState() => _ManageHomeworkPageState();
}

class _ManageHomeworkPageState extends State<ManageHomeworkPage> {
  final _homeworkService = HomeworkService();
  final _schoolService = SchoolManagementService();
  final _teacherService = TeacherService();

  List<HomeworkEntry> _homeworks = [];
  List<SchoolClass> _classes = [];
  List<String> _teacherSubjects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final hwList = await _homeworkService.getTeacherHomeworks();
      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();
      final allSubjects = await _schoolService.getSubjects();

      // Filter classes teacher teaches
      final teacherClasses = allClasses.where((c) {
        final isAssignedByJoin = c.teachers.any((t) =>
            t.teacherId == profile.id ||
            t.teacherName.toLowerCase() == profile.fullName.toLowerCase());
        final isAssignedByName = profile.assignedClasses.contains(c.displayName) ||
            profile.assignedClasses.contains(c.shortLabel);
        return isAssignedByJoin || isAssignedByName;
      }).toList();

      // Collect teacher's assigned subjects directly from profile
      final Set<String> subjSet = {};
      for (final s in profile.assignedSubjects) {
        if (s.trim().isNotEmpty) subjSet.add(s.trim());
      }
      if (subjSet.isEmpty) {
        for (final s in allSubjects) {
          if (s.name.trim().isNotEmpty) subjSet.add(s.name.trim());
        }
      }

      if (mounted) {
        setState(() {
          _homeworks = hwList;
          _classes = teacherClasses.isNotEmpty ? teacherClasses : allClasses;
          _teacherSubjects = subjSet.toList()..sort();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _dialogInputDecoration(String labelText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon, color: KukieAccent.violet, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KukieAccent.violet, width: 1.8),
      ),
    );
  }

  Future<void> _showCreateHomeworkDialog() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    SchoolClass? selectedClass = _classes.isNotEmpty ? _classes.first : null;
    String selectedSubject = _teacherSubjects.isNotEmpty ? _teacherSubjects.first : 'General';
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 2));

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final dateStr = DateFormat('EEE, MMM d, yyyy').format(selectedDueDate);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: KukieAccent.violetTint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: KukieAccent.violet, size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'New Homework Assignment',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    const SizedBox(height: 10),
                    if (_classes.isNotEmpty)
                      DropdownButtonFormField<SchoolClass>(
                        value: selectedClass,
                        isExpanded: true,
                        decoration: _dialogInputDecoration('Target Class *', Icons.class_outlined),
                        items: _classes
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.displayName, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) => setDialogState(() => selectedClass = val),
                      ),
                    const SizedBox(height: 12),

                    // Dynamic Subject Dropdown suggested directly from teacher's assigned subjects
                    if (_teacherSubjects.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _teacherSubjects.contains(selectedSubject) ? selectedSubject : _teacherSubjects.first,
                        isExpanded: true,
                        decoration: _dialogInputDecoration('Subject *', Icons.book_outlined),
                        items: _teacherSubjects
                            .map((subj) => DropdownMenuItem(
                                  value: subj,
                                  child: Text(subj, overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedSubject = val);
                        },
                      )
                    else
                      TextFormField(
                        initialValue: selectedSubject,
                        decoration: _dialogInputDecoration('Subject *', Icons.book_outlined),
                        onChanged: (val) => selectedSubject = val,
                      ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: titleCtrl,
                      decoration: _dialogInputDecoration('Assignment Title *', Icons.title),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: _dialogInputDecoration('Instructions / Description *', Icons.description_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event, color: KukieAccent.violet, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Due Date', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 180)),
                                );
                                if (picked != null) {
                                  setDialogState(() => selectedDueDate = picked);
                                }
                              },
                              child: const Text('Select Date'),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                  if (formKey.currentState!.validate() && selectedClass != null) {
                    await _homeworkService.createHomework(
                      classId: selectedClass!.id,
                      className: selectedClass!.displayName,
                      subject: selectedSubject,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      dueDate: selectedDueDate,
                    );
                    if (!mounted) return;
                    Navigator.of(dialogCtx).pop();
                    _loadData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Homework assignment published!'), backgroundColor: KukieAccent.success),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: KukieAccent.violet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('Publish Homework'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteHomework(String id) async {
    await _homeworkService.deleteHomework(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homework Assignments'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateHomeworkDialog,
        backgroundColor: KukieAccent.violet,
        icon: const Icon(Icons.add),
        label: const Text('New Homework'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _homeworks.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('No homework assignments published yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _showCreateHomeworkDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Create First Homework'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KukieAccent.violet,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _homeworks.length,
                  itemBuilder: (context, index) {
                    final hw = _homeworks[index];
                    final dueStr = DateFormat('EEE, MMM d, yyyy').format(hw.dueDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: KukieAccent.violetTint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    hw.subject,
                                    style: const TextStyle(color: KukieAccent.violet, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                  onPressed: () => _deleteHomework(hw.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(hw.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(hw.description, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Target: ${hw.className ?? 'Class'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                Row(
                                  children: [
                                    const Icon(Icons.event, size: 14, color: Colors.orange),
                                    const SizedBox(width: 4),
                                    Text('Due: $dueStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
