import 'package:flutter/material.dart';
import '../../models/portal_dashboard_models.dart';
import '../../models/user.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/portal_announcements_card.dart';
import '../../widgets/portal_sidebar.dart';
import '../../widgets/portal_tasks_card.dart';
import '../../widgets/portal_top_bar.dart';
import '../../widgets/portal_upcoming_classes_card.dart';
import '../../widgets/portal_weekly_goals_card.dart';

class StudentPortalDashboardPage extends StatefulWidget {
  const StudentPortalDashboardPage({super.key, required this.user});

  static const routeName = '/student-portal-dashboard';

  final User user;

  @override
  State<StudentPortalDashboardPage> createState() => _StudentPortalDashboardPageState();
}

class _StudentPortalDashboardPageState extends State<StudentPortalDashboardPage> {
  String _activeTab = 'Overview';
  String _selectedRoute = '/dashboard';

  // Sample Mock Data
  final List<PortalClassItem> _classes = [
    const PortalClassItem(
      id: 'c1',
      code: 'CSCI 201',
      title: 'Statistics in Computer Science',
      timeRange: '1:30pm - 3:00pm',
      color: Color(0xFF6366F1),
      instructorName: 'Alex Morgan',
      attendeeAvatars: ['A', 'S', 'D', 'M'],
    ),
    const PortalClassItem(
      id: 'c2',
      code: 'MATH 301',
      title: 'Deep Learning & Linear Algebra',
      timeRange: '11:00am - 1:00pm',
      color: Color(0xFF10B981),
      instructorName: 'Sarah Taylor',
      attendeeAvatars: ['J', 'K', 'L'],
    ),
  ];

  final List<PortalTaskItem> _tasks = [
    const PortalTaskItem(
      id: 't1',
      title: 'Submit Web Development Project',
      status: 'In progress',
      dueDate: 'Tomorrow',
    ),
    const PortalTaskItem(
      id: 't2',
      title: 'Review Database Systems Notes',
      status: 'Done',
      dueDate: 'March 20',
    ),
    const PortalTaskItem(
      id: 't3',
      title: 'Complete Software Architecture Homework',
      status: 'Due Soon',
      dueDate: 'Today, 11:59 PM',
    ),
  ];

  final List<PortalGoalItem> _goals = [
    const PortalGoalItem(
      id: 'g1',
      title: 'Complete a 5-day study streak',
      streakText: '🔥 3 day streak!',
      completedCount: 3,
      totalCount: 5,
    ),
    const PortalGoalItem(
      id: 'g2',
      title: 'Finish 2 Practice Coding Quizzes',
      streakText: '⚡ High focus!',
      completedCount: 1,
      totalCount: 2,
    ),
  ];

  final List<PortalAnnouncementItem> _announcements = [
    const PortalAnnouncementItem(
      id: 'a1',
      title: 'Registration for the upcoming semester is now officially open!',
      snippet: 'Explore the diverse range of courses now available for enrollment this semester.',
      authorName: 'University Admin',
      category: 'Academic',
      timestamp: '2 days ago',
      isImportant: true,
    ),
    const PortalAnnouncementItem(
      id: 'a2',
      title: 'Midterm Examination Schedule Released',
      snippet: 'Check your portal calendar for exam dates, rooms, and invigilator details.',
      authorName: 'Academic Directorate',
      category: 'Notice',
      timestamp: '5 days ago',
    ),
  ];

  void _handleAddTask() {
    final titleController = TextEditingController();
    final dueDateController = TextEditingController(text: 'Next Week');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New Task', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dueDateController,
              decoration: const InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  _tasks.add(
                    PortalTaskItem(
                      id: 't-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      status: 'In progress',
                      dueDate: dueDateController.text.trim(),
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KukieAccent.violet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  void _handleAddGoal() {
    final titleController = TextEditingController();
    final countController = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create Weekly Goal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Steps/Days',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final target = int.tryParse(countController.text) ?? 5;
                setState(() {
                  _goals.add(
                    PortalGoalItem(
                      id: 'g-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleController.text.trim(),
                      streakText: '🔥 New goal!',
                      completedCount: 1,
                      totalCount: target,
                    ),
                  );
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: KukieAccent.violet,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final userName = '${widget.user.firstName} ${widget.user.lastName}'.trim();
    final displayName = userName.isNotEmpty ? userName : 'Student';

    final sidebar = PortalSidebar(
      selectedRoute: _selectedRoute,
      userName: displayName,
      userRole: 'Student Portal',
      onSelectRoute: (route) => setState(() => _selectedRoute = route),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      drawer: !isDesktop ? Drawer(child: sidebar) : null,
      body: Row(
        children: [
          if (isDesktop) sidebar,
          Expanded(
            child: Column(
              children: [
                // Top Bar Navigation
                PortalTopBar(
                  userName: displayName,
                  onMenuTap: !isDesktop
                      ? () {
                          Scaffold.of(context).openDrawer();
                        }
                      : null,
                ),

                // Main Dashboard Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Header Section with Dynamic Greeting
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good morning, $displayName! 👋',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Here is your academic overview and task schedule for today.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Filter Pills / Tab Switcher
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _tabPill('Overview'),
                            _tabPill('Job Offers'),
                            _tabPill('Tasks'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2x2 Grid / Responsive Column Layout
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  PortalTasksCard(tasks: _tasks, onAddTask: _handleAddTask),
                                  const SizedBox(height: 20),
                                  PortalAnnouncementsCard(announcements: _announcements),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                children: [
                                  PortalUpcomingClassesCard(classes: _classes),
                                  const SizedBox(height: 20),
                                  PortalWeeklyGoalsCard(goals: _goals, onAddGoal: _handleAddGoal),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Mobile Single-Column Layout
                        PortalUpcomingClassesCard(classes: _classes),
                        const SizedBox(height: 16),
                        PortalTasksCard(tasks: _tasks, onAddTask: _handleAddTask),
                        const SizedBox(height: 16),
                        PortalWeeklyGoalsCard(goals: _goals, onAddGoal: _handleAddGoal),
                        const SizedBox(height: 16),
                        PortalAnnouncementsCard(announcements: _announcements),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(String label) {
    final isSelected = _activeTab == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _activeTab = label),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? KukieAccent.violet : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? KukieAccent.violet : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
