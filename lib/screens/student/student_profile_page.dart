import 'package:flutter/material.dart';
import 'package:schoolguardian_app/models/user_role.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';

/// Student's "My Profile" tab. Reuses `GET /auth/me`
/// (`AuthService.getMe`) the same way `AdminProfilePage` does -- a
/// student account is a `User` like any other, so no student-specific
/// backend work is needed to show it.
///
/// Read-only for the same reason as `AdminProfilePage`: there's no
/// `PATCH /auth/me` on the backend yet.
class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, this.initialUser});

  static const routeName = '/student/profile';

  final User? initialUser;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _authService = AuthService();
  User? _user;
  bool _loading = true;
  String? _error;
  bool _sendingReset = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.getMe();
      if (!mounted) return;
      setState(() => _user = user);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Profile')),
      body: user == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(_error ?? 'Could not load profile.'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Center(
                    child: Column(
                      children: [
                        const AppLogoBadge(size: 88),
                        const SizedBox(height: AppSpacing.md),
                        Text(user.fullName,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            user.role.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ProfileCard(children: [
                    if (user.studentId != null && user.studentId!.isNotEmpty)
                      _ProfileRow(
                        icon: Icons.badge_outlined,
                        label: 'Student ID',
                        value: user.studentId!,
                      ),
                    if (user.schoolCode != null && user.schoolCode!.isNotEmpty)
                      _ProfileRow(
                        icon: Icons.apartment_outlined,
                        label: 'School Code',
                        value: user.schoolCode!,
                      ),
                    _ProfileRow(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        value: user.email),
                    if (user.status != null)
                      _ProfileRow(
                        icon: Icons.verified_user_outlined,
                        label: 'Account status',
                        value: user.status == AccountStatus.active
                            ? 'Active'
                            : user.status!.name,
                      ),
                    if (user.createdAt != null)
                      _ProfileRow(
                        icon: Icons.event_outlined,
                        label: 'Student since',
                        value: _formatDate(user.createdAt!),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: _sendingReset ? null : _changePassword,
                    icon: _sendingReset
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_outline),
                    label: Text(
                        _sendingReset ? 'Sending…' : 'Change Password'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit profile (coming soon)'),
                  ),
                ],
              ),
            ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Sends a password-reset email to the student's own address, reusing
  /// `POST /auth/forgot-password` -- same approach as
  /// `AdminProfilePage._changePassword`; there is no separate "change
  /// password while logged in" endpoint on the backend.
  Future<void> _changePassword() async {
    final user = _user;
    if (user == null || _sendingReset) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password?'),
        content: Text(
          "We'll email a password reset link to ${user.email}. "
          'Follow that link to set a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sendingReset = true);
    try {
      await _authService.forgotPassword(user.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset link sent to ${user.email}.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}
