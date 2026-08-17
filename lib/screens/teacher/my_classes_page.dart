import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'add_grade_page.dart';

class MyClassesPage extends StatefulWidget {
  const MyClassesPage({super.key});

  static const routeName = '/teacher/classes';

  @override
  State<MyClassesPage> createState() => _MyClassesPageState();
}

class _MyClassesPageState extends State<MyClassesPage> {
  int _selectedClassIndex = 0;

  final List<Map<String, dynamic>> _classes = [
    {
      'code': 'CS-101',
      'title': 'Intro to Computer Science',
      'schedule': 'Mon, Wed, Fri · 9:00 AM - 10:30 AM',
      'room': 'Lab 4B',
      'studentsCount': 24,
      'students': [
        {'id': 'STU-1001', 'name': 'Alexander Hayes', 'status': 'Present', 'grade': '91% (A)'},
        {'id': 'STU-1002', 'name': 'Sophia Rodriguez', 'status': 'Present', 'grade': '76% (C)'},
        {'id': 'STU-1003', 'name': 'Liam Chen', 'status': 'Late', 'grade': '88% (B)'},
        {'id': 'STU-1004', 'name': 'Emma Watson', 'status': 'Present', 'grade': '95% (A)'},
      ]
    },
    {
      'code': 'MATH-202',
      'title': 'Advanced Algebra & Calculus',
      'schedule': 'Tue, Thu · 11:00 AM - 12:30 PM',
      'room': 'Hall 2A',
      'studentsCount': 28,
      'students': [
        {'id': 'STU-1001', 'name': 'Alexander Hayes', 'status': 'Present', 'grade': '94% (A)'},
        {'id': 'STU-1005', 'name': 'Noah Miller', 'status': 'Present', 'grade': '82% (B)'},
        {'id': 'STU-1006', 'name': 'Olivia Taylor', 'status': 'Absent', 'grade': '79% (C)'},
      ]
    },
    {
      'code': 'STEM-305',
      'title': 'Robotics & Problem Solving',
      'schedule': 'Wed, Fri · 2:00 PM - 4:00 PM',
      'room': 'Maker Lab 1',
      'studentsCount': 18,
      'students': [
        {'id': 'STU-1001', 'name': 'Alexander Hayes', 'status': 'Present', 'grade': '96% (A)'},
        {'id': 'STU-1007', 'name': 'Ethan Davis', 'status': 'Present', 'grade': '90% (A)'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentClass = _classes[_selectedClassIndex];
    final students = currentClass['students'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Classes & Rosters'),
      ),
      body: Column(
        children: [
          // Class Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_classes.length, (index) {
                  final isSelected = index == _selectedClassIndex;
                  final cls = _classes[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text('${cls['code']}: ${cls['title']}'),
                      selectedColor: KukieAccent.violetTint,
                      labelStyle: TextStyle(
                        color: isSelected ? KukieAccent.violet : KukieAccent.ink,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedClassIndex = index);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          // Selected Class Info Header
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [KukieAccent.violet, KukieAccent.violet.withValues(alpha: 0.85)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentClass['code']} · ${currentClass['title']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${currentClass['schedule']} · ${currentClass['room']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${currentClass['studentsCount']} Enrolled Students',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
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
                      'Class Roster & Today\'s Attendance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(AddGradePage.routeName),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Grade'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...students.map((student) => _StudentRosterCard(
                      student: student,
                      onToggleStatus: (newStatus) {
                        setState(() => student['status'] = newStatus);
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentRosterCard extends StatelessWidget {
  const _StudentRosterCard({
    required this.student,
    required this.onToggleStatus,
  });

  final Map<String, dynamic> student;
  final ValueChanged<String> onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final status = student['status'] as String;

    Color statusColor;
    switch (status) {
      case 'Present':
        statusColor = Colors.green.shade700;
        break;
      case 'Late':
        statusColor = Colors.orange.shade800;
        break;
      default:
        statusColor = Colors.red.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: KukieAccent.violetTint,
              child: Text(
                (student['name'] as String).substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.w800, color: KukieAccent.violet),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  Text(
                    'ID: ${student['id']} · Current Grade: ${student['grade']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              initialValue: status,
              onSelected: onToggleStatus,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
                  ],
                ),
              ),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Present', child: Text('Present')),
                PopupMenuItem(value: 'Late', child: Text('Late')),
                PopupMenuItem(value: 'Absent', child: Text('Absent')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
