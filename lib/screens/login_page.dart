import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../models/account_status.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../screens/dashboard/dashboard_page.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.role});

  static const routeName = '/login';
  final UserRole? role;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _submitting = false;

  UserRole get _role => widget.role ?? UserRole.parent;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _demoLogin({
    required String email,
    required UserRole role,
    required String firstName,
    required String lastName,
  }) {
    final demoUser = User(
      id: 'demo-${role.name}',
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      status: AccountStatus.active,
      studentId: role == UserRole.student ? 'STU-1001' : null,
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      DashboardPage.routeName,
      (route) => false,
      arguments: demoUser,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      // POST /auth/login (email + password only — the backend has no
      // phone-based login, see auth.validator.ts `loginSchema`).
      final result = await _authService.login(
        email: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // Login only ever succeeds for ACTIVE accounts (PENDING/REJECTED/
      // SUSPENDED all fail with a generic 401 below), so a successful
      // response means the account is active.
      Navigator.of(context).pushNamedAndRemoveUntil(
        DashboardPage.routeName,
        (route) => false,
        arguments: result.user,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const AppLogoBadge(),
            const SizedBox(height: AppSpacing.md),
            Text('SchoolGuardian',
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Secure access to your ${_role.label.toLowerCase()} portal.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Email',
                    hint: 'parent@example.com',
                    controller: _identifierController,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AuthTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) => {},
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    labelTrailing: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/forgot-password'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Forgot password?'),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                      ),
                      const Text('Remember me for 30 days'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '⚡ Quick Dev / Demo Login',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            _DemoChip(
                              label: 'Teacher',
                              icon: Icons.menu_book_outlined,
                              color: Colors.blue.shade700,
                              onTap: () => _demoLogin(
                                email: 'teacher@schoolguardian.app',
                                role: UserRole.teacher,
                                firstName: 'Elizabeth',
                                lastName: 'Vance',
                              ),
                            ),
                            _DemoChip(
                              label: 'Admin',
                              icon: Icons.admin_panel_settings_outlined,
                              color: Colors.purple.shade700,
                              onTap: () => _demoLogin(
                                email: 'admin@gmail.com',
                                role: UserRole.admin,
                                firstName: 'Admin',
                                lastName: 'System',
                              ),
                            ),
                            _DemoChip(
                              label: 'Parent',
                              icon: Icons.family_restroom,
                              color: Colors.teal.shade700,
                              onTap: () => _demoLogin(
                                email: 'parent@example.com',
                                role: UserRole.parent,
                                firstName: 'Marcus',
                                lastName: 'Hayes',
                              ),
                            ),
                            _DemoChip(
                              label: 'Student',
                              icon: Icons.school_outlined,
                              color: Colors.orange.shade800,
                              onTap: () => _demoLogin(
                                email: 'student@example.com',
                                role: UserRole.student,
                                firstName: 'Alexander',
                                lastName: 'Hayes',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_role.hasSignUp)
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/signup/${_role.name}'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Create an account'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              children: [
                Text('Privacy Policy', style: Theme.of(context).textTheme.bodySmall),
                const Text('•', style: TextStyle(color: AppColors.outline)),
                Text('Terms of Service', style: Theme.of(context).textTheme.bodySmall),
                const Text('•', style: TextStyle(color: AppColors.outline)),
                Text('Help Center', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.w600),
      ),
      padding: EdgeInsets.zero,
      backgroundColor: color.withValues(alpha: 0.08),
      side: BorderSide(color: color.withValues(alpha: 0.2)),
      onPressed: onTap,
    );
  }
}
