import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/kukie_accent.dart';

class ScheduleEvent {
  const ScheduleEvent({
    required this.id,
    required this.courseCode,
    required this.title,
    required this.timeRange,
    required this.dayIndex, // 0: Mon, 1: Tue, 2: Wed, 3: Thu, 4: Fri
    required this.startHourIndex, // e.g. 1 for 8:00am, 3 for 10:00am
    required this.color,
    required this.instructorName,
  });

  final String id;
  final String courseCode;
  final String title;
  final String timeRange;
  final int dayIndex;
  final int startHourIndex;
  final Color color;
  final String instructorName;
}

class ClassScheduleTimetableWidget extends StatefulWidget {
  const ClassScheduleTimetableWidget({super.key});

  @override
  State<ClassScheduleTimetableWidget> createState() => _ClassScheduleTimetableWidgetState();
}

class _ClassScheduleTimetableWidgetState extends State<ClassScheduleTimetableWidget> {
  String _selectedMonth = 'February';
  String _selectedYear = '2026';

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<String> _dayDates = ['FEB 1', 'FEB 2', 'FEB 3', 'FEB 4', 'FEB 5'];
  final List<String> _timeSlots = [
    '7:00am',
    '8:00am',
    '9:00am',
    '10:00am',
    '11:00am',
    '12:00pm',
    '1:00pm',
  ];

  final List<ScheduleEvent> _events = [
    const ScheduleEvent(
      id: 'e1',
      courseCode: 'CS101',
      title: 'Mathematics in the Modern World',
      timeRange: '7:30am - 9:00am',
      dayIndex: 0,
      startHourIndex: 1, // 8:00am
      color: Color(0xFF3B82F6),
      instructorName: 'Alex Morgan',
    ),
    const ScheduleEvent(
      id: 'e2',
      courseCode: 'CS101',
      title: 'Computer Programming & Logic',
      timeRange: '10:30am - 12:00pm',
      dayIndex: 0,
      startHourIndex: 3, // 10:00am
      color: Color(0xFF6366F1),
      instructorName: 'Alex Morgan',
    ),
    const ScheduleEvent(
      id: 'e3',
      courseCode: 'ENG101',
      title: 'Technical Writing & Communication',
      timeRange: '8:30am - 10:00am',
      dayIndex: 1,
      startHourIndex: 1, // 8:00am
      color: Color(0xFF10B981),
      instructorName: 'Sarah Taylor',
    ),
    const ScheduleEvent(
      id: 'e4',
      courseCode: 'CS202',
      title: 'Human Computer Interaction',
      timeRange: '1:00pm - 2:30pm',
      dayIndex: 1,
      startHourIndex: 6, // 1:00pm
      color: Color(0xFFF59E0B),
      instructorName: 'Sarah Taylor',
    ),
    const ScheduleEvent(
      id: 'e5',
      courseCode: 'CS301',
      title: 'Operating Systems & Networks',
      timeRange: '9:30am - 11:00am',
      dayIndex: 2,
      startHourIndex: 2, // 9:00am
      color: Color(0xFF0EA5E9),
      instructorName: 'Alex Morgan',
    ),
    const ScheduleEvent(
      id: 'e6',
      courseCode: 'BUS101',
      title: 'Entrepreneurship & Innovation',
      timeRange: '10:00am - 11:30am',
      dayIndex: 3,
      startHourIndex: 3, // 10:00am
      color: Color(0xFF10B981),
      instructorName: 'Sarah Taylor',
    ),
    const ScheduleEvent(
      id: 'e7',
      courseCode: 'AI401',
      title: 'Artificial Intelligence Fundamentals',
      timeRange: '8:00am - 9:30am',
      dayIndex: 4,
      startHourIndex: 1, // 8:00am
      color: Color(0xFF8B5CF6),
      instructorName: 'Alex Morgan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Dropdowns
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chevron_left, size: 18),
                    label: const Text('Prev week', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () {},
                    label: const Text('Next week', style: TextStyle(fontSize: 12)),
                    icon: const Icon(Icons.chevron_right, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KukieAccent.violet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text('$_selectedMonth ∨', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text('$_selectedYear ∨', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Timetable Matrix Grid
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 680,
              child: Column(
                children: [
                  // Days Header Row
                  Row(
                    children: [
                      const SizedBox(width: 60), // Time column offset
                      for (int d = 0; d < 5; d++)
                        Expanded(
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _days[d],
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _dayDates[d],
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Time Slots Rows
                  for (int t = 0; t < _timeSlots.length; t++)
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                      ),
                      child: Row(
                        children: [
                          // Time Label Column
                          SizedBox(
                            width: 60,
                            child: Text(
                              _timeSlots[t],
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ),

                          // 5 Day Columns
                          for (int d = 0; d < 5; d++)
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: Colors.grey.shade100)),
                                ),
                                child: _buildEventCardForSlot(d, t),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildEventCardForSlot(int dayIdx, int timeIdx) {
    final matches = _events.where((e) => e.dayIndex == dayIdx && e.startHourIndex == timeIdx).toList();
    if (matches.isEmpty) return null;

    final event = matches.first;
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${event.courseCode}: ${event.title}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheduled Time: ${event.timeRange}'),
                const SizedBox(height: 6),
                Text('Instructor: ${event.instructorName}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: double.infinity,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.courseCode,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: event.color),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    event.timeRange,
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
