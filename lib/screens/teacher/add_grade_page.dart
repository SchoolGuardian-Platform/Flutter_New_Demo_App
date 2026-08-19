import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../models/school_class.dart';
import '../../services/school_management_service.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class AddGradePage extends StatefulWidget {
  const AddGradePage({super.key, this.existingEntry});

  static const routeName = '/teacher/add-grade';
  final GradeEntry? existingEntry;

  @override
  State<AddGradePage> createState() => _AddGradePageState();
}

class _ComponentInputRow {
  _ComponentInputRow({
    required String name,
    required double score,
    required double maxScore,
  })  : nameController = TextEditingController(text: name),
        scoreController = TextEditingController(text: score > 0 ? score.toStringAsFixed(0) : ''),
        maxScoreController = TextEditingController(text: maxScore > 0 ? maxScore.toStringAsFixed(0) : '');

  final TextEditingController nameController;
  final TextEditingController scoreController;
  final TextEditingController maxScoreController;

  void dispose() {
    nameController.dispose();
    scoreController.dispose();
    maxScoreController.dispose();
  }
}

class _AddGradePageState extends State<AddGradePage> {
  final _formKey = GlobalKey<FormState>();
  final _teacherService = TeacherService();

  late final TextEditingController _studentIdController;
  late final TextEditingController _studentNameController;
  late final TextEditingController _subjectController;
  late final TextEditingController _termController;
  late final TextEditingController _recommendationController;

  final List<_ComponentInputRow> _componentRows = [];

  AssessmentType _assessmentType = AssessmentType.composite;
  bool _submitting = false;

  List<String> _teacherSubjects = [];
  String _selectedYear = '2025/2026';
  String _selectedSemester = 'Semester 1';

  List<SchoolClass> _assignedClasses = [];
  SchoolClass? _selectedClass;
  bool _isTeacherAssigned = true;

  final Map<String, String> _knownStudents = {};

  bool get _isEditing => widget.existingEntry != null;

  static const List<Map<String, dynamic>> _presetAssessments = [
    {'name': 'Attendance & Participation', 'defaultMax': 10.0},
    {'name': 'Midterm Exam', 'defaultMax': 30.0},
    {'name': 'Assignments & Tasks', 'defaultMax': 10.0},
    {'name': 'Final Exam', 'defaultMax': 50.0},
    {'name': 'Project & Practical', 'defaultMax': 20.0},
    {'name': 'Quizzes & Short Tests', 'defaultMax': 10.0},
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;

    if (entry != null && entry.term.isNotEmpty) {
      if (entry.term.contains('Semester 2')) {
        _selectedSemester = 'Semester 2';
      } else {
        _selectedSemester = 'Semester 1';
      }
      final parts = entry.term.split(' - ');
      if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
        final candidateYear = parts[0].trim();
        if (['2024/2025', '2025/2026', '2026/2027', '2027/2028'].contains(candidateYear)) {
          _selectedYear = candidateYear;
        }
      }
    }

    final initialTerm = '$_selectedYear - $_selectedSemester';

    _studentIdController = TextEditingController(text: entry?.studentId ?? '');
    _studentNameController = TextEditingController(text: entry?.studentName ?? '');
    _subjectController = TextEditingController(text: entry?.subject ?? '');
    _termController = TextEditingController(text: entry?.term.isNotEmpty == true ? entry!.term : initialTerm);
    _recommendationController = TextEditingController(text: entry?.parentRecommendation ?? '');

    _studentIdController.addListener(_onStudentIdChanged);
    _loadTeacherSubjectsAndStudents();

