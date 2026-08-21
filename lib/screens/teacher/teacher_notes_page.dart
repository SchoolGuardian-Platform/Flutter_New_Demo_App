import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/school_class.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_note_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';

class TeacherNotesPage extends StatefulWidget {
  const TeacherNotesPage({super.key});

  static const routeName = '/teacher/notes';

  @override
  State<TeacherNotesPage> createState() => _TeacherNotesPageState();
}

class _TeacherNotesPageState extends State<TeacherNotesPage> {
  final _noteService = TeacherNoteService();
  final _teacherService = TeacherService();
  final _schoolService = SchoolManagementService();

  List<TeacherNoteItem> _notes = [];
  List<StudentClassInfo> _students = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final notes = await _noteService.getTeacherNotes();
      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();

      final teacherClasses = allClasses.where((sc) {
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

      final activeClasses = teacherClasses.isNotEmpty ? teacherClasses : allClasses;
      final List<StudentClassInfo> stList = [];
      for (final c in activeClasses) {
        for (final s in c.students) {
          if (!stList.any((existing) => existing.studentId == s.studentId)) {
            stList.add(s);
          }
        }
      }

      if (mounted) {
        setState(() {
          _notes = notes;
          _students = stList;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openWriteNoteDialog([TeacherNoteItem? existingNote]) {
    final isEditing = existingNote != null;
    String? selectedStudentId = existingNote?.studentId;
    final titleController = TextEditingController(text: existingNote?.title ?? '');
    final contentController = TextEditingController(text: existingNote?.content ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Edit Observation Note' : 'Write Observation Note',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      const Text('Target Student *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedStudentId,
                        decoration: InputDecoration(
                          hintText: 'Select student from roster',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        items: _students.map((st) {
                          return DropdownMenuItem<String>(
                            value: st.studentId,
                            child: Text(st.studentName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setDialogState(() => selectedStudentId = val),
                      ),
                      const SizedBox(height: 14),
                    ],
                    const Text('Observation Title *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Commendation: Outstanding science participation',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Observation & Remarks *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Detail student achievements, areas of growth, or behavioral observations...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: KukieAccent.violet,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();

                    if (title.isEmpty || content.isEmpty || (!isEditing && selectedStudentId == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please complete all required fields.')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    if (isEditing) {
                      await _noteService.updateNote(existingNote.id, title: title, content: content);
                    } else {
                      await _noteService.createNote(studentId: selectedStudentId!, title: title, content: content);
                    }
                    _loadData();
                  },
                  child: Text(isEditing ? 'Update Note' : 'Publish Note'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _notes.where((n) {
      final q = _searchQuery.trim().toLowerCase();
      if (q.isEmpty) return true;
      final stName = n.studentName?.toLowerCase() ?? '';
      return stName.contains(q) || n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();

    final coveredStudents = _notes.map((n) => n.studentId).toSet().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Student Observation Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            Text('Log pedagogical observations & feedback', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openWriteNoteDialog(),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text('Write Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: KukieAccent.violet,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Banner Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF4F46E5), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Notes', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    Text('${_notes.length}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.people_outline_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Students Covered', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    Text('$coveredStudents', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search Bar
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by student name, title, or remark...',
                      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                              child: const Icon(Icons.notes_rounded, size: 36, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 12),
                            const Text('No observation notes recorded yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text('Tap "Write Note" to log pedagogical observations', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map((note) {
                      final dateStr = DateFormat('MMM d, yyyy').format(note.createdAt);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [
                            BoxShadow(color: Color(0x04000000), blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // SINGLE CLEAN ROW FOR STUDENT NAME & DATE
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: KukieAccent.violetTint,
                                  child: Text(
                                    note.studentName?.isNotEmpty == true ? note.studentName!.substring(0, 1).toUpperCase() : 'S',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    note.studentName ?? 'Student ${note.studentId}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              note.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              note.content,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openWriteNoteDialog(note),
                                  icon: const Icon(Icons.edit_outlined, size: 13, color: KukieAccent.violet),
                                  label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: KukieAccent.violet)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 30),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final del = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete Note?'),
                                        content: const Text('Are you sure you want to delete this observation note?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );
                                    if (del == true) {
                                      await _noteService.deleteNote(note.id);
                                      _loadData();
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline_rounded, size: 13, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    minimumSize: const Size(0, 30),
                                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
