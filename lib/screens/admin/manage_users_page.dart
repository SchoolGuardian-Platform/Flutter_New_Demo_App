import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/friend_admin_bottom_nav.dart';
import 'admin_profile_page.dart';
import 'class_section_management_page.dart';
import 'pending_approvals_page.dart';
import 'verified_users_page.dart';

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
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      bottomNavigationBar: FriendAdminBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
          } else if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const VerifiedUsersPage()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AdminProfilePage()),
            );
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF5B5BF7),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B5BF7).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
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
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Review new registrations and guardian links.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClassSectionManagementPage()),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.class_outlined, color: Color(0xFF5B5BF7)),
                ),
                title: const Text('Class & Section Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text(
                  'Manage classes, sections, rooms, student rosters & teacher assignments.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
              ),
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