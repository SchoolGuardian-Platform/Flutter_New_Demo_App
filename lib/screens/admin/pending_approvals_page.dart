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

  Future<void> _approveUser(UserRole role, User user) async {
    try {
      await _adminService.approve(role, user.id);
      if (!mounted) return;
      setState(() => _pendingUsers[role]?.removeWhere((u) => u.id == user.id));
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
      setState(() => _pendingUsers[role]?.removeWhere((u) => u.id == user.id));
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
      setState(() =>
          _pendingRelationships.removeWhere((r) => r.id == relationship.id));
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
      setState(() =>
          _pendingRelationships.removeWhere((r) => r.id == relationship.id));
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
    final decision = await showDialog<_Decision>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.fullName),
        content: Text('${user.email}\nRequesting access as ${role.label}.'),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(_Decision.reject),
              child: const Text('Reject'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_Decision.approve),
              child: const Text('Approve'),
            ),
          ),
        ],
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
    final decision = await showDialog<_Decision>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${relationship.relationshipType.label} link request'),
        content: Text(
          'Parent ID: ${relationship.parentId}\n'
          'Student ID: ${relationship.studentId}',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(_Decision.reject),
              child: const Text('Reject'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_Decision.approve),
              child: const Text('Approve'),
            ),
          ),
        ],
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
            return Material(
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
                    Text(
                      '${relationship.relationshipType.label} link request',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    Text('Parent ID: ${relationship.parentId}',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('Student ID: ${relationship.studentId}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
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
}