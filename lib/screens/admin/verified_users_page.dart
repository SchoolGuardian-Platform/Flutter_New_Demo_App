import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Admin's "Users" directory — every already-verified (ACTIVE) account,
/// grouped by category with a tab each for Students, Teachers, and
/// Parents. Backed by `GET /admin/users/verified?role=...`
/// (`AdminService.getActive`), which is separate from the pending-review
/// queues on `PendingApprovalsPage`. Unlike a purely read-only directory,
/// each row also lets the admin permanently remove the account via
/// `DELETE /admin/users/:id` (`AdminService.deleteUser`).
class VerifiedUsersPage extends StatefulWidget {
  const VerifiedUsersPage({super.key});

  static const routeName = '/admin/users';

  @override
  State<VerifiedUsersPage> createState() => _VerifiedUsersPageState();
}

class _VerifiedUsersPageState extends State<VerifiedUsersPage>
    with SingleTickerProviderStateMixin {
  final _adminService = AdminService();
  late final TabController _tabController;

  static const _roles = [UserRole.student, UserRole.teacher, UserRole.parent];

  final Map<UserRole, List<User>> _users = {};
  final Map<UserRole, bool> _loading = {};
  final Map<UserRole, String?> _error = {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
    for (final role in _roles) {
      _load(role);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load(UserRole role) async {
    setState(() {
      _loading[role] = true;
      _error[role] = null;
    });
    try {
      final list = await _adminService.getActive(role);
      if (!mounted) return;
      setState(() => _users[role] = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error[role] = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error[role] = 'Something went wrong loading this list.');
    } finally {
      if (mounted) setState(() => _loading[role] = false);
    }
  }

  Future<void> _loadAll() => Future.wait(_roles.map(_load));

  Future<void> _confirmAndDelete(UserRole role, User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove user?'),
        content: Text(
          'This permanently deletes ${user.fullName}\'s (${user.email}) '
          'account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _adminService.deleteUser(user.id);
      if (!mounted) return;
      setState(() {
        _users[role] = (_users[role] ?? const <User>[])
            .where((u) => u.id != user.id)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.fullName} removed.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove this user.')),
      );
    }
  }

  List<User> _filtered(UserRole role) {
    final list = _users[role] ?? const <User>[];
    if (_query.isEmpty) return list;
    final q = _query.toLowerCase();
    return list
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            (u.studentId ?? '').toLowerCase().contains(q))
        .toList();
  }

  String _label(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Students';
      case UserRole.teacher:
        return 'Teachers';
      case UserRole.parent:
        return 'Parents';
      case UserRole.admin:
        return 'Admins';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _roles.map((r) => Tab(text: _label(r))).toList(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or ID',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _roles.map(_buildTab).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(UserRole role) {
    final loading = _loading[role] ?? false;
    final error = _error[role];
    final users = _filtered(role);

    if (loading && (_users[role] ?? const <User>[]).isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && (_users[role] ?? const <User>[]).isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => _load(role),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadAll,
        child: ListView(
          children: [
            SizedBox(
              height: 240,
              child: Center(
                child: Text(
                  _query.isEmpty
                      ? 'No verified ${_label(role).toLowerCase()} yet.'
                      : 'No matches for "$_query".',
                  style: const TextStyle(color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: users.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _VerifiedUserCard(
          user: users[index],
          onDelete: () => _confirmAndDelete(role, users[index]),
        ),
      ),
    );
  }
}

class _VerifiedUserCard extends StatelessWidget {
  const _VerifiedUserCard({required this.user, required this.onDelete});

  final User user;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: KukieAccent.violetTint,
              shape: BoxShape.circle,
            ),
            child: Icon(user.role.icon, color: KukieAccent.violet, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(user.fullName,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                if (user.studentId != null && user.studentId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('ID: ${user.studentId}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Remove user',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}