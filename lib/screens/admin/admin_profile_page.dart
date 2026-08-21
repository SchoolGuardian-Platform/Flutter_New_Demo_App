import 'package:flutter/material.dart';
import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/user.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../theme/kukie_accent.dart';
import '../../widgets/edit_profile_modal.dart';
import '../../widgets/friend_admin_bottom_nav.dart';
import '../landing_page.dart';
import 'manage_users_page.dart';
import 'verified_users_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key, this.initialUser});

  static const routeName = '/admin/profile';
  final User? initialUser;

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final _authService = AuthService();
  User? _user;
  bool _loading = true;
  String? _error;
  bool _sendingReset = false;
  bool _loggingOut = false;

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
    final isAdmin = user?.role == UserRole.admin || widget.initialUser?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !isAdmin,
        title: Row(
          children: const [
            Icon(Icons.admin_panel_settings_rounded, color: KukieAccent.violet, size: 24),
            SizedBox(width: 10),
            Text(
              'My Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      bottomNavigationBar: isAdmin
          ? FriendAdminBottomNav(
              currentIndex: 3,
              onTap: (index) {
                if (index == 0) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else if (index == 1) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const ManageUsersPage()),
                  );
                } else if (index == 2) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const VerifiedUsersPage()),
                  );
                }
              },
            )
          : null,
      body: user == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(_error ?? 'Could not load profile.'),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(20),
                children: [
                  // ── Hero Banner Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [KukieAccent.violet, KukieAccent.violetDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: KukieAccent.violet.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Text(
                              user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'A',
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                color: KukieAccent.violet,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.label.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Details Information Card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrator Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _infoTile(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email',
                          value: user.email,
                        ),
                        const Divider(height: 20, color: Color(0xFFF1F5F9)),
                        _infoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Account Status',
                          value: user.status == AccountStatus.active ? 'Active' : (user.status?.name ?? 'Active'),
                          isStatus: true,
                        ),
                        if (user.createdAt != null) ...[
                          const Divider(height: 20, color: Color(0xFFF1F5F9)),
                          _infoTile(
                            icon: Icons.event_outlined,
                            label: 'Admin Since',
                            value: _formatDate(user.createdAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Actions Card ──
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Security',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openEditProfileModal,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: KukieAccent.violet, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: KukieAccent.violet,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text(
                              'Edit Profile Details',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _sendingReset ? null : _changePassword,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: KukieAccent.violet, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: KukieAccent.violet,
                            ),
                            icon: _sendingReset
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: KukieAccent.violet),
                                  )
                                : const Icon(Icons.lock_outline_rounded, size: 18),
                            label: Text(
                              _sendingReset ? 'Sending Reset Link…' : 'Change Password',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _loggingOut ? null : _logout,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              foregroundColor: const Color(0xFFEF4444),
                            ),
                            icon: _loggingOut
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                                  )
                                : const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEF4444)),
                            label: Text(
                              _loggingOut ? 'Logging out…' : 'Log Out',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    bool isStatus = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: KukieAccent.violetTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: KukieAccent.violet, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              if (isStatus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _openEditProfileModal() async {
    final user = _user;
    if (user == null) return;
    final updatedUser = await EditProfileModal.show(context, user);
    if (updatedUser != null && mounted) {
      setState(() => _user = updatedUser);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

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
            style: FilledButton.styleFrom(backgroundColor: KukieAccent.violet),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign in again to continue."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loggingOut = true);
    try {
      await _authService.logout();
    } on ApiException {
      // Safe to proceed to landing
    } finally {
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LandingPage.routeName,
          (route) => false,
        );
      }
    }
  }
}
