import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
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
        scoreController = TextEditingController(text: score.toStringAsFixed(0)),
        maxScoreController = TextEditingController(text: maxScore.toStringAsFixed(0));

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

    _studentIdController = TextEditingController(text: entry?.studentId ?? 'STU-1001');
    _studentNameController = TextEditingController(text: entry?.studentName ?? 'Alexander Hayes');
    _subjectController = TextEditingController(text: entry?.subject ?? 'Advanced Mathematics');
    _termController = TextEditingController(text: entry?.term ?? 'Fall 2026');
    _recommendationController = TextEditingController(text: entry?.parentRecommendation ?? '');

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

  void _loadStandardPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Attendance', score: 7, maxScore: 10);
    _addComponentRow(name: 'Midterm Exam', score: 27, maxScore: 30);
    _addComponentRow(name: 'Assignments', score: 9, maxScore: 10);
    _addComponentRow(name: 'Final Exam', score: 48, maxScore: 50);
  }

  void _loadProjectPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Attendance', score: 9, maxScore: 10);
    _addComponentRow(name: 'Project & Practical', score: 18, maxScore: 20);
    _addComponentRow(name: 'Midterm Exam', score: 25, maxScore: 30);
    _addComponentRow(name: 'Final Exam', score: 38, maxScore: 40);
  }

  void _loadMidtermFinalPreset() {
    _clearComponentRows();
    _addComponentRow(name: 'Midterm Exam', score: 42, maxScore: 50);
    _addComponentRow(name: 'Final Exam', score: 46, maxScore: 50);
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
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Student ID *',
                  hintText: 'e.g. STU-1001',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Student ID is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Student Full Name *',
                  hintText: 'e.g. Alexander Hayes',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Student name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject / Course *',
                        hintText: 'e.g. Advanced Mathematics',
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Subject is required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _termController,
                      decoration: const InputDecoration(
                        labelText: 'Academic Term *',
                        hintText: 'Fall 2026',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Term is required' : null,
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
                    name: 'Quiz / Task', score: 8, maxScore: 10),
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
                            'Write professional feedback for the parents (e.g. "Alexander understands calculus well but needs 15 mins daily practice at home on quadratic equations.")',
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
                onPressed: _submitting ? null : _submit,
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
