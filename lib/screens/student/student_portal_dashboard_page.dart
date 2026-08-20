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
  const StudentPortalDashboardPage({super.key, this.user});

  static const routeName = '/student-portal-dashboard';

  final User? user;

  @override
  State<StudentPortalDashboardPage> createState() => _StudentPortalDashboardPageState();
}

class _StudentPortalDashboardPageState extends State<StudentPortalDashboardPage> {
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
    const PortalClassItem(
      id: 'c3',
      code: 'PHYS 102',
      title: 'Quantum Physics & Relativity',
      timeRange: '3:30pm - 5:00pm',
      color: Color(0xFFF59E0B),
      instructorName: 'Dr. Robert Chen',
      attendeeAvatars: ['P', 'R', 'T'],
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

  void _handleToggleTaskStatus(PortalTaskItem task) {
    String nextStatus;
    switch (task.status) {
      case 'In progress':
        nextStatus = 'Done';
        break;
      case 'Done':
        nextStatus = 'Due Soon';
        break;
      case 'Due Soon':
      default:
        nextStatus = 'In progress';
        break;
    }

    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx != -1) {
        _tasks[idx] = PortalTaskItem(
          id: task.id,
          title: task.title,
          status: nextStatus,
          dueDate: task.dueDate,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task "${task.title}" updated to $nextStatus')),
    );
  }

  void _handleIncrementGoal(PortalGoalItem goal) {
    if (goal.completedCount >= goal.totalCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 Goal "${goal.title}" is 100% complete!')),
      );
      return;
    }

    final newCount = goal.completedCount + 1;
    setState(() {
      final idx = _goals.indexWhere((g) => g.id == goal.id);
      if (idx != -1) {
        _goals[idx] = PortalGoalItem(
          id: goal.id,
          title: goal.title,
          streakText: newCount == goal.totalCount ? '🎉 Goal Completed!' : goal.streakText,
          completedCount: newCount,
          totalCount: goal.totalCount,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Progress logged: ${goal.title} ($newCount/${goal.totalCount})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final userName = widget.user != null
        ? '${widget.user!.firstName} ${widget.user!.lastName}'.trim()
        : 'Alex Morgan';
    final displayName = userName.isNotEmpty ? userName : 'Alex Morgan';

    final sidebar = PortalSidebar(
      selectedRoute: _selectedRoute,
      userName: displayName,
      userRole: 'Student Portal',
      onSelectRoute: (route) => setState(() => _selectedRoute = route),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      drawer: !isDesktop ? Drawer(child: sidebar) : null,
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getBottomNavIndex(_selectedRoute),
              selectedItemColor: KukieAccent.violet,
              unselectedItemColor: Colors.grey.shade600,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 8,
              onTap: (index) {
                switch (index) {
                  case 0:
                    setState(() => _selectedRoute = '/dashboard');
                    break;
                  case 1:
                    setState(() => _selectedRoute = '/schedule');
                    break;
                  case 2:
                    setState(() => _selectedRoute = '/portfolio');
                    break;
                  case 3:
                    setState(() => _selectedRoute = '/resources');
                    break;
                  case 4:
                    setState(() => _selectedRoute = '/settings');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Schedule'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
                BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Resources'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Account'),
              ],
            )
          : null,
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

                // Main Content View Body
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Student Summary Header Bar
                      _buildStudentSummaryHeader(displayName),
                      const SizedBox(height: 20),

                      // Filter Pills / Tab Switcher
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _tabPill('Overview', '/dashboard'),
                            _tabPill('Schedule Matrix', '/schedule'),
                            _tabPill('Portfolio Projects', '/portfolio'),
                            _tabPill('Resources & Downloads', '/resources'),
                            _tabPill('Student Forum', '/forum'),
                            _tabPill('Account Settings', '/settings'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Route / Tab Specific Dynamic Content
                      _buildActiveTabContent(isDesktop),
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

  int _getBottomNavIndex(String route) {
    switch (route) {
      case '/schedule':
        return 1;
      case '/portfolio':
        return 2;
      case '/resources':
        return 3;
      case '/settings':
        return 4;
      case '/dashboard':
      default:
        return 0;
    }
  }

  Widget _buildStudentSummaryHeader(String displayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, $displayName 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Computer Science & AI Major • Year 3 (Junior)',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE ENROLLED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 4 Quick Metrics Grid
          Row(
            children: [
              _headerMetric('Cumulative GPA', '3.84 / 4.00', '+0.12 vs last sem', const Color(0xFF6366F1)),
              _headerMetric('Enrolled Courses', '5 Active', '15 Credit Hours', const Color(0xFF10B981)),
              _headerMetric('Completed Credits', '48 / 120', 'Degree Track 40%', const Color(0xFFF59E0B)),
              _headerMetric('Attendance Rate', '96.5%', 'Honor Roll Eligible', const Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerMetric(String label, String value, String subtext, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: accentColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDesktop) {
    switch (_selectedRoute) {
      case '/schedule':
        return _buildScheduleMatrixView();
      case '/portfolio':
        return _buildPortfolioProjectsView();
      case '/resources':
        return _buildResourcesView();
      case '/forum':
        return _buildStudentForumView();
      case '/settings':
        return _buildAccountSettingsView();
      case '/dashboard':
      default:
        return _buildOverviewDashboardView(isDesktop);
    }
  }

  Widget _buildOverviewDashboardView(bool isDesktop) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                PortalTasksCard(
                  tasks: _tasks,
                  onAddTask: _handleAddTask,
                  onToggleTaskStatus: _handleToggleTaskStatus,
                ),
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
                PortalWeeklyGoalsCard(
                  goals: _goals,
                  onAddGoal: _handleAddGoal,
                  onTapGoal: _handleIncrementGoal,
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        PortalUpcomingClassesCard(classes: _classes),
        const SizedBox(height: 16),
        PortalTasksCard(
          tasks: _tasks,
          onAddTask: _handleAddTask,
          onToggleTaskStatus: _handleToggleTaskStatus,
        ),
        const SizedBox(height: 16),
        PortalWeeklyGoalsCard(
          goals: _goals,
          onAddGoal: _handleAddGoal,
          onTapGoal: _handleIncrementGoal,
        ),
        const SizedBox(height: 16),
        PortalAnnouncementsCard(announcements: _announcements),
      ],
    );
  }

  Widget _buildScheduleMatrixView() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Timetable Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          const Text('Spring Semester 2026 • Class Room Allocations & Time Blocks', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 16),
          Column(
            children: [
              for (int idx = 0; idx < days.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(days[idx], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('CSCI 201: Statistics (Room 304) • 10:00 AM - 11:30 AM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('MATH 301: Linear Algebra (Lab 102) • 01:30 PM - 03:00 PM', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioProjectsView() {
    final projects = [
      {'title': 'Mobile Anti-Gravity & AI Tracker', 'tech': 'Flutter • Dart • Physics API', 'score': '98/100', 'status': 'Completed'},
      {'title': 'Distributed Microservices DB Engine', 'tech': 'Go • PostgreSQL • Docker', 'score': '95/100', 'status': 'Under Review'},
      {'title': 'Zero-Knowledge Authentication System', 'tech': 'Python • Rust • Cryptography', 'score': '96/100', 'status': 'Completed'},
    ];

    return Column(
      children: projects.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['title']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text(p['tech']!, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p['score']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                  const SizedBox(height: 4),
                  Text(p['status']!, style: const TextStyle(fontSize: 11, color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResourcesView() {
    final files = [
      {'name': 'CSCI 201: Statistics & ML Lecture Notes.pdf', 'size': '14.2 MB', 'category': 'Lecture Slides'},
      {'name': 'MATH 301: Linear Algebra Formula Sheet.pdf', 'size': '3.8 MB', 'category': 'Exam Prep'},
      {'name': 'CSCI 310: Software Architecture Patterns.zip', 'size': '42.5 MB', 'category': 'Lab Code'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Course Resources & Downloads', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int idx = 0; idx < files.length; idx++) ...[
                if (idx > 0) const Divider(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFEF4444), size: 28),
                  title: Text(files[idx]['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${files[idx]['category']} • ${files[idx]['size']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  trailing: IconButton(
                    icon: const Icon(Icons.download_rounded, color: Color(0xFF6366F1)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${files[idx]['name']}...')),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentForumView() {
    final threads = [
      {'title': 'CSCI 201 Midterm Study Group in Library Room 204', 'replies': '18 replies', 'upvotes': '42 upvotes'},
      {'title': 'Tips for Mastering Flutter State Management & Custom Painters', 'replies': '24 replies', 'upvotes': '65 upvotes'},
      {'title': 'Algorithm Analysis Homework #3 Discussion Thread', 'replies': '9 replies', 'upvotes': '15 upvotes'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Student Peer Discussion Forum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Column(
            children: [
              for (int idx = 0; idx < threads.length; idx++) ...[
                if (idx > 0) const Divider(height: 16),
                ListTile(
                  leading: const Icon(Icons.forum_outlined, color: Color(0xFF6366F1)),
                  title: Text(threads[idx]['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('${threads[idx]['replies']} • ${threads[idx]['upvotes']}', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Student Profile & Account Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 14),
          ListTile(
            leading: Icon(Icons.badge_outlined, color: Color(0xFF6366F1)),
            title: Text('Student ID'),
            subtitle: Text('STU-2026-8842'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.school_outlined, color: Color(0xFF10B981)),
            title: Text('Academic Major'),
            subtitle: Text('Computer Science & Artificial Intelligence'),
          ),
          Divider(height: 1),
          ListTile(
            leading: Icon(Icons.notifications_active_outlined, color: Color(0xFFF59E0B)),
            title: Text('Notification Alerts'),
            subtitle: Text('Exam reminders, task due dates & announcements enabled'),
          ),
        ],
      ),
    );
  }

  Widget _tabPill(String label, String route) {
    final isSelected = _selectedRoute == route;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedRoute = route),
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
