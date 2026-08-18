import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Read-only detail view for a single verified student -- their profile
/// plus every guardian link involving them that this admin session can
/// discover, at any status. Reached by tapping a student row on
/// `VerifiedUsersPage`.
///
/// BACKEND GAP: there is no `GET /admin/relationships` (all statuses)
/// route, and no per-student relationships endpoint an admin can call
/// for an arbitrary student (`GET /students/my-guardians` is scoped to
/// the caller's own JWT). So this can only show:
///   1. Links currently pending (via `AdminService.getPendingRelationships`,
///      filtered client-side to this student -- always complete/live), and
///   2. Links this app has already discovered before (cached relationship
///      ids in `AdminService`, refreshed via `GET /relationships/:id` --
///      see `AdminService.refreshKnownRelationshipsForStudent`).
/// A link approved or rejected before ever appearing pending in this app
/// session has no discoverable id and won't show up here. Closing that
/// gap needs a real backend endpoint (e.g. `GET /admin/relationships` or
/// `GET /admin/students/:id/relationships`) -- this is a client-side
/// workaround, not a substitute for one.
class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key, required this.student});

  final User student;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final _adminService = AdminService();
  List<Relationship>? _links;
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
      // 1. Whatever's currently pending, globally -- filtered to this
      // student. Always live/complete for the PENDING status.
      final pending = await _adminService.getPendingRelationships();
      final pendingForStudent =
          pending.where((r) => r.studentId == widget.student.id);

      // 2. Anything this session already knows about for this student
      // (including ids just re-cached by step 1), re-fetched by id so a
      // previously-pending link that's since been approved/rejected
      // shows its current status.
      final known = await _adminService
          .refreshKnownRelationshipsForStudent(widget.student.id);

      final byId = <String, Relationship>{};
      for (final r in [...pendingForStudent, ...known]) {
        byId[r.id] = r;
      }
      final mine = byId.values.toList()..sort(_byPendingFirstThenMostRecent);

      if (!mounted) return;
      setState(() => _links = mine);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load guardian links.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Pending links first (they need attention); within each group, most
  /// recently created/decided first.
  static int _byPendingFirstThenMostRecent(Relationship a, Relationship b) {
    final aPending = a.status == RelationshipStatus.pending;
    final bPending = b.status == RelationshipStatus.pending;
    if (aPending != bPending) return aPending ? -1 : 1;
    final aDate = a.verifiedAt ?? a.createdAt;
    final bDate = b.verifiedAt ?? b.createdAt;
    if (aDate == null || bDate == null) return 0;
    return bDate.compareTo(aDate);
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
            const SizedBox(height: AppSpacing.lg),
            Text('Guardian Links', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              'Pending links are always current. Already-decided links only '
              'show once this app has seen them at least once.',
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