import 'package:flutter/material.dart';
import '../../models/grade_entry.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class AddGradePage extends StatefulWidget {
  const AddGradePage({super.key});

  static const routeName = '/teacher/add-grade';

  @override
  State<AddGradePage> createState() => _AddGradePageState();
}

class _AddGradePageState extends State<AddGradePage> {
  final _formKey = GlobalKey<FormState>();
  final _teacherService = TeacherService();

  final _studentIdController = TextEditingController(text: 'STU-1001');
  final _studentNameController = TextEditingController(text: 'Alexander Hayes');
  final _subjectController = TextEditingController(text: 'Advanced Mathematics');
  final _termController = TextEditingController(text: 'Fall 2026');

  // Component Marks out of 100 total
  final _attendanceController = TextEditingController(text: '7');  // out of 10
  final _midtermController = TextEditingController(text: '27');    // out of 30
  final _assignmentController = TextEditingController(text: '9');   // out of 10
  final _finalController = TextEditingController(text: '48');        // out of 50

  final _recommendationController = TextEditingController();

  AssessmentType _assessmentType = AssessmentType.composite;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _attendanceController.addListener(_updateSummation);
    _midtermController.addListener(_updateSummation);
    _assignmentController.addListener(_updateSummation);
    _finalController.addListener(_updateSummation);
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
    _attendanceController.dispose();
    _midtermController.dispose();
    _assignmentController.dispose();
    _finalController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  double get _totalSum {
    final att = double.tryParse(_attendanceController.text.trim()) ?? 0;
    final mid = double.tryParse(_midtermController.text.trim()) ?? 0;
    final ass = double.tryParse(_assignmentController.text.trim()) ?? 0;
    final fin = double.tryParse(_finalController.text.trim()) ?? 0;
    return att + mid + ass + fin;
  }

  String get _computedGrade {
    final total = _totalSum;
    if (total >= 90) return 'A';
    if (total >= 80) return 'B';
    if (total >= 70) return 'C';
    if (total >= 60) return 'D';
    return 'F';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final attendance = double.tryParse(_attendanceController.text.trim()) ?? 0;
      final midterm = double.tryParse(_midtermController.text.trim()) ?? 0;
      final assignment = double.tryParse(_assignmentController.text.trim()) ?? 0;
      final finalScore = double.tryParse(_finalController.text.trim()) ?? 0;

      final totalScore = attendance + midterm + assignment + finalScore;

      await _teacherService.addGradeEntry(
        studentId: _studentIdController.text.trim(),
        studentName: _studentNameController.text.trim(),
        subject: _subjectController.text.trim(),
        assessmentType: _assessmentType,
        score: totalScore,
        maxScore: 100.0,
        term: _termController.text.trim(),
        attendanceScore: attendance,
        midtermScore: midterm,
        assignmentScore: assignment,
        finalScore: finalScore,
        parentRecommendation: _recommendationController.text.trim().isNotEmpty
            ? _recommendationController.text.trim()
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Grade (${totalScore.toStringAsFixed(0)}/100 · $_computedGrade) & confidential recommendation saved!'),
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
    final total = _totalSum;
    final letterGrade = _computedGrade;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Composite Assessment'),
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
                    const Icon(Icons.school, color: KukieAccent.violet),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Input component marks out of 100 (Attendance 10, Midterm 30, Assignments 10, Final 50). The API will automatically sum the total.',
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
                'Student & Course Information',
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
              TextFormField(
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
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _termController,
                decoration: const InputDecoration(
                  labelText: 'Term / Academic Period *',
                  hintText: 'Fall 2026',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Term is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Assessment Component Breakdown (Out of 100 Total)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _attendanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Attendance (/10)',
                        hintText: '7',
                        prefixIcon: Icon(Icons.event_available),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0 || val > 10) return '0-10';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _midtermController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Midterm (/30)',
                        hintText: '27',
                        prefixIcon: Icon(Icons.assignment),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0 || val > 30) return '0-30';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _assignmentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Assignments (/10)',
                        hintText: '9',
                        prefixIcon: Icon(Icons.task),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0 || val > 10) return '0-10';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _finalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Final Exam (/50)',
                        hintText: '48',
                        prefixIcon: Icon(Icons.grade),
                      ),
                      validator: (v) {
                        final val = double.tryParse(v ?? '');
                        if (val == null || val < 0 || val > 50) return '0-50';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
                          '${total.toStringAsFixed(0)} / 100 Marks',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
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
                    : const Icon(Icons.check),
                label: Text('Save Total Score (${total.toStringAsFixed(0)}/100) & Guidance'),
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
