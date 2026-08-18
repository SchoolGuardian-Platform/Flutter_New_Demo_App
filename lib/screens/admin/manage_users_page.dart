import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'pending_approvals_page.dart';

/// Admin's "Manage Users" hub -- reviewing and acting on every account/link
/// waiting on a decision, grouped by category with live counts.
///
/// This is deliberately separate from the "Users" tab (`VerifiedUsersPage`,
/// reachable from the dashboard nav bar), which is the searchable directory
/// of already-verified accounts backed by `GET /admin/users/verified` and
/// supports removing an account. This hub stays focused on the pending
/// queues; browsing/removing verified accounts lives on that other page.
class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  static const routeName = '/admin/manage-users';

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final _adminService = AdminService();
  PendingSummary? _summary;
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

  void _openTab(int index) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PendingApprovalsPage(initialTabIndex: index),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manage Users')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [KukieAccent.violet, KukieAccent.violetDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.manage_accounts_outlined,
                      color: Colors.white, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loading
                              ? 'Loading…'
                              : '${summary?.total ?? 0} account${(summary?.total ?? 0) == 1 ? '' : 's'} need a decision',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Review new registrations and guardian links.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            _CategoryCard(
              icon: Icons.school_outlined,
              title: 'Students',
              count: summary?.students.length ?? 0,
              onTap: () => _openTab(0),
            ),
            _CategoryCard(
              icon: Icons.family_restroom,
              title: 'Parents',
              count: summary?.parents.length ?? 0,
              onTap: () => _openTab(1),
            ),
            _CategoryCard(
              icon: Icons.menu_book_outlined,
              title: 'Teachers',
              count: summary?.teachers.length ?? 0,
              onTap: () => _openTab(2),
            ),
            _CategoryCard(
              icon: Icons.link,
              title: 'Guardian Links',
              count: summary?.relationships.length ?? 0,
              onTap: () => _openTab(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

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
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: KukieAccent.violetTint,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: KukieAccent.violet),
        ),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(
          count == 0 ? 'Nothing pending' : '$count awaiting review',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: count > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              )
            : const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppColors.outline),
      ),
    );
  }
}