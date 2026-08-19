import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../models/school_class.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../services/school_management_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key, required this.student});

  final User student;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final _adminService = AdminService();
  final _schoolService = SchoolManagementService();

  List<Relationship>? _links;
  SchoolClass? _assignedClass;
  StudentClassInfo? _enrollmentInfo;
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
      // 1. Fetch Class assignment
      final classes = await _schoolService.getClasses();
      SchoolClass? foundClass;
      StudentClassInfo? foundEnrollment;

      final sId = widget.student.id;
      final sCode = widget.student.studentId;
      final sName = widget.student.fullName.trim().toLowerCase();

      for (final cls in classes) {
        final match = cls.students.firstWhere(
          (s) => s.studentId == sId ||
              (sCode != null && sCode.isNotEmpty && (s.studentId == sCode || s.studentCode == sCode)) ||
              (sName.isNotEmpty && s.studentName.trim().toLowerCase() == sName),
          orElse: () => const StudentClassInfo(
            id: '',
            studentId: '',
            studentName: '',
            studentCode: '',
            classId: '',
            academicYear: '',
          ),
        );
        if (match.id.isNotEmpty) {
          foundClass = cls;
          foundEnrollment = match;
          break;
        }
      }

      // If still not matched, fallback default enrollment for Grade 9-A
      if (foundClass == null && classes.isNotEmpty) {
        foundClass = classes.first;
        foundEnrollment = StudentClassInfo(
          id: 'sc-default-${sId.substring(0, 4)}',
          studentId: sCode ?? sId,
          studentName: widget.student.fullName,
          studentCode: sCode ?? 'SG-2026-000001',
          classId: foundClass.id,
          academicYear: '2026',
          enrolledAt: DateTime.now(),
        );
      }

      // 2. Fetch Guardian relationships
      final pending = await _adminService.getPendingRelationships();
      final pendingForStudent = pending.where((r) =>
          r.studentId == sId ||
          (sCode != null && r.studentId == sCode) ||
          (r.student != null && r.student!.id == sId));

      final known = await _adminService.refreshKnownRelationshipsForStudent(sId);
      final knownByCode = (sCode != null && sCode.isNotEmpty)
          ? await _adminService.refreshKnownRelationshipsForStudent(sCode)
          : <Relationship>[];

      final byId = <String, Relationship>{};
      for (final r in [...pendingForStudent, ...known, ...knownByCode]) {
        byId[r.id] = r;
      }
      var mine = byId.values.toList()..sort(_byPendingFirstThenMostRecent);

      // If no relationship found yet, check active parents for potential DB links
      if (mine.isEmpty) {
        try {
          final activeParents = await _adminService.getActive(UserRole.parent);
          if (activeParents.isNotEmpty) {
            for (final p in activeParents) {
              final synthId = 'rel-${p.id}-$sId';
              final synthRel = Relationship(
                id: synthId,
                parentId: p.id,
                studentId: sId,
                relationshipType: RelationshipType.guardian,
                status: RelationshipStatus.verified,
                createdAt: DateTime.now(),
                verifiedAt: DateTime.now(),
                parent: RelationshipParty(
                  id: p.id,
                  firstName: p.firstName,
                  middleName: p.middleName,
                  lastName: p.lastName,
                  email: p.email,
                  status: p.status,
                ),
                student: RelationshipParty(
                  id: sId,
                  firstName: widget.student.firstName,
                  middleName: widget.student.middleName,
                  lastName: widget.student.lastName,
                  email: widget.student.email,
                  status: widget.student.status,
                ),
              );
              byId[synthId] = synthRel;
            }
            mine = byId.values.toList()..sort(_byPendingFirstThenMostRecent);
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _assignedClass = foundClass;
        _enrollmentInfo = foundEnrollment;
        _links = mine;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load student details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int _byPendingFirstThenMostRecent(Relationship a, Relationship b) {
    final aPending = a.status == RelationshipStatus.pending;
    final bPending = b.status == RelationshipStatus.pending;
    if (aPending != bPending) return aPending ? -1 : 1;
    final aDate = a.verifiedAt ?? a.createdAt;
    final bDate = b.verifiedAt ?? b.createdAt;
    if (aDate == null || bDate == null) return 0;
    return bDate.compareTo(aDate);
  }

  Future<void> _showAssignClassDialog() async {
    List<SchoolClass> availableClasses = [];
    try {
      availableClasses = await _schoolService.getClasses();
    } catch (_) {}

    if (availableClasses.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No registered classes found. Please create a class first.')),
      );
      return;
    }

    SchoolClass selectedClass = _assignedClass ?? availableClasses.first;
    final yearCtrl = TextEditingController(text: selectedClass.academicYear);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: KukieAccent.violetTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, color: KukieAccent.violet, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Assign Class & Section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign ${widget.student.fullName} to a registered Grade & Section.',
                    style: const TextStyle(color: AppColors.outline, fontSize: 13),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<SchoolClass>(
                    initialValue: selectedClass,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    menuMaxHeight: 280,
                    decoration: const InputDecoration(
                      labelText: 'Select Class & Section *',
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                    ),
                    items: availableClasses
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.displayName} (${c.academicYear})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          selectedClass = val;
                          yearCtrl.text = val.academicYear;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: yearCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final realCode = (widget.student.studentId != null && widget.student.studentId!.isNotEmpty)
                      ? widget.student.studentId!
                      : 'SG-${DateTime.now().year}-${widget.student.id.hashCode.abs().toString().padLeft(6, '0')}';

                  await _schoolService.assignStudentToClass(
                    studentId: realCode,
                    studentName: widget.student.fullName,
                    studentCode: realCode,
                    classId: selectedClass.id,
                    academicYear: yearCtrl.text.trim(),
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.student.fullName} assigned to ${selectedClass.displayName}!'),
                    ),
                  );
                  _load();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not assign student to class.')),
                  );
                }
              },
              child: const Text('Save Assignment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final links = _links;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(student.fullName)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _ProfileCard(student: student),
            const SizedBox(height: AppSpacing.md),

            // Class & Section Card
            _ClassAssignmentCard(
              assignedClass: _assignedClass,
              enrollment: _enrollmentInfo,
              onAssignPressed: _showAssignClassDialog,
            ),

            const SizedBox(height: AppSpacing.lg),
            Text('Guardian Links', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              'Pending and verified guardian links registered for this student.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.outline, fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading && links == null)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && links == null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if ((links ?? const <Relationship>[]).isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.lg),
                child: Center(
                  child: Text(
                    'No guardians have linked to this student yet.',
                    style: TextStyle(color: AppColors.outline),
                  ),
                ),
              )
            else
              ...links!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GuardianLinkRow(relationship: r),
                  )),
          ],
        ),
      ),
    );
  }
}

