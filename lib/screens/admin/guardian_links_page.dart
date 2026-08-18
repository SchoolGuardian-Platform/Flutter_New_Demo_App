import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

enum _Decision { approve, reject }

/// Admin's dedicated home for parent↔student guardian links -- both the
/// ones still awaiting a decision AND the ones already decided.
///
/// WHY THIS PAGE EXISTS: previously the only place an admin could see a
/// guardian-link request at all was the "Guardian Links" tab inside
/// Pending Approvals, which -- true to its name -- only ever showed
/// PENDING requests. The moment a link was approved it dropped out of
/// that view and effectively vanished, with nowhere else in the app
/// showing it. This page is reachable directly from the dashboard (not
/// nested inside Pending Approvals) and shows two sections: "Awaiting
/// your decision" and "Recently decided".
///
/// BACKEND GAP: there is no `GET /admin/relationships` (all-statuses)
/// route on this backend -- only `/relationships/pending`,
/// `/relationships/:id`, and the approve/reject actions
/// (`admin.routes.ts`). So "Recently decided" is NOT a complete list of
/// every ever-decided link; it's every relationship id this app session
/// has discovered via the pending queue (or an approve/reject action
/// here), re-fetched by id (`GET /relationships/:id`, the only endpoint
/// that can return a non-pending relationship) to pick up its current
/// status. A link decided before this app ever saw it pending has no
/// discoverable id and won't appear. See
/// `AdminService.refreshAllKnownRelationships` for the full explanation
/// -- closing this gap for real needs a backend endpoint.
class GuardianLinksPage extends StatefulWidget {
  const GuardianLinksPage({super.key});

  static const routeName = '/admin/guardian-links';

  @override
  State<GuardianLinksPage> createState() => _GuardianLinksPageState();
}

class _GuardianLinksPageState extends State<GuardianLinksPage> {
  final _adminService = AdminService();
  List<Relationship> _pending = [];
  List<Relationship> _decided = [];
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
      // Live/complete for PENDING; "known" re-fetches every relationship
      // id this session has ever seen (including ids the pending call
      // above just cached) so previously-pending links that are now
      // decided show their current status. See
      // `AdminService.refreshAllKnownRelationships` for the backend-gap
      // explanation of why this can't just be one call.
      final pending = await _adminService.getPendingRelationships();
      final known = await _adminService.refreshAllKnownRelationships();
      final byId = <String, Relationship>{};
      for (final r in [...pending, ...known]) {
        byId[r.id] = r;
      }
      final all = byId.values.toList();
      if (!mounted) return;
      setState(() {
        _pending = all
            .where((r) => r.status == RelationshipStatus.pending)
            .toList();
        _decided = all
            .where((r) => r.status != RelationshipStatus.pending)
            .toList()
          ..sort((a, b) {
            final aTime = a.verifiedAt ?? a.createdAt ?? DateTime(0);
            final bTime = b.verifiedAt ?? b.createdAt ?? DateTime(0);
            return bTime.compareTo(aTime);
          });
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong loading guardian links: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respondTo(Relationship relationship) async {
    final decision = await showDialog<_Decision>(
      context: context,
      builder: (context) => _DecisionDialog(relationship: relationship),
    );
    if (decision == null) return;
    if (decision == _Decision.approve) {
      await _approve(relationship);
    } else {
      await _reject(relationship);
    }
  }

  Future<void> _approve(Relationship relationship) async {
    try {
      await _adminService.approveRelationship(relationship.id);
      _showSnack('Guardian link approved.');
      await _load();
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<void> _reject(Relationship relationship) async {
    final reason = await _promptReason();
    if (reason == null) return;
    try {
      await _adminService.rejectRelationship(relationship.id,
          reason: reason.isEmpty ? null : reason);
      _showSnack('Guardian link rejected.');
      await _load();
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<String?> _promptReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject this guardian link?'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guardian Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Awaiting your decision',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              )
            else if (_pending.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Nothing waiting on you right now.',
                    style: TextStyle(color: AppColors.outline)),
              )
            else
              ..._pending.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GuardianLinkCard(
                      relationship: r,
                      onTap: () => _respondTo(r),
                    ),
                  )),
            const SizedBox(height: AppSpacing.lg),
            Text('Recently decided',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              'Approved and rejected links stay listed here -- they '
              'don\'t disappear once decided.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              const SizedBox.shrink()
            else if (_decided.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('No guardian links have been decided yet.',
                    style: TextStyle(color: AppColors.outline)),
              )
            else
              ..._decided.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _GuardianLinkCard(relationship: r, onTap: null),
                  )),
          ],
        ),
      ),
    );
  }
}

class _DecisionDialog extends StatelessWidget {
  const _DecisionDialog({required this.relationship});

  final Relationship relationship;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${relationship.relationshipType.label} link request'),
      content: Text(
        'Parent: ${relationship.parent?.fullName ?? relationship.parentId}\n'
        'Student: ${relationship.student?.fullName ?? relationship.studentId}',
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  style:
                      OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => Navigator.of(context).pop(_Decision.reject),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_Decision.approve),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One guardian-link row -- used for both pending (tappable, to
/// approve/reject) and decided (informational only, [onTap] null) items.
///
/// Shows the parent/student's actual name and email when the backend
/// joined that data in (see `Relationship.parent`/`.student`), instead of
/// the raw internal `studentId` foreign key. Also lazily resolves and
/// shows the student's real, human-readable Student ID (e.g.
/// "SG-2026-000123") via `AdminService.getStudentProfile` -- that field
/// isn't included on the relationship endpoints, so it's a small extra
/// fetch, cached after the first lookup.
class _GuardianLinkCard extends StatelessWidget {
  const _GuardianLinkCard({required this.relationship, required this.onTap});

  final Relationship relationship;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decided = relationship.status != RelationshipStatus.pending;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${relationship.relationshipType.label} link request',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        _StatusBadge(status: relationship.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relationship.student != null
                          ? 'Student: ${relationship.student!.fullName} '
                              '(${relationship.student!.email})'
                          : 'Student (internal id): ${relationship.studentId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (relationship.student != null)
                      _StudentIdLine(studentInternalId: relationship.student!.id),
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
                    ],
                  ],
                ),
              ),
              if (!decided)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.sm, top: 4),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.outline),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Resolves and displays the student's real Student ID underneath their
/// name, once loaded. Silently shows nothing on failure (e.g. offline) --
/// this is a nice-to-have detail, not worth blocking or erroring the
/// whole card over.
class _StudentIdLine extends StatefulWidget {
  const _StudentIdLine({required this.studentInternalId});

  final String studentInternalId;

  @override
  State<_StudentIdLine> createState() => _StudentIdLineState();
}

class _StudentIdLineState extends State<_StudentIdLine> {
  final _adminService = AdminService();
  String? _studentId;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final profile = await _adminService.getStudentProfile(widget.studentInternalId);
      if (!mounted) return;
      setState(() => _studentId = profile.studentId);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || (_studentId == null || _studentId!.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Text(
        'Student ID: ${_studentId!}',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: KukieAccent.violet, fontWeight: FontWeight.w600),
      ),
    );
  }
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