import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class AttendanceReportPage extends StatelessWidget {
  const AttendanceReportPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/reports/attendance';
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Summary Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.teal.shade700,
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Attendance Rate',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  '96.2%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: $studentId · 128 Days Attended of 133 Total',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(child: _AttendanceStatCard(label: 'Present', count: '124', color: Colors.green)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _AttendanceStatCard(label: 'Late', count: '4', color: Colors.orange)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _AttendanceStatCard(label: 'Excused', count: '3', color: Colors.blue)),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: _AttendanceStatCard(label: 'Absent', count: '2', color: Colors.red)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent Attendance History Log',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _AttendanceLogRow(date: 'Today (Aug 18)', status: 'PRESENT', subject: 'All Classes'),
          const _AttendanceLogRow(date: 'Yesterday (Aug 17)', status: 'PRESENT', subject: 'All Classes'),
          const _AttendanceLogRow(date: 'Friday (Aug 14)', status: 'LATE', subject: 'Period 1: Math (Arrival 8:12 AM)'),
          const _AttendanceLogRow(date: 'Thursday (Aug 13)', status: 'PRESENT', subject: 'All Classes'),
          const _AttendanceLogRow(date: 'Wednesday (Aug 12)', status: 'EXCUSED', subject: 'Medical Appointment'),
        ],
      ),
    );
  }
}

class _AttendanceStatCard extends StatelessWidget {
  const _AttendanceStatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final String count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
        border: Border.all(color: KukieAccent.cardBorder),
      ),
      child: Column(
        children: [
          Text(count,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _AttendanceLogRow extends StatelessWidget {
  const _AttendanceLogRow({
    required this.date,
    required this.status,
    required this.subject,
  });

  final String date;
  final String status;
  final String subject;

  Color get _statusColor {
    switch (status) {
      case 'PRESENT':
        return Colors.green.shade700;
      case 'LATE':
        return Colors.orange.shade800;
      case 'EXCUSED':
        return Colors.blue.shade700;
      default:
        return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
        border: Border.all(color: KukieAccent.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(subject, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
