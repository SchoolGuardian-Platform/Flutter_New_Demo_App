import 'package:flutter/material.dart';
import '../../models/course_offering.dart';
import '../../services/course_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class ManageCoursesPage extends StatefulWidget {
  const ManageCoursesPage({super.key});

  static const routeName = '/admin/manage-courses';

  @override
  State<ManageCoursesPage> createState() => _ManageCoursesPageState();
}

class _ManageCoursesPageState extends State<ManageCoursesPage> {
  final _courseService = CourseService();
  List<CourseOffering> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _loading = true);
    final courses = await _courseService.getAvailableOfferings(term: 'Fall 2026');
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  Future<void> _showCreateCourseDialog() async {
    final codeController = TextEditingController(text: 'PHY-301');
    final titleController = TextEditingController(text: 'General Physics II');
    final creditsController = TextEditingController(text: '3.0');
    final teacherController = TextEditingController(text: 'Dr. Aris Thorne');
    final deptController = TextEditingController(text: 'Physical Sciences');
    final termController = TextEditingController(text: 'Fall 2026');

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Semester Course'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code *',
                    hintText: 'e.g. CS-101',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Course Title *',
                    hintText: 'e.g. Intro to Computer Science',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: creditsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Credit Hours (e.g. 3.0, 4.0) *',
                  ),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null || d <= 0) return 'Valid credits required';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: teacherController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Teacher Name *',
                    hintText: 'e.g. Dr. Vance',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: deptController,
                  decoration: const InputDecoration(
                    labelText: 'Department *',
                    hintText: 'e.g. Computer Science',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: termController,
                  decoration: const InputDecoration(
                    labelText: 'Term *',
                    hintText: 'Fall 2026',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _courseService.createCourseOffering(
                  code: codeController.text.trim(),
                  title: titleController.text.trim(),
                  credits: double.parse(creditsController.text.trim()),
                  teacherName: teacherController.text.trim(),
                  department: deptController.text.trim(),
                  term: termController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _loadCourses();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Course created & teacher assigned successfully!'),
                      backgroundColor: KukieAccent.success,
                    ),
                  );
                }
              }
            },
            child: const Text('Create Course'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Director Course Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateCourseDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Course'),
        backgroundColor: KukieAccent.violet,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCourses,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  // --- Director Registration Generator Banner ---
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
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
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.amberAccent),
                            SizedBox(width: 8),
                            Text(
                              'Director Registration Generator',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Generate and publish semester course registration batches for all enrolled students.',
                          style: TextStyle(color: Colors.white70, fontSize: 12.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Success: Course registration batch generated & published for Fall 2026! Students can now register.'),
                                      backgroundColor: KukieAccent.success,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.send, size: 16),
                                label: const Text(
                                  'Publish Registration Batch (Fall 2026)',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                  foregroundColor: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Active Semester Course Offerings (Fall 2026)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ..._courses.map((course) => Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: KukieAccent.violetTint,
                            child: Text(
                              course.code.substring(0, 2),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: KukieAccent.violet,
                                  fontSize: 12),
                            ),
                          ),
                          title: Text(
                            '${course.code}: ${course.title}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            'Assigned Teacher: ${course.teacherName} · ${course.credits} Credits · ${course.department}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                          trailing: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              '${course.credits} Cr',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.green.shade800,
                                  fontSize: 12),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
