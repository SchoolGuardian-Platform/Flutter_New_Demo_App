import 'package:flutter/material.dart';

/// Data Model for Upcoming Class Item
class PortalClassItem {
  const PortalClassItem({
    required this.id,
    required this.code,
    required this.title,
    required this.timeRange,
    required this.color,
    required this.instructorName,
    required this.attendeeAvatars,
  });

  final String id;
  final String code;
  final String title;
  final String timeRange;
  final Color color;
  final String instructorName;
  final List<String> attendeeAvatars;
}

/// Data Model for Task Item
class PortalTaskItem {
  const PortalTaskItem({
    required this.id,
    required this.title,
    required this.status, // 'In progress', 'Done', 'Due Soon'
    required this.dueDate,
  });

  final String id;
  final String title;
  final String status;
  final String dueDate;
}

/// Data Model for Weekly Goal Item
class PortalGoalItem {
  const PortalGoalItem({
    required this.id,
    required this.title,
    required this.streakText,
    required this.completedCount,
    required this.totalCount,
  });

  final String id;
  final String title;
  final String streakText;
  final int completedCount;
  final int totalCount;

  double get progressFraction => totalCount > 0 ? completedCount / totalCount : 0.0;
}

/// Data Model for Announcement Item
class PortalAnnouncementItem {
  const PortalAnnouncementItem({
    required this.id,
    required this.title,
    required this.snippet,
    required this.authorName,
    required this.category,
    required this.timestamp,
    this.isImportant = false,
  });

  final String id;
  final String title;
  final String snippet;
  final String authorName;
  final String category;
  final String timestamp;
  final bool isImportant;
}
