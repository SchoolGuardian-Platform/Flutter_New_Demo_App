import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/relationship.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';

class PendingApprovalsPage extends StatefulWidget {
  const PendingApprovalsPage({super.key, this.initialTabIndex = 0});

  static const routeName = '/admin/pending-approvals';

  final int initialTabIndex;

  @override
  State<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

enum _Category { student, parent, teacher, relationship }

enum _Decision { approve, reject }

class _PendingApprovalsPageState extends State<PendingApprovalsPage>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late final TabController _tabController;

  static const _categories = [
    _Category.student,
    _Category.parent,
    _Category.teacher,
    _Category.relationship,
  ];

  final Map<UserRole, List<User>> _pendingUsers = {};
  List<Relationship> _pendingRelationships = [];

  final Map<_Category, bool> _loading = {};
  final Map<_Category, String?> _error = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _categories.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _categories.length - 1),
    );
    for (final category in _categories) {
      _load(category);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  UserRole? _roleFor(_Category category) {
    switch (category) {
      case _Category.student:
        return UserRole.student;
      case _Category.parent:
        return UserRole.parent;
      case _Category.teacher:
        return UserRole.teacher;
      case _Category.relationship:
        return null;
    }
  }

  Future<void> _load(_Category category) async {
    setState(() {
      _loading[category] = true;
      _error[category] = null;
    });
    try {
      final role = _roleFor(category);
      if (role != null) {
        final list = await _adminService.getPending(role);
        if (!mounted) return;
        setState(() => _pendingUsers[role] = list);
      } else {
        final list = await _adminService.getPendingRelationships();
        if (!mounted) return;
        setState(() => _pendingRelationships = list);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error[category] = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error[category] = 'Something went wrong loading this '
          'list: $e');
    } finally {
      if (mounted) setState(() => _loading[category] = false);
    }
  }

  /// Replaces the entry for [userId] in `_pendingUsers[role]` with
  /// [updated], leaving its position in the list untouched. Returns
  /// silently if the id isn't found (shouldn't happen in practice).
  void _updateUserInList(UserRole role, String userId, User updated) {
    final list = _pendingUsers[role];
    if (list == null) return;
    final index = list.indexWhere((u) => u.id == userId);
    if (index == -1) return;
    list[index] = updated;
  }

  void _updateRelationshipInList(String id, Relationship updated) {
    final index = _pendingRelationships.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _pendingRelationships[index] = updated;
  }

  Future<void> _approveUser(UserRole role, User user) async {
    try {
      await _adminService.approve(role, user.id);
      if (!mounted) return;
      // THIS IS THE FIX: the row used to be removed from the list on
      // approval, so it just vanished from this page with no trace. Now
      // it stays in place with its status swapped to "Approved" so the
      // admin can still see the decision was made.
      setState(() => _updateUserInList(
          role, user.id, user.copyWith(status: AccountStatus.active)));
      _showSnack('${user.fullName} approved.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<void> _rejectUser(UserRole role, User user) async {
    final reason = await _promptReason(title: 'Reject ${user.fullName}?');
    if (reason == null) return;
    try {
      await _adminService.reject(role, user.id, reason: reason.isEmpty ? null : reason);
      if (!mounted) return;
      setState(() => _updateUserInList(
          role, user.id, user.copyWith(status: AccountStatus.rejected)));
      _showSnack('${user.fullName} rejected.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<void> _approveRelationship(Relationship relationship) async {
    try {
      await _adminService.approveRelationship(relationship.id);
      if (!mounted) return;
      setState(() => _updateRelationshipInList(relationship.id,
          relationship.copyWith(status: RelationshipStatus.verified)));
      _showSnack('Guardian link approved.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<void> _rejectRelationship(Relationship relationship) async {
    final reason = await _promptReason(title: 'Reject this guardian link?');
    if (reason == null) return;
    try {
      await _adminService.rejectRelationship(relationship.id,
          reason: reason.isEmpty ? null : reason);
      if (!mounted) return;
      setState(() => _updateRelationshipInList(relationship.id,
          relationship.copyWith(status: RelationshipStatus.rejected)));
      _showSnack('Guardian link rejected.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  /// Tapping a card opens the same Approve/Reject choice used on the
  /// Notifications page, instead of relying only on the inline buttons.
  Future<void> _respondToUser(UserRole role, User user) async {
    if (user.status != null && user.status != AccountStatus.pending) {
      _showSnack('${user.fullName} is already ${user.status!.name}.');
      return;
    }
    final decision = await showDialog<_Decision>(
      context: context,
      builder: (context) => _DecisionDialog(
        title: 'Review ${user.fullName}',
        description: '${user.email}\nRequesting access as ${role.label}.',
      ),
    );
    if (decision == null) return;
    if (decision == _Decision.approve) {
      await _approveUser(role, user);
    } else {
      await _rejectUser(role, user);
    }
  }

  /// Same tap-to-decide pattern for guardian-link requests.
  Future<void> _respondToRelationship(Relationship relationship) async {
    if (relationship.status != RelationshipStatus.pending) {
      _showSnack(
          'This guardian link is already ${relationship.status.name}.');
      return;
    }
    final decision = await showDialog<_Decision>(
      context: context,
      builder: (context) => _DecisionDialog(
        title: '${relationship.relationshipType.label} link request',
        description: 'Parent ID: ${relationship.parentId}\n'
            'Student ID: ${relationship.studentId}',
      ),
    );
    if (decision == null) return;
    if (decision == _Decision.approve) {
      await _approveRelationship(relationship);
    } else {
      await _rejectRelationship(relationship);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _promptReason({required String title}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Reason (optional)',
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.dfault),
              borderSide: const BorderSide(color: AppColors.outlineVariant),
            ),
          ),
          maxLines: 3,
        ),
        actionsAlignment: MainAxisAlignment.end,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pending Approvals'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(text: _label(c))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map(_buildTab).toList(),
      ),
    );
  }

  Widget _buildTab(_Category category) {
    final loading = _loading[category] ?? false;
    final error = _error[category];
    final role = _roleFor(category);
    final count = role != null
        ? (_pendingUsers[role] ?? const <User>[]).length
        : _pendingRelationships.length;
    final isEmpty = count == 0;

    return _buildTabContent(category, loading, error, role, isEmpty);
  }

  Widget _buildTabContent(_Category category, bool loading, String? error,
      UserRole? role, bool isEmpty) {
    if (loading && isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _load(category),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (isEmpty) {
      return Center(
        child: Text(
          'No pending ${_label(category).toLowerCase()}.',
          style: const TextStyle(color: AppColors.outline),
        ),
      );
    }

    if (role != null) {
      final users = _pendingUsers[role] ?? const <User>[];
      return RefreshIndicator(
        onRefresh: () => _load(category),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final user = users[index];
            final decided =
                user.status != null && user.status != AccountStatus.pending;
            return Opacity(
              opacity: decided ? 0.7 : 1,
              child: Material(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: () => _respondToUser(role, user),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: AppColors.outlineVariant, width: 1),
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
                                      user.fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge,
                                    ),
                                  ),
                                  _StatusBadge(status: user.status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: AppSpacing.sm, top: 4),
                          // A decided row is no longer actionable, so it
                          // gets a plain check/cancel glyph instead of the
                          // "tap to act on this" arrow.
                          child: decided
                              ? Icon(
                                  user.status == AccountStatus.active
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 16,
                                  color: user.status == AccountStatus.active
                                      ? AppColors.secondary
                                      : AppColors.error,
                                )
                              : const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(category),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _pendingRelationships.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final relationship = _pendingRelationships[index];
          return _PendingRelationshipCard(
            relationship: relationship,
            onTap: () => _respondToRelationship(relationship),
          );
        },
      ),
    );
  }

  String _label(_Category category) {
    switch (category) {
      case _Category.student:
        return 'Students';
      case _Category.parent:
        return 'Parents';
      case _Category.teacher:
        return 'Teachers';
      case _Category.relationship:
        return 'Guardian Links';
    }
  }
}

/// Approve/Reject confirm dialog — white rounded card, bold title, gray
/// description, right-aligned actions. Matches the "Approve lem hiw?"
/// dialog on the web admin console: a plain "Cancel"-style text button next
/// to a solid red "Reject" and solid indigo "Approve".
class _DecisionDialog extends StatelessWidget {
  const _DecisionDialog({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(description),
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
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.dfault),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(_Decision.reject),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.of(context).pop(_Decision.approve),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final AccountStatus? status;

  @override
  Widget build(BuildContext context) {
    // Entries on this page come from the .../pending endpoints, so this
    // will read "Pending" in practice -- shown explicitly (rather than
    // assumed) since [status] is nullable and this card should still
    // render sensibly if that ever changes.
    final label = switch (status) {
      AccountStatus.pending => 'Pending',
      AccountStatus.active => 'Approved',
      AccountStatus.rejected => 'Rejected',
      AccountStatus.suspended => 'Suspended',
      null => 'Unknown',
    };
    final color = switch (status) {
      AccountStatus.pending => AppColors.warning,
      AccountStatus.active => AppColors.secondary,
      AccountStatus.rejected => AppColors.error,
      AccountStatus.suspended => AppColors.error,
      null => AppColors.outline,
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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PendingRelationshipCard extends StatelessWidget {
  const _PendingRelationshipCard({
    required this.relationship,
    required this.onTap,
  });

  final Relationship relationship;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final decided = relationship.status != RelationshipStatus.pending;
    return Opacity(
      opacity: decided ? 0.7 : 1,
      child: Material(
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
                          _RelationshipStatusBadge(
                              status: relationship.status),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('Parent ID: ${relationship.parentId}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Student ID: ${relationship.studentId}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: AppSpacing.sm, top: 4),
                  child: decided
                      ? Icon(
                          relationship.status == RelationshipStatus.verified
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color:
                              relationship.status == RelationshipStatus.verified
                                  ? AppColors.secondary
                                  : AppColors.error,
                        )
                      : const Icon(Icons.arrow_forward_ios,
                          size: 14, color: AppColors.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RelationshipStatusBadge extends StatelessWidget {
  const _RelationshipStatusBadge({required this.status});

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
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}