import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/attendance.dart';
import '../../models/user.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';

/// Student Attendance page — `GET /attendance/student/:studentId` and
/// `GET /attendance/student/:studentId/summary`.
///
/// Shown to the logged-in student for their own attendance records.
/// The [user] is the currently authenticated student.
class StudentAttendancePage extends StatefulWidget {
  const StudentAttendancePage({super.key, required this.user});

  static const routeName = '/student/attendance';

  final User user;

  @override
  State<StudentAttendancePage> createState() => _StudentAttendancePageState();
}

class _StudentAttendancePageState extends State<StudentAttendancePage> {
  final _service = AttendanceService();
  List<Attendance>? _records;
  AttendanceSummary? _summary;
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
      final results = await Future.wait([
        _service.getStudentAttendance(widget.user.id),
        _service.getStudentAttendanceSummary(widget.user.id),
      ]);
      if (mounted) {
        setState(() {
          _records = results[0] as List<Attendance>;
          _summary = results[1] as AttendanceSummary;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load attendance data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.secondary;
      case AttendanceStatus.absent:
        return AppColors.error;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.excused:
        return AppColors.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Attendance')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      FilledButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      // Summary card
                      if (_summary != null) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLowest,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Attendance Summary',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              _SummaryRow('Present', _summary!.present,
                                  AppColors.secondary),
                              _SummaryRow(
                                  'Absent', _summary!.absent, AppColors.error),
                              _SummaryRow(
                                  'Late', _summary!.late, Colors.orange),
                              _SummaryRow('Excused', _summary!.excused,
                                  AppColors.outline),
                              const Divider(),
                              _SummaryRow('Total Days', _summary!.totalDays,
                                  AppColors.onSurface),
                              const SizedBox(height: 4),
                              Text(
                                'Attendance Rate: '
                                '${_summary!.attendancePercentage.toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      // History list
                      Text(
                        'History (${_records?.length ?? 0} records)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_records != null && _records!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: Text('No attendance records yet.')),
                        )
                      else
                        ...(_records ?? []).map(
                          (rec) => Card(
                            margin: const EdgeInsets.only(
                                bottom: AppSpacing.sm),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _statusColor(rec.status)
                                        .withValues(alpha: 0.15),
                                child: Icon(
                                  Icons.event_available,
                                  color: _statusColor(rec.status),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                rec.date
                                    .toLocal()
                                    .toString()
                                    .substring(0, 10),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(rec.status)
                                      .withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  rec.status.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _statusColor(rec.status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              subtitle: rec.note != null
                                  ? Text(rec.note!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall)
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.count, this.color);
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