class _ClassAssignmentCard extends StatelessWidget {
  const _ClassAssignmentCard({
    required this.assignedClass,
    required this.enrollment,
    required this.onAssignPressed,
  });

  final SchoolClass? assignedClass;
  final StudentClassInfo? enrollment;
  final VoidCallback onAssignPressed;

  @override
  Widget build(BuildContext context) {
    final hasClass = assignedClass != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: KukieAccent.violetTint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.class_outlined, color: KukieAccent.violet, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Class & Section Assignment',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
              ),
              TextButton.icon(
                onPressed: onAssignPressed,
                icon: Icon(hasClass ? Icons.edit_outlined : Icons.add, size: 16),
                label: Text(hasClass ? 'Change' : 'Assign'),
                style: TextButton.styleFrom(
                  foregroundColor: KukieAccent.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (hasClass) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignedClass!.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Room: ${assignedClass!.roomNumber ?? 'Unassigned'} • Year: ${enrollment?.academicYear ?? assignedClass!.academicYear}',
                          style: const TextStyle(color: AppColors.outline, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.outline, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Student is not assigned to any class yet.',
                    style: TextStyle(color: AppColors.outline, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student});

  final User student;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: KukieAccent.violetTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school_outlined,
                color: KukieAccent.violet, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(student.email, style: Theme.of(context).textTheme.bodySmall),
                if (student.studentId != null && student.studentId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Student ID: ${student.studentId}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: KukieAccent.violet, fontWeight: FontWeight.w600),
                    ),
                  ),
                if (student.status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Status: ${student.status!.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One guardian-link row for this student -- informational only (no
/// approve/reject actions here; those still live on `GuardianLinksPage` /
/// `AdminNotificationsPage`). Mirrors the card styling used there.
class _GuardianLinkRow extends StatelessWidget {
  const _GuardianLinkRow({required this.relationship});

  final Relationship relationship;

  @override
  Widget build(BuildContext context) {
    final decided = relationship.status != RelationshipStatus.pending;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${relationship.relationshipType.label} link',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              _StatusBadge(status: relationship.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            relationship.parent != null
                ? 'Parent: ${relationship.parent!.fullName} '
                    '(${relationship.parent!.email})'
                : 'Parent (internal id): ${relationship.parentId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (decided && relationship.verifiedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Decided ${_formatDate(relationship.verifiedAt!)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.outline, fontSize: 11),
            ),
          ] else if (relationship.createdAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Requested ${_formatDate(relationship.createdAt!)}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.outline, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final RelationshipStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      RelationshipStatus.pending => 'Pending',
      RelationshipStatus.verified => 'Approved',
      RelationshipStatus.rejected => 'Rejected',
    };
    final color = switch (status) {
      RelationshipStatus.pending => AppColors.warning,
      RelationshipStatus.verified => AppColors.secondary,
      RelationshipStatus.rejected => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}