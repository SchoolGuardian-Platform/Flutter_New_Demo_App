import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/school_class.dart';
import '../../models/teacher_profile.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/kukie_accent.dart';

class AddGradePage extends StatefulWidget {
  const AddGradePage({
    super.key,
    this.existingEntry,
    this.initialStudentId,
    this.initialStudentName,
  });

  static const routeName = '/teacher/add-grade';
  final GradeEntry? existingEntry;
  final String? initialStudentId;
  final String? initialStudentName;

  @override
  State<AddGradePage> createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final _formKey = GlobalKey<FormState>();
  final _teacherService = TeacherService();
  final _schoolService = SchoolManagementService();

  late final TextEditingController _subjectController;
  late final TextEditingController _scoreController;
  late final TextEditingController _maxScoreController;
  late final TextEditingController _academicYearController;
  late final TextEditingController _commentController;

  List<SchoolClass> _availableClasses = [];
  String? _selectedClassId;
  String? _selectedStudentId;
  String? _selectedStudentName;
  String _selectedSemester = '1st Semester';
  String _assessmentTypeLabel = 'Assignment';

  List<StudentClassInfo> _classStudents = [];
  List<String> _teacherSubjects = [];

  bool _loading = true;
  bool _submitting = false;

  bool get _isEditing => widget.existingEntry != null;

  static const List<Map<String, String>> _assessmentTypes = [
    {'value': 'ASSIGNMENT', 'label': 'Assignment'},
    {'value': 'QUIZ', 'label': 'Quiz'},
    {'value': 'MIDTERM', 'label': 'Midterm'},
    {'value': 'FINAL', 'label': 'Final'},
    {'value': 'PROJECT', 'label': 'Project'},
    {'value': 'OTHER', 'label': 'Other'},
  ];

  TeacherProfile? _teacherProfile;

