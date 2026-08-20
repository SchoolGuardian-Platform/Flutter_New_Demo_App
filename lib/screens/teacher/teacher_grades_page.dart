import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/grade.dart';
import '../../services/grade_service.dart';
import '../../theme/app_theme.dart';

/// Teacher Grades screen — `GET /grades/teacher`,
/// `POST /grades`, `PATCH /grades/:id`, `DELETE /grades/:id`.
///
/// Shows all grades created by the logged-in teacher and allows full CRUD.
class TeacherGradesPage extends StatefulWidget {
  const TeacherGradesPage({super.key});

  static const routeName = '/teacher/grades';

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  final _service = GradeService();
  List<Grade>? _grades;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final grades = await _service.getGradesByTeacher();
      if (mounted) setState(() => _grades = grades);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load grades.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateDialog() async {
    final studentIdCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final maxScoreCtrl = TextEditingController(text: '100');
    final termCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    var selectedType = AssessmentType.exam;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Grade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student ID (UUID)',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AssessmentType>(
                  // ignore: deprecated_member_use
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Assessment Type'),
                  items: AssessmentType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Score'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Max Score'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Term (optional, e.g. "Term 1")'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Comment (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final score = double.tryParse(scoreCtrl.text.trim());
    final maxScore = double.tryParse(maxScoreCtrl.text.trim());
    if (score == null || maxScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score and Max Score must be valid numbers.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await _service.createGrade(
        studentId: studentIdCtrl.text.trim(),
        subject: subjectCtrl.text.trim(),
        assessmentType: selectedType,
        score: score,
        maxScore: maxScore,
        term: termCtrl.text.trim().isEmpty ? null : termCtrl.text.trim(),
        comment:
            commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grade recorded.')),
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _showEditDialog(Grade grade) async {
    final subjectCtrl = TextEditingController(text: grade.subject);
    final scoreCtrl =
        TextEditingController(text: grade.score.toString());
    final maxScoreCtrl =
        TextEditingController(text: grade.maxScore.toString());
    final termCtrl = TextEditingController(text: grade.term ?? '');
    final commentCtrl =
        TextEditingController(text: grade.comment ?? '');
    var selectedType = grade.assessmentType;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Grade'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Subject'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AssessmentType>(
                  // ignore: deprecated_member_use
                  value: selectedType,
                  decoration:
                      const InputDecoration(labelText: 'Assessment Type'),
                  items: AssessmentType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: scoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Score'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxScoreCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Max Score'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Term (optional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Comment (optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final score = double.tryParse(scoreCtrl.text.trim());
    final maxScore = double.tryParse(maxScoreCtrl.text.trim());
    if (score == null || maxScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Score and Max Score must be valid numbers.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await _service.updateGrade(
        grade.id,
        subject: subjectCtrl.text.trim(),
        assessmentType: selectedType,
        score: score,
        maxScore: maxScore,
        term: termCtrl.text.trim(),
        comment: commentCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Grade updated.')));
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _confirmDelete(Grade grade) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Grade?'),
        content: Text(
          'Remove ${grade.assessmentType.label} for ${grade.subject}? '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteGrade(grade.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Grades')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Grade'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style:
                              const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _grades!.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'No grades yet.\nTap + to add a grade.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.all(AppSpacing.md),
                          itemCount: _grades!.length,
                          itemBuilder: (_, i) {
                            final g = _grades![i];
                            final pct =
                                g.percentage.toStringAsFixed(1);
                            return Card(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      AppColors.primaryFixed,
                                  child: Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  g.subject,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${g.assessmentType.label} — '
                                      '${g.score}/${g.maxScore}',
                                    ),
                                    if (g.term != null)
                                      Text(g.term!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall),
                                    Text(
                                      'Student: ${g.studentId.substring(0, 8)}…',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 18),
                                      tooltip: 'Edit',
                                      onPressed: () =>
                                          _showEditDialog(g),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 18,
                                          color: AppColors.error),
                                      tooltip: 'Delete',
                                      onPressed: () =>
                                          _confirmDelete(g),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
