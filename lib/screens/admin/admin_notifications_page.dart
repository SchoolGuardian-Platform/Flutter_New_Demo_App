import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import 'pending_approvals_page.dart';

enum _Decision { approve, reject }

/// Admin's notification feed: one card per thing waiting on a decision,
/// across every category (new students, new parents, new teachers,
/// guardian-link requests). This is the piece that was missing entirely
/// before -- a new user's registration created a PENDING account in the
/// database, but nothing on the admin side ever surfaced that fact. Now
/// it does, every time this page (or the dashboard's notification bell)
/// loads.
///
/// Built entirely on the four already-implemented `GET .../pending`
/// endpoints via `AdminService.getPendingSummary()` -- the OpenAPI spec's
/// dedicated `/notifications` endpoint is marked
/// `x-implementation-status: planned` (not live on the backend yet), so
/// this intentionally does not depend on it and will keep working exactly
/// as-is once that endpoint ships.
class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  static const routeName = '/admin/notifications';

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _adminService = AdminService();
  PendingSummary _summary = PendingSummary.empty;
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
      final summary = await _adminService.getPendingSummary();
      if (!mounted) return;
      setState(() => _summary = summary);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCategory(int tabIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PendingApprovalsPage(initialTabIndex: tabIndex),
    ));
  }

  /// THIS IS THE FIX: tapping a notification tile previously just
  /// navigated to the full Pending Approvals page and left the admin to
  /// find the right row themselves. Now it opens the approve/reject
  /// choice immediately, for that exact person, right from the
  /// notification -- no extra navigation required.
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

  Future<void> _approveUser(UserRole role, User user) async {
    try {
      await _adminService.approve(role, user.id);
      if (!mounted) return;
      setState(
          () => _summary = _summary.withoutUser(role: role, userId: user.id));
      _showSnack('${user.fullName} approved.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

  Future<void> _rejectUser(UserRole role, User user) async {
    final reason = await _promptReason(title: 'Reject ${user.fullName}?');
    if (reason == null) return; // cancelled
    try {
      await _adminService.reject(role, user.id,
          reason: reason.isEmpty ? null : reason);
      if (!mounted) return;
      setState(
          () => _summary = _summary.withoutUser(role: role, userId: user.id));
      _showSnack('${user.fullName} rejected.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
  }

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

  Future<void> _approveRelationship(Relationship relationship) async {
    try {
      await _adminService.approveRelationship(relationship.id);
      if (!mounted) return;
      setState(() =>
          _summary = _summary.withoutRelationship(relationship.id));
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
          _summary = _summary.withoutRelationship(relationship.id));
      _showSnack('Guardian link rejected.');
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Something went wrong: $e');
    }
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
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _summary.total == 0) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _summary.total == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_summary.total == 0) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.notifications_none, size: 48, color: AppColors.outline),
            SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                "You're all caught up.\nNo pending requests right now.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.outline),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final user in _summary.students)
            _NotificationTile(
              icon: Icons.school_outlined,
              title: 'New student registration',
              subtitle: '${user.fullName} · ${user.email}',
              onTap: () => _respondToUser(UserRole.student, user),
              onViewList: () => _openCategory(0),
            ),
          for (final user in _summary.parents)
            _NotificationTile(
              icon: Icons.family_restroom,
              title: 'New parent registration',
              subtitle: '${user.fullName} · ${user.email}',
              onTap: () => _respondToUser(UserRole.parent, user),
              onViewList: () => _openCategory(1),
            ),
          for (final user in _summary.teachers)
            _NotificationTile(
              icon: Icons.menu_book_outlined,
              title: 'New teacher registration',
              subtitle: '${user.fullName} · ${user.email}',
              onTap: () => _respondToUser(UserRole.teacher, user),
              onViewList: () => _openCategory(2),
            ),
          for (final relationship in _summary.relationships)
            _NotificationTile(
              icon: Icons.link,
              title: 'Guardian link request',
              subtitle:
                  '${relationship.relationshipType.label} · parent ${relationship.parentId.substring(0, 8)}…',
              onTap: () => _respondToRelationship(relationship),
              onViewList: () => _openCategory(3),
            ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onViewList,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// Opens the approve/reject dialog for this exact item.
  final VoidCallback onTap;

  /// Falls back to the full Pending Approvals list for this category, in
  /// case the admin wants to see it alongside the rest of the queue
  /// instead of deciding on it right here.
  final VoidCallback onViewList;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primaryFixed,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: IconButton(
          icon: const Icon(Icons.list_alt_outlined,
              size: 18, color: AppColors.outline),
          tooltip: 'View full list',
          onPressed: onViewList,
        ),
      ),
    );
  }
}