  List<String> _getSubjectsForSelectedClass(SchoolClass? sc, TeacherProfile? profile) {
    if (sc != null && sc.teachers.isNotEmpty) {
      final classSubjs = <String>[];
      if (profile != null) {
        for (final t in sc.teachers) {
          final matches = (t.teacherId.isNotEmpty && t.teacherId == profile.id) ||
              (t.teacherName.isNotEmpty && t.teacherName.toLowerCase() == profile.fullName.toLowerCase());
          if (matches && t.subjectName.trim().isNotEmpty) {
            classSubjs.add(t.subjectName.trim());
          }
        }
      }
      if (classSubjs.isEmpty) {
        for (final t in sc.teachers) {
          if (t.subjectName.trim().isNotEmpty) {
            classSubjs.add(t.subjectName.trim());
          }
        }
      }
      if (classSubjs.isNotEmpty) {
        return classSubjs.toSet().toList()..sort();
      }
    }
    if (_teacherSubjects.isNotEmpty) {
      return _teacherSubjects;
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;

    _selectedStudentId = entry?.studentId ?? widget.initialStudentId;
    _selectedStudentName = entry?.studentName ?? widget.initialStudentName;

    if (entry?.term != null && entry!.term.isNotEmpty) {
      if (entry.term.contains('2nd Semester')) {
        _selectedSemester = '2nd Semester';
      } else {
        _selectedSemester = '1st Semester';
      }
    }

    _subjectController = TextEditingController(text: entry?.subject ?? '');
    _scoreController = TextEditingController(text: entry?.score != null && entry!.score > 0 ? entry.score.toStringAsFixed(0) : '85');
    _maxScoreController = TextEditingController(text: entry?.maxScore != null && entry!.maxScore > 0 ? entry.maxScore.toStringAsFixed(0) : '100');
    _academicYearController = TextEditingController(text: '2026-2027');
    _commentController = TextEditingController(text: entry?.parentRecommendation ?? '');

    if (entry != null) {
      switch (entry.assessmentType) {
        case AssessmentType.midterm:
          _assessmentTypeLabel = 'Midterm';
          break;
        case AssessmentType.finalExam:
          _assessmentTypeLabel = 'Final';
          break;
        case AssessmentType.quiz:
          _assessmentTypeLabel = 'Quiz';
          break;
        case AssessmentType.project:
          _assessmentTypeLabel = 'Project';
          break;
        case AssessmentType.assignment:
          _assessmentTypeLabel = 'Assignment';
          break;
        case AssessmentType.composite:
          _assessmentTypeLabel = 'Other';
          break;
      }
    }

    _scoreController.addListener(_updateState);
    _maxScoreController.addListener(_updateState);
    _loadInitialData();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInitialData() async {
    try {
      final profile = await _teacherService.getTeacherProfile();
      final allClasses = await _schoolService.getClasses();

      final teacherAssignedClasses = allClasses.where((sc) {
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

      final activeClasses = teacherAssignedClasses.isNotEmpty ? teacherAssignedClasses : allClasses;

      SchoolClass? defaultClass;
      if (_selectedStudentId != null) {
        defaultClass = activeClasses.firstWhere(
          (c) => c.students.any((s) => s.studentId == _selectedStudentId),
          orElse: () => activeClasses.isNotEmpty ? activeClasses.first : allClasses.first,
        );
      } else if (activeClasses.isNotEmpty) {
        defaultClass = activeClasses.first;
      }

      final suggestedSubjects = _getSubjectsForSelectedClass(defaultClass, profile);

      if (mounted) {
        setState(() {
          _teacherProfile = profile;
          _availableClasses = activeClasses;
          _selectedClassId = defaultClass?.id;
          _classStudents = defaultClass?.students ?? [];
          _teacherSubjects = profile.assignedSubjects;
          if (!_isEditing && suggestedSubjects.isNotEmpty) {
            _subjectController.text = suggestedSubjects.first;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _scoreController.dispose();
    _maxScoreController.dispose();
    _academicYearController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  double get _earned => double.tryParse(_scoreController.text.trim()) ?? 0;
  double get _max => (double.tryParse(_maxScoreController.text.trim()) ?? 100) > 0
      ? (double.tryParse(_maxScoreController.text.trim()) ?? 100)
      : 100;
  double get _percentage => (_earned / _max) * 100;

  AssessmentType get _mappedType {
    switch (_assessmentTypeLabel) {
      case 'Quiz':
        return AssessmentType.quiz;
      case 'Midterm':
        return AssessmentType.midterm;
      case 'Final':
        return AssessmentType.finalExam;
      case 'Project':
        return AssessmentType.project;
      case 'Other':
        return AssessmentType.composite;
      case 'Assignment':
      default:
        return AssessmentType.assignment;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student from the class roster.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final studentName = _selectedStudentName ?? 'Student';
      final subject = _subjectController.text.trim();
      final score = _earned;
      final maxScore = _max;
      final term = '$_selectedSemester (${_academicYearController.text.trim()})';
      final comment = _commentController.text.trim();

      if (_isEditing) {
        final updated = GradeEntry(
          id: widget.existingEntry!.id,
          studentId: _selectedStudentId!,
          studentName: studentName,
          subject: subject,
          assessmentType: _mappedType,
          score: score,
          maxScore: maxScore,
          term: term,
          parentRecommendation: comment.isNotEmpty ? comment : null,
          createdAt: widget.existingEntry!.createdAt,
        );
        await _teacherService.updateGradeEntry(updated);
      } else {
        await _teacherService.addGradeEntry(
          studentId: _selectedStudentId!,
          studentName: studentName,
          subject: subject,
          assessmentType: _mappedType,
          score: score,
          maxScore: maxScore,
          term: term,
          parentRecommendation: comment.isNotEmpty ? comment : null,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Grade record updated successfully!' : 'Grade submitted to roster successfully!'),
          backgroundColor: KukieAccent.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save grade: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uniqueClasses = <String, SchoolClass>{};
    for (final c in _availableClasses) {
      if (c.id.isNotEmpty && !uniqueClasses.containsKey(c.id)) {
        uniqueClasses[c.id] = c;
      }
    }
    final deduplicatedClasses = uniqueClasses.values.toList();

    final uniqueStudents = <String, StudentClassInfo>{};
    for (final s in _classStudents) {
      if (s.studentId.isNotEmpty && !uniqueStudents.containsKey(s.studentId)) {
        uniqueStudents[s.studentId] = s;
      }
    }
    final deduplicatedStudents = uniqueStudents.values.toList();

    final validClassId = deduplicatedClasses.any((c) => c.id == _selectedClassId) ? _selectedClassId : null;
    final validStudentId = deduplicatedStudents.any((s) => s.studentId == _selectedStudentId) ? _selectedStudentId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Student Grade' : 'Record Student Grade',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x05000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Select Class *
                      const Text(
                        'Select Class / Cohort *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: validClassId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select teaching class',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: deduplicatedClasses.map((c) {
                          final label = c.displayName.isNotEmpty ? c.displayName : 'Grade ${c.grade}-${c.section}';
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              '$label (${c.students.length} Students)',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (classId) {
                          if (classId != null) {
                            final match = deduplicatedClasses.firstWhere((c) => c.id == classId);
                            final subjs = _getSubjectsForSelectedClass(match, _teacherProfile);
                            setState(() {
                              _selectedClassId = classId;
                              _classStudents = match.students;
                              _selectedStudentId = null;
                              _selectedStudentName = null;
                              if (!_isEditing && subjs.isNotEmpty) {
                                _subjectController.text = subjs.first;
                              }
                            });
                          }
                        },
                        validator: (v) => (v == null || v.isEmpty) ? 'Please select a class' : null,
                      ),
                      const SizedBox(height: 16),

                      // 2. Select Student *
                      const Text(
                        'Select Student *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: validStudentId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: deduplicatedStudents.isEmpty ? 'No students enrolled in class' : 'Select student from roster',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: deduplicatedStudents.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.studentId,
                            child: Text(
                              '${s.studentName} (${s.studentId})',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final match = _classStudents.firstWhere(
                              (s) => s.studentId == val,
                              orElse: () => StudentClassInfo(id: val, studentId: val, studentName: 'Student', classId: ''),
                            );
                            setState(() {
                              _selectedStudentId = val;
                              _selectedStudentName = match.studentName;
                            });
                          }
                        },
                        validator: (v) => (v == null || v.isEmpty) ? 'Please select a student' : null,
                      ),
                      const SizedBox(height: 16),

                      // 3. Subject *
                      const Text(
                        'Subject *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Physics, Maths',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
                      ),
                      Builder(builder: (context) {
                        final selectedClassObj = deduplicatedClasses.firstWhere(
                          (c) => c.id == validClassId,
                          orElse: () => deduplicatedClasses.isNotEmpty ? deduplicatedClasses.first : const SchoolClass(id: '', grade: 0, section: ''),
                        );
                        final availableSubjs = _getSubjectsForSelectedClass(selectedClassObj, _teacherProfile);

                        if (availableSubjs.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: availableSubjs.map((subj) {
                                final isSel = _subjectController.text.trim().toLowerCase() == subj.trim().toLowerCase();
                                return InkWell(
                                  onTap: () => setState(() => _subjectController.text = subj),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isSel ? KukieAccent.violetTint : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSel ? KukieAccent.violet : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      subj,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                        color: isSel ? KukieAccent.violet : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),

                      // 4. Assessment Type Pills
                      const Text(
                        'Assessment Type',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _assessmentTypes.map((type) {
                            final isSelected = _assessmentTypeLabel == type['label'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => setState(() => _assessmentTypeLabel = type['label']!),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? KukieAccent.violet : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? KukieAccent.violet : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    type['label']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Score Obtained * & Maximum Score *
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Score Obtained *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _scoreController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '85',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Invalid' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maximum Score *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _maxScoreController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '100',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  validator: (v) => (v == null || (double.tryParse(v.trim()) ?? 0) <= 0) ? 'Invalid' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // 6. Resulting Grade Evaluation (100% Scale Indicator)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBAE6FD)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Resulting Grade Evaluation',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                ),
                                Text(
                                  '${_percentage.toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _max == 100 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                  size: 14,
                                  color: _max == 100 ? Colors.green.shade700 : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _max == 100
                                        ? '✓ Evaluated out of 100% — Final score ready for class roster submission.'
                                        : 'Current Score: ${_earned.toStringAsFixed(0)} / ${_max.toStringAsFixed(0)} pts (${_percentage.toStringAsFixed(0)}% equivalent out of 100)',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _max == 100 ? Colors.green.shade800 : const Color(0xFF0369A1)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 7. Semester Choice & Academic Year
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Semester *',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedSemester,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: '1st Semester', child: Text('1st Semester', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                    DropdownMenuItem(value: '2nd Semester', child: Text('2nd Semester', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedSemester = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Academic Year',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _academicYearController,
                                  decoration: InputDecoration(
                                    hintText: '2026-2027',
                                    filled: true,
                                    fillColor: const Color(0xFFF8FAFC),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 8. Teacher Feedback / Comment
                      const Text(
                        'Teacher Feedback / Comment',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'e.g. Excellent problem solving on quadratic equations.',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 9. Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _submitting ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Cancel', style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: KukieAccent.violet,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _submitting
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                      _isEditing ? 'Update Grade' : 'Submit Grade',
                                      style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
