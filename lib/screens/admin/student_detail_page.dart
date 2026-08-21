import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../models/school_class.dart';
import '../../models/user.dart';
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
      final mine = byId.values.toList()..sort(_byPendingFirstThenMostRecent);

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

    SchoolClass selectedClass = availableClasses.firstWhere(
      (c) => _assignedClass != null && c.id == _assignedClass!.id,
      orElse: () => availableClasses.first,
    );
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedClass.id,
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
                          (c) => DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              '${c.displayName} (${c.academicYear})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = availableClasses.firstWhere((c) => c.id == val);
                        setDialogState(() {
                          selectedClass = found;
                          yearCtrl.text = found.academicYear;
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
                    studentId: widget.student.id,
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: Text(
          student.fullName,
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _ProfileCard(student: student),
            const SizedBox(height: 16),

            // Class & Section Card
            _ClassAssignmentCard(
              assignedClass: _assignedClass,
              enrollment: _enrollmentInfo,
              onAssignPressed: _showAssignClassDialog,
            ),

            const SizedBox(height: 24),
            const Text(
              'Guardian Links',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pending and verified guardian links registered for this student.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),
            if (_loading && links == null)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF5B5BF7))),
              )
            else if (_error != null && links == null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFEF4444))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B5BF7)),
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if ((links ?? const <Relationship>[]).isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    'No guardians have linked to this student yet.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ...links!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined, color: Color(0xFF5B5BF7), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Class & Section Assignment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              TextButton.icon(
                onPressed: onAssignPressed,
                icon: Icon(hasClass ? Icons.edit_outlined : Icons.add, size: 16, color: const Color(0xFF5B5BF7)),
                label: Text(
                  hasClass ? 'Change' : 'Assign',
                  style: const TextStyle(color: Color(0xFF5B5BF7), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasClass) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school, color: Color(0xFF5B5BF7), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignedClass!.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Room: ${assignedClass!.roomNumber ?? 'Unassigned'} • Year: ${enrollment?.academicYear ?? assignedClass!.academicYear}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF64748B), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Student is not assigned to any class yet.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.school, color: Color(0xFF5B5BF7), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 3),
                Text(
                  student.email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                if (student.studentId != null && student.studentId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Student ID: ${student.studentId}',
                      style: const TextStyle(
                        color: Color(0xFF5B5BF7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (student.status != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Status: ${student.status!.name}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '${relationship.relationshipType.label} link',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              _StatusBadge(status: relationship.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            relationship.parent != null
                ? 'Parent: ${relationship.parent!.fullName}'
                : 'Parent (internal id): ${relationship.parentId}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          ),
          if (relationship.parent != null && relationship.parent!.email.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '(${relationship.parent!.email})',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
          if (decided && relationship.verifiedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Decided ${_formatDate(relationship.verifiedAt!)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ] else if (relationship.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Requested ${_formatDate(relationship.createdAt!)}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
    final (bgColor, textColor, borderColor) = switch (status) {
      RelationshipStatus.pending => (const Color(0xFFFEF3C7), const Color(0xFFD97706), const Color(0xFFFDE68A)),
      RelationshipStatus.verified => (const Color(0xFFDCFCE7), const Color(0xFF15803D), const Color(0xFF86EFAC)),
      RelationshipStatus.rejected => (const Color(0xFFFEE2E2), const Color(0xFFDC2626), const Color(0xFFFCA5A5)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}