    if (entry != null) {
      _assessmentType = entry.assessmentType;
      final active = entry.activeComponents;
      if (active.isNotEmpty) {
        for (final c in active) {
          _addComponentRow(name: c.name, score: c.score, maxScore: c.maxScore);
        }
      } else {
        _loadStandardPreset();
      }
    } else {
      _loadStandardPreset();
    }
  }

  Future<void> _loadTeacherSubjectsAndStudents() async {
    final profile = await _teacherService.getTeacherProfile();
    final subjectList = List<String>.from(profile.assignedSubjects);

    try {
      final dbSubjects = await SchoolManagementService().getSubjects();
      for (final s in dbSubjects) {
        if (s.name.isNotEmpty && !subjectList.contains(s.name)) {
          subjectList.add(s.name);
        }
      }
    } catch (_) {}

    List<SchoolClass> allSchoolClasses = [];
    try {
      allSchoolClasses = await SchoolManagementService().getClasses();
    } catch (_) {}

    // Filter classes to ONLY those where this teacher is explicitly assigned by the Admin
    final teacherAssignedClasses = allSchoolClasses.where((sc) {
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
        _teacherSubjects = subjectList;
        _assignedClasses = teacherAssignedClasses;
        _isTeacherAssigned = teacherAssignedClasses.isNotEmpty;
        if (teacherAssignedClasses.isNotEmpty && _selectedClass == null) {
          _selectedClass = teacherAssignedClasses.first;
        } else if (teacherAssignedClasses.isEmpty) {
          _selectedClass = null;
        }
        _updateKnownStudents();
      });

      _onStudentIdChanged();
    }
  }

  void _updateKnownStudents() {
    _knownStudents.clear();
    if (_selectedClass != null) {
      for (final s in _selectedClass!.students) {
        if (s.studentId.isNotEmpty) {
          _knownStudents[s.studentId.trim().toUpperCase()] = s.studentName;
        }
        final code = s.studentCode;
        if (code != null && code.isNotEmpty) {
          _knownStudents[code.trim().toUpperCase()] = s.studentName;
        }
      }
    }
  }

  void _onStudentIdChanged() {
    final query = _studentIdController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    if (_knownStudents.containsKey(query)) {
      final matchedName = _knownStudents[query]!;
      if (_studentNameController.text.trim() != matchedName) {
        _studentNameController.text = matchedName;
      }
    }
  }

  void _updateTermText() {
    _termController.text = '$_selectedYear - $_selectedSemester';
  }

  void _loadStandardPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Attendance', score: 0, maxScore: 10);
    _addComponentRow(name: 'Midterm Exam', score: 0, maxScore: 30);
    _addComponentRow(name: 'Assignments', score: 0, maxScore: 10);
    _addComponentRow(name: 'Final Exam', score: 0, maxScore: 50);
  }

  void _loadProjectPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Attendance', score: 0, maxScore: 10);
    _addComponentRow(name: 'Project & Practical', score: 0, maxScore: 20);
    _addComponentRow(name: 'Midterm Exam', score: 0, maxScore: 30);
    _addComponentRow(name: 'Final Exam', score: 0, maxScore: 40);
  }

  void _loadMidtermFinalPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Midterm Exam', score: 0, maxScore: 50);
    _addComponentRow(name: 'Final Exam', score: 0, maxScore: 50);
  }

  void _clearComponentRows() {
    for (final row in _componentRows) {
      row.dispose();
    }
    setState(() => _componentRows.clear());
  }

  void _addComponentRow({required String name, required double score, required double maxScore}) {
    final row = _ComponentInputRow(name: name, score: score, maxScore: maxScore);
    row.scoreController.addListener(_updateSummation);
    row.maxScoreController.addListener(_updateSummation);
    row.nameController.addListener(_updateSummation);
    setState(() => _componentRows.add(row));
  }

  void _removeComponentRow(int index) {
    if (_componentRows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one assessment section is required.')),
      );
      return;
    }
    final row = _componentRows.removeAt(index);
    row.dispose();
    setState(() {});
  }

  void _updateSummation() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentNameController.dispose();
    _subjectController.dispose();
    _termController.dispose();
    _recommendationController.dispose();
    for (final row in _componentRows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _totalEarned {
    double total = 0;
    for (final row in _componentRows) {
      total += double.tryParse(row.scoreController.text.trim()) ?? 0;
    }
    return total;
  }

  double get _totalMax {
    double total = 0;
    for (final row in _componentRows) {
      total += double.tryParse(row.maxScoreController.text.trim()) ?? 0;
    }
    return total > 0 ? total : 100;
  }

  double get _percentage => (_totalEarned / _totalMax) * 100;

  String get _computedGrade {
    final p = _percentage;
    if (p >= 90) return 'A+';
    if (p >= 85) return 'A';
    if (p >= 80) return 'A-';
    if (p >= 75) return 'B+';
    if (p >= 70) return 'B';
    if (p >= 65) return 'B-';
    if (p >= 60) return 'C+';
    if (p >= 50) return 'C';
    if (p >= 45) return 'C-';
    if (p >= 40) return 'D';
    return 'F';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isTeacherAssigned || _selectedClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Restricted: You are not assigned to any class by the administrator.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final inputId = _studentIdController.text.trim().toUpperCase();
    final isStudentInSelectedClass = _selectedClass!.students.any((s) =>
        s.studentId.trim().toUpperCase() == inputId ||
        (s.studentCode != null && s.studentCode!.trim().toUpperCase() == inputId));

    if (!isStudentInSelectedClass && _selectedClass!.students.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access Restricted: Student "$inputId" is NOT enrolled in ${_selectedClass!.displayName}. You can only add results for students in your assigned class.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final components = <AssessmentComponent>[];
      for (final row in _componentRows) {
        final name = row.nameController.text.trim().isNotEmpty
            ? row.nameController.text.trim()
            : 'Assessment';
        final score = double.tryParse(row.scoreController.text.trim()) ?? 0;
        final maxScore = double.tryParse(row.maxScoreController.text.trim()) ?? 10;
        components.add(AssessmentComponent(name: name, score: score, maxScore: maxScore));
      }

      final totalScore = _totalEarned;
      final maxScoreTotal = _totalMax;

      if (_isEditing) {
        final updated = GradeEntry(
          id: widget.existingEntry!.id,
          studentId: _studentIdController.text.trim(),
          studentName: _studentNameController.text.trim(),
          subject: _subjectController.text.trim(),
          assessmentType: _assessmentType,
          score: totalScore,
          maxScore: maxScoreTotal,
          term: _termController.text.trim(),
          components: components,
          parentRecommendation: _recommendationController.text.trim().isNotEmpty
              ? _recommendationController.text.trim()
              : null,
          createdAt: widget.existingEntry!.createdAt,
        );
        await _teacherService.updateGradeEntry(updated);
      } else {
        await _teacherService.addGradeEntry(
          studentId: _studentIdController.text.trim(),
          studentName: _studentNameController.text.trim(),
          subject: _subjectController.text.trim(),
          assessmentType: _assessmentType,
          score: totalScore,
          maxScore: maxScoreTotal,
          term: _termController.text.trim(),
          components: components,
          parentRecommendation: _recommendationController.text.trim().isNotEmpty
              ? _recommendationController.text.trim()
              : null,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Student record updated (${totalScore.toStringAsFixed(0)}/${maxScoreTotal.toStringAsFixed(0)} · $_computedGrade)!'
              : 'New assessment saved (${totalScore.toStringAsFixed(0)}/${maxScoreTotal.toStringAsFixed(0)} · $_computedGrade)!'),
          backgroundColor: KukieAccent.success,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save grade: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final earned = _totalEarned;
    final maxTotal = _totalMax;
    final letterGrade = _computedGrade;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student Grade & Guidance' : 'Manage Student Assessments'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Icon(_isEditing ? Icons.edit_note : Icons.tune, color: KukieAccent.violet),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Choose any assessment sections (Midterm, Attendance, Project, Quiz, Final) and enter scores. Total score is calculated automatically.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: KukieAccent.ink,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Student & Course Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!_isTeacherAssigned) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_person_outlined, color: Colors.amber.shade900, size: 26),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Class Access Restricted',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'The Admin has not assigned you to any class yet. You cannot search students or record grades until an Admin assigns you to a class.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              DropdownButtonFormField<SchoolClass>(
                initialValue: _selectedClass,
                isExpanded: true,
                isDense: true,
                borderRadius: BorderRadius.circular(12),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KukieAccent.violet, size: 20),
                decoration: InputDecoration(
                  labelText: 'Assigned Class / Section *',
                  hintText: 'Select assigned class',
                  prefixIcon: const Icon(Icons.class_outlined, size: 18),
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                items: _assignedClasses.map((sc) {
                  return DropdownMenuItem<SchoolClass>(
                    value: sc,
                    child: Text(
                      '${sc.displayName} (${sc.students.length} students)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: !_isTeacherAssigned
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedClass = val;
                            _updateKnownStudents();
                            _studentIdController.clear();
                            _studentNameController.clear();
                          });
                        }
                      },
                validator: (v) => (v == null && _isTeacherAssigned) ? 'Please select an assigned class' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _studentIdController,
                enabled: _isTeacherAssigned,
                decoration: InputDecoration(
                  labelText: 'Student ID * (Type or Select)',
                  hintText: 'e.g. SG-2026-000001',
                  prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  suffixIcon: PopupMenuButton<String>(
                    enabled: _isTeacherAssigned,
                    icon: const Icon(Icons.person_search_outlined, color: KukieAccent.violet, size: 20),
                    tooltip: 'Select registered student from class',
                    onSelected: (id) {
                      if (id != '__EMPTY__') {
                        _studentIdController.text = id;
                        _onStudentIdChanged();
                      }
                    },
                    itemBuilder: (context) {
                      if (!_isTeacherAssigned) {
                        return [
                          const PopupMenuItem<String>(
                            value: '__EMPTY__',
                            enabled: false,
                            child: Text(
                              'Admin must assign you to a class first',
                              style: TextStyle(fontSize: 12, color: Colors.amber),
                            ),
                          ),
                        ];
                      }
                      if (_knownStudents.isEmpty) {
                        return [
                          const PopupMenuItem<String>(
                            value: '__EMPTY__',
                            enabled: false,
                            child: Text(
                              'No registered students in this class',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ];
                      }
                      return [
                        for (final entry in _knownStudents.entries)
                          PopupMenuItem<String>(
                            value: entry.key,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, size: 16, color: KukieAccent.violet),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${entry.key} · ${entry.value}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ];
                    },
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Student ID is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _studentNameController,
                enabled: _isTeacherAssigned,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name * (Auto-filled on ID match)',
                  hintText: 'e.g. Abebe Bikila',
                  prefixIcon: Icon(Icons.person_outline, size: 18),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Student name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _subjectController,
                    enabled: _isTeacherAssigned,
                    decoration: const InputDecoration(
                      labelText: 'Subject / Course *',
                      hintText: 'e.g. Mathematics',
                      prefixIcon: Icon(Icons.book_outlined, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Subject is required'
                        : null,
                  ),
                  if (_teacherSubjects.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Suggest from your assigned teaching subjects:',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _teacherSubjects.map((subject) {
                        final isSelected = _subjectController.text.trim().toLowerCase() ==
                            subject.trim().toLowerCase();
                        return ChoiceChip(
                          label: Text(
                            subject,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? KukieAccent.violet : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: !_isTeacherAssigned
                              ? null
                              : (selected) {
                                  if (selected) {
                                    setState(() {
                                      _subjectController.text = subject;
                                    });
                                  }
                                },
                          selectedColor: KukieAccent.violetTint,
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedYear,
                      isExpanded: true,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KukieAccent.violet, size: 20),
                      decoration: InputDecoration(
                        labelText: 'Academic Year *',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: '2024/2025', child: Text('2024/2025', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: '2025/2026', child: Text('2025/2026', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: '2026/2027', child: Text('2026/2027', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: '2027/2028', child: Text('2027/2028', style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: !_isTeacherAssigned
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedYear = val;
                                  _updateTermText();
                                });
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSemester,
                      isExpanded: true,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      dropdownColor: Colors.white,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: KukieAccent.violet, size: 20),
                      decoration: InputDecoration(
                        labelText: 'Semester *',
                        prefixIcon: const Icon(Icons.school_outlined, size: 18),
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Semester 1', child: Text('Semester 1', style: TextStyle(fontSize: 12.5))),
                        DropdownMenuItem(value: 'Semester 2', child: Text('Semester 2', style: TextStyle(fontSize: 12.5))),
                      ],
                      onChanged: !_isTeacherAssigned
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedSemester = val;
                                  _updateTermText();
                                });
                              }
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Preset Shortcuts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assessment Sections',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  PopupMenuButton<VoidCallback>(
                    onSelected: (action) => action(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: KukieAccent.violetTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.flash_on, size: 14, color: KukieAccent.violet),
                          SizedBox(width: 4),
                          Text('Presets',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: KukieAccent.violet)),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _loadStandardPreset,
                        child: const Text('Standard (Att + Mid + Assig + Final)'),
                      ),
                      PopupMenuItem(
                        value: _loadProjectPreset,
                        child: const Text('Project Emphasis (Att + Proj + Mid + Final)'),
                      ),
                      PopupMenuItem(
                        value: _loadMidtermFinalPreset,
                        child: const Text('Exams Only (Midterm 50 + Final 50)'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Dynamic Section Rows
              ...List.generate(_componentRows.length, (index) {
                final row = _componentRows[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PopupMenuButton<String>(
                                initialValue: row.nameController.text,
                                onSelected: (val) {
                                  row.nameController.text = val;
                                  // Update default max score if known
                                  final found = _presetAssessments.firstWhere(
                                      (p) => p['name'] == val,
                                      orElse: () => {});
                                  if (found.isNotEmpty) {
                                    row.maxScoreController.text =
                                        (found['defaultMax'] as double)
                                            .toStringAsFixed(0);
                                  }
                                  _updateSummation();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        row.nameController.text.isNotEmpty
                                            ? row.nameController.text
                                            : 'Select Assessment',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5),
                                      ),
                                      const Icon(Icons.arrow_drop_down, size: 18),
                                    ],
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  for (final preset in _presetAssessments)
                                    PopupMenuItem(
                                      value: preset['name'] as String,
                                      child: Text(preset['name'] as String),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 20),
                              onPressed: () => _removeComponentRow(index),
                              tooltip: 'Remove section',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: row.scoreController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Score Earned *',
                                  hintText: 'e.g. 27',
                                  prefixIcon: Icon(Icons.check_circle_outline),
                                ),
                                validator: (v) {
                                  final score = double.tryParse(v ?? '');
                                  if (score == null || score < 0) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextFormField(
                                controller: row.maxScoreController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Max Score *',
                                  hintText: 'e.g. 30',
                                  prefixIcon: Icon(Icons.score),
                                ),
                                validator: (v) {
                                  final maxScore = double.tryParse(v ?? '');
                                  if (maxScore == null || maxScore <= 0) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: () => _addComponentRow(
                    name: 'Quiz / Task', score: 0, maxScore: 10),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Custom Assessment Section'),
              ),
              const SizedBox(height: AppSpacing.lg),
              // --- Live Automatic Summation Box ---
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [KukieAccent.violet, KukieAccent.violet.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Automatic Total Summation',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${earned.toStringAsFixed(0)} / ${maxTotal.toStringAsFixed(0)} Marks',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Overall: ${_percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Grade $letterGrade',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              // --- Confidential Parent Recommendation Box ---
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_person_outlined,
                            color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Teacher Recommendation (Parents Only)',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🔒 PRIVACY GUARANTEE: This note will be visible exclusively to the student\'s parents/guardians and will NOT be shown to the student.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.amber.shade900.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _recommendationController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Write professional feedback for the parents (e.g. "Student understands concepts well but needs 15 mins daily practice at home.")',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: (_submitting || !_isTeacherAssigned) ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(_isEditing ? Icons.save_outlined : Icons.check),
                label: Text(_isEditing
                    ? 'Update Student Record (${earned.toStringAsFixed(0)}/${maxTotal.toStringAsFixed(0)})'
                    : 'Save Student Mark (${earned.toStringAsFixed(0)}/${maxTotal.toStringAsFixed(0)}) & Guidance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
