import 'package:flutter/material.dart';
import '../models/portal_dashboard_models.dart';
import '../theme/kukie_accent.dart';

class PortalTasksCard extends StatefulWidget {
  const PortalTasksCard({
    super.key,
    required this.tasks,
    required this.onAddTask,
  });

  final List<PortalTaskItem> tasks;
  final VoidCallback onAddTask;

  @override
  State<PortalTasksCard> createState() => _PortalTasksCardState();
}

class _PortalTasksCardState extends State<PortalTasksCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Color _getStatusBgColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFFECFDF5);
      case 'Due Soon':
        return const Color(0xFFFEF2F2);
      case 'In progress':
      default:
        return const Color(0xFFFFFBEB);
    }
  }

  Color _getStatusBorderColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFFA7F3D0);
      case 'Due Soon':
        return const Color(0xFFFECACA);
      case 'In progress':
      default:
        return const Color(0xFFFDE68A);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Done':
        return const Color(0xFF047857);
      case 'Due Soon':
        return const Color(0xFFDC2626);
      case 'In progress':
      default:
        return const Color(0xFFB45309);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.tasks.where((t) => t.status == 'Done').length;
    final inProgressCount = widget.tasks.where((t) => t.status == 'In progress').length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tasks & Assignments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track your coursework & study deliverables',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onAddTask,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New task', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KukieAccent.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal Task Cards
          SizedBox(
            height: 120,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.tasks.length,
              onPageChanged: (idx) => setState(() => _currentPage = idx),
              itemBuilder: (context, idx) {
                final task = widget.tasks[idx];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusBgColor(task.status),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getStatusBorderColor(task.status)),
                            ),
                            child: Text(
                              task.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusTextColor(task.status),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF9CA3AF)),
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            'Due date: ${task.dueDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.tasks.length} total tasks  •  $completedCount completed  •  $inProgressCount in progress',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_left, size: 18, color: Color(0xFF4B5563)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      if (_currentPage < widget.tasks.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
