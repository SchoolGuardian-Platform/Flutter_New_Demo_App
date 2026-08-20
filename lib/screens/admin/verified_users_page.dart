import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/friend_admin_bottom_nav.dart';
import 'admin_profile_page.dart';
import 'manage_users_page.dart';
import 'student_detail_page.dart';

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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Users', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        elevation: 0,
        backgroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF5B5BF7),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF5B5BF7),
          indicatorWeight: 3,
          tabs: _roles.map((r) => Tab(text: _label(r))).toList(),
        ),
      ),
      bottomNavigationBar: FriendAdminBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ManageUsersPage()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProfilePage()),
            );
          }
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search by name, email, or ID',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          // Guardian links only exist between a parent and a student, so
          // only student rows open the detail page.
          onTap: role == UserRole.student
              ? () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => StudentDetailPage(student: users[index]),
                  ))
              : null,
        ),
      ),
    );
  }
}

class _VerifiedUserCard extends StatelessWidget {
  const _VerifiedUserCard({
    required this.user,
    required this.onDelete,
    this.onTap,
  });

  final User user;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(user.role.icon, color: const Color(0xFF5B5BF7), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(
                              color: Color(0xFF15803D),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.studentId != null && user.studentId!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${user.studentId}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 22),
                tooltip: 'Remove user',
              ),
              if (onTap != null)
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}