import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../grades/parent_grades_page.dart';
import '../reports/academic_report_page.dart';

class LinkedStudentsPage extends StatefulWidget {
  const LinkedStudentsPage({super.key});

  static const routeName = '/parent/linked-students';

  @override
  State<LinkedStudentsPage> createState() => _LinkedStudentsPageState();
}

class _LinkedStudentsPageState extends State<LinkedStudentsPage> {
  final List<Map<String, String>> _students = [
    {
      'id': 'STU-1001',
      'name': 'Alexander Hayes',
      'gradeLevel': 'Grade 10',
      'major': 'Computer Science & STEM',
      'schoolCode': 'SCH-2026',
      'relationship': 'MOTHER',
      'status': 'VERIFIED & ACTIVE',
      'gpa': '3.84 / 4.0',
    },
  ];

  Future<void> _showAddStudentDialog() async {
    final studentIdController = TextEditingController(text: 'STU-1002');
    final nameController = TextEditingController(text: 'Sophia Hayes');
    String selectedRelation = 'MOTHER';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Link Another Child / Student'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your child\'s Student ID to send a linking request to school administration.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black87),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: studentIdController,
                    decoration: const InputDecoration(
                      labelText: 'Student ID *',
                      hintText: 'e.g. STU-1002',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Child Full Name *',
                      hintText: 'e.g. Sophia Hayes',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedRelation,
                    decoration: const InputDecoration(labelText: 'Relationship Type'),
                    items: const [
                      DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                      DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                      DropdownMenuItem(value: 'GUARDIAN', child: Text('Legal Guardian')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Sponsor')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRelation = val);
                    },
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final sId = studentIdController.text.trim();
                  final name = nameController.text.trim();
                  setState(() {
                    _students.add({
                      'id': sId,
                      'name': name,
                      'gradeLevel': 'Grade 9',
                      'major': 'General STEM',
                      'schoolCode': 'SCH-2026',
                      'relationship': selectedRelation,
                      'status': 'PENDING APPROVAL',
                      'gpa': '3.50 / 4.0',
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Relationship verification request submitted for $name ($sId)!'),
                      backgroundColor: KukieAccent.success,
                    ),
                  );
                }
              },
              child: const Text('Submit Link Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Linked Students'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStudentDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Link Another Child'),
        backgroundColor: KukieAccent.violet,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                    'Access your connected children\'s grades, assessment breakdowns, credit hours, and confidential teacher guidance notes.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Linked Children (${_students.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton.icon(
                onPressed: _showAddStudentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Link Child'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._students.map((student) => _ParentStudentCard(student: student)),
        ],
      ),
    );
  }
}

class _ParentStudentCard extends StatelessWidget {
  const _ParentStudentCard({required this.student});

  final Map<String, String> student;

  @override
  Widget build(BuildContext context) {
    final isVerified = student['status'] == 'VERIFIED & ACTIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: KukieAccent.violetTint,
                  child: Icon(Icons.face, color: KukieAccent.violet),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        'ID: ${student['id']} · ${student['gradeLevel']} · ${student['major']}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                  ),
                  child: Text(
                    student['status']!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: KukieAccent.violetTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Semester GPA: ${student['gpa']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: KukieAccent.violet, fontSize: 13),
                  ),
                  Text(
                    'Relationship: ${student['relationship']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParentGradesPage(studentId: student['id']!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined, size: 16),
                    label: const Text('View Grades & Notes'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AcademicReportPage(studentId: student['id']!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text('Academic Report'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
