import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/attendance.dart';
import '../../models/parent_student_link.dart';
import '../../services/attendance_service.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';

/// Parent "My Children" screen — `GET /parents/my-students`.
///
/// Lists every approved guardian link for the logged-in parent.
/// Tapping a child opens their attendance records via
/// `GET /attendance/student/:studentId`.
class ParentMyChildrenPage extends StatefulWidget {
  const ParentMyChildrenPage({super.key});

  static const routeName = '/parent/my-children';

  @override
  State<ParentMyChildrenPage> createState() => _ParentMyChildrenPageState();
}

class _ParentMyChildrenPageState extends State<ParentMyChildrenPage> {
  final _parentService = ParentService();
  List<ParentStudentLink>? _links;
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
      final links = await _parentService.getMyStudents();
      if (mounted) setState(() => _links = links);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load children.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Children')),
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
                  child: _links!.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.people_outline,
                                      size: 64, color: AppColors.outline),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No linked children found.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Ask an admin to approve your\nguardian relationship request.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _links!.length,
                          itemBuilder: (_, i) {
                            final link = _links![i];
                            final student = link.student;
                            return Container(
                              margin: const EdgeInsets.only(
                                  bottom: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm),
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primaryFixed,
                                  child: Text(
                                    student.firstName.isNotEmpty
                                        ? student.firstName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student.fullName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(student.email),
                                    Text(
                                      link.relationshipType,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                              color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right,
                                    color: AppColors.outline),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          _ChildAttendancePage(
                                        studentId: student.id,
                                        studentName: student.fullName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

/// Shows attendance history for a single linked child.
/// Uses `GET /attendance/student/:studentId` which the backend allows
/// for parents with an approved relationship (verifyRecordAccess middleware).
class _ChildAttendancePage extends StatefulWidget {
  const _ChildAttendancePage({
    required this.studentId,
    required this.studentName,
  });

  final String studentId;
  final String studentName;

  @override
  State<_ChildAttendancePage> createState() => _ChildAttendancePageState();
}

class _ChildAttendancePageState extends State<_ChildAttendancePage> {
  final _attendanceService = AttendanceService();
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
        _attendanceService.getStudentAttendance(widget.studentId),
        _attendanceService.getStudentAttendanceSummary(widget.studentId),
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
      if (mounted) {
        setState(() => _error = 'Could not load attendance data.');
      }
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
      appBar: AppBar(title: Text(widget.studentName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 12),
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
                              Text('Attendance Summary',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              _SummaryRow('Present',
                                  _summary!.present, AppColors.secondary),
                              _SummaryRow(
                                  'Absent', _summary!.absent, AppColors.error),
                              _SummaryRow(
                                  'Late', _summary!.late, Colors.orange),
                              _SummaryRow('Excused', _summary!.excused,
                                  AppColors.outline),
                              const Divider(),
                              _SummaryRow('Total Days',
                                  _summary!.totalDays, AppColors.onSurface),
                              const SizedBox(height: 4),
                              Text(
                                'Attendance Rate: '
                                '${_summary!.attendancePercentage.toStringAsFixed(1)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      // Attendance list
                      Text('Records (${_records?.length ?? 0})',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      if (_records != null && _records!.isEmpty)
                        const Center(child: Text('No attendance records yet.'))
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
                              ),
                              trailing: Text(
                                rec.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(rec.status),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              subtitle: rec.note != null
                                  ? Text(rec.note!)
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
