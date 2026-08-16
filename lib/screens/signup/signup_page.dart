import 'package:flutter/material.dart';
import 'package:schoolguardian_app/screens/verify_eamil_page.dart';
import '../../core/api_exception.dart';
import '../../models/gender.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/password_strength_meter.dart';

/// One Sign Up page, adapted per role. Student/Parent/Teacher each hit a
/// different endpoint (`POST /auth/register/<role>`) and collect slightly
/// different fields, but share the same Guardian Core visual language.
///
/// Field set per role is dictated by `src/validators/auth.validator.ts`:
/// - Student: firstName, lastName, dateOfBirth (REQUIRED), gender
///   (REQUIRED), email, password, confirmPassword.
/// - Parent: firstName, lastName, gender (optional) — NO dateOfBirth field
///   at all — email, password, confirmPassword.
/// - Teacher: firstName, lastName, dateOfBirth (optional), gender
///   (optional), email, password, confirmPassword.
///
/// There is no "Student ID" / "Employee ID" / "School Code" / "Phone"
/// field on any register endpoint — the backend does not accept them at
/// sign-up (see `registration.service.ts`), so those inputs have been
/// removed rather than silently dropped from the submitted payload.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, required this.role});

  static const routeName = '/signup';
  final UserRole role;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _middleName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _authService = AuthService();

  DateTime? _dateOfBirth;
  Gender? _gender;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _submitting = false;
  String? _dobError;
  String? _genderError;
  PasswordStrength _strength = PasswordStrength.empty;

  @override
  void dispose() {
    _firstName.dispose();
    _middleName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  bool get _isParent => widget.role == UserRole.parent;
  bool get _isStudent => widget.role == UserRole.student;
  bool get _isTeacher => widget.role == UserRole.teacher;

  /// Student: required. Teacher: shown, optional. Parent: not on the
  /// backend schema at all, so not shown.
  bool get _showDateOfBirth => _isStudent || _isTeacher;

  /// Shown (optional) on every role's backend schema; required for
  /// students only.
  bool get _showGender => true;

  String get _title {
    switch (widget.role) {
      case UserRole.parent:
        return 'Create Your Parent Account';
      case UserRole.student:
        return 'Create Your Student Account';
      case UserRole.teacher:
        return 'Create Your Teacher Account';
      case UserRole.admin:
        return 'Create Your Account';
    }
  }

  String get _subtitle {
    if (_isParent) return 'Step 1 of verification process.';
    return 'Enter your details to begin the secure activation process.';
  }

  String get _submitLabel {
    switch (widget.role) {
      case UserRole.parent:
        return 'Create Account';
      case UserRole.student:
        return 'Create Student Account';
      case UserRole.teacher:
        return 'Create Teacher Account';
      case UserRole.admin:
        return 'Create Account';
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 16, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select date of birth',
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobError = null;
      });
    }
  }

  /// Returns true only if every field the current role's backend endpoint
  /// requires is present. Runs alongside `_formKey`'s validators because
  /// date-of-birth/gender aren't plain `TextFormField`s.
  bool _validateRoleSpecificFields() {
    setState(() {
      _dobError =
          (_isStudent && _dateOfBirth == null) ? 'Date of birth is required' : null;
      _genderError = (_isStudent && _gender == null) ? 'Gender is required' : null;
    });
    return _dobError == null && _genderError == null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState!.validate();
    final roleFieldsValid = _validateRoleSpecificFields();
    if (!formValid || !roleFieldsValid) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please agree to the Terms and Privacy Policy.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final middleName =
          _middleName.text.trim().isEmpty ? null : _middleName.text.trim();

      switch (widget.role) {
        case UserRole.student:
          await _authService.registerStudent(
            firstName: _firstName.text.trim(),
            middleName: middleName,
            lastName: _lastName.text.trim(),
            dateOfBirth: _formatDate(_dateOfBirth!),
            gender: _gender!,
            email: _email.text.trim(),
            password: _password.text,
            confirmPassword: _confirmPassword.text,
          );
          break;
        case UserRole.parent:
          await _authService.registerParent(
            firstName: _firstName.text.trim(),
            middleName: middleName,
            lastName: _lastName.text.trim(),
            gender: _gender,
            email: _email.text.trim(),
            password: _password.text,
            confirmPassword: _confirmPassword.text,
          );
          break;
        case UserRole.teacher:
          await _authService.registerTeacher(
            firstName: _firstName.text.trim(),
            middleName: middleName,
            lastName: _lastName.text.trim(),
            dateOfBirth: _dateOfBirth != null ? _formatDate(_dateOfBirth!) : null,
            gender: _gender,
            email: _email.text.trim(),
            password: _password.text,
            confirmPassword: _confirmPassword.text,
          );
          break;
        case UserRole.admin:
          // No admin sign-up endpoint; UserRole.hasSignUp keeps this page
          // from ever being reached with role == admin.
          throw ApiException(
            statusCode: 400,
            code: 'ADMIN_REGISTRATION_FORBIDDEN',
            message: 'Admin accounts are provisioned by the institution.',
          );
      }

      if (!mounted) return;
      setState(() => _submitting = false);
      // Every new account is created PENDING (registration.service.ts),
      // but before that pending-approval review is even worth showing,
      // the address itself needs confirming -- same "verify the inbox
      // first" ordering as the rest of the auth flow. VerifyEmailPage
      // takes over from here and hands off to PendingApprovalPage once
      // the email is confirmed (see _continueToPendingApproval there).
      Navigator.of(context).pushNamedAndRemoveUntil(
        VerifyEmailPage.routeName,
        (r) => false,
        arguments: {'email': _email.text.trim()},
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      showBackButton: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AppLogoBadge(size: 56)),
            const SizedBox(height: AppSpacing.md),
            const Center(child: AppWordmark()),
            const SizedBox(height: AppSpacing.lg),
            AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isParent)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.role.icon,
                                size: 14, color: AppColors.onSecondaryContainer),
                            const SizedBox(width: 6),
                            Text(
                              'SIGNING UP AS ${widget.role.name.toUpperCase()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isParent) const SizedBox(height: AppSpacing.md),
                  Text(_title, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    children: [
                      Expanded(
                        child: AuthTextField(
                          label: 'First Name',
                          hint: 'e.g. Jane',
                          controller: _firstName,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AuthTextField(
                          label: 'Last Name',
                          hint: 'e.g. Doe',
                          controller: _lastName,
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Optional on every role's backend schema.
                  AuthTextField(
                    label: 'Middle Name (optional)',
                    hint: 'e.g. Ann',
                    controller: _middleName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_showDateOfBirth) ...[
                    _DateOfBirthField(
                      label: _isStudent
                          ? 'Date of Birth'
                          : 'Date of Birth (optional)',
                      value: _dateOfBirth,
                      onTap: _pickDateOfBirth,
                      errorText: _dobError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  if (_showGender) ...[
                    _GenderField(
                      label: _isStudent ? 'Gender' : 'Gender (optional)',
                      value: _gender,
                      onChanged: (g) => setState(() {
                        _gender = g;
                        _genderError = null;
                      }),
                      errorText: _genderError,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  AuthTextField(
                    label: 'Email Address',
                    hint: 'jane@example.com',
                    controller: _email,
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  AuthTextField(
                    label: 'Password',
                    hint: 'Enter password',
                    controller: _password,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.next,
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
                    onChanged: (v) =>
                        setState(() => _strength = scorePassword(v)),
                    // Mirrors src/utils/password.ts `isStrongPassword`:
                    // >=8 chars, upper, lower, digit, and any
                    // non-alphanumeric character.
                    validator: (v) {
                      if (v == null || v.length < 8) {
                        return 'At least 8 characters';
                      }
                      if (!RegExp(r'[A-Z]').hasMatch(v)) {
                        return 'Add an uppercase letter';
                      }
                      if (!RegExp(r'[a-z]').hasMatch(v)) {
                        return 'Add a lowercase letter';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(v)) {
                        return 'Add a number';
                      }
                      if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
                        return 'Add a special character';
                      }
                      return null;
                    },
                  ),
                  if (_isParent) PasswordStrengthMeter(strength: _strength),
                  const SizedBox(height: AppSpacing.md),

                  AuthTextField(
                    label: 'Confirm Password',
                    hint: 'Confirm password',
                    controller: _confirmPassword,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_reset_outlined,
                    textInputAction: TextInputAction.done,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                        color: AppColors.outline,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) =>
                        v != _password.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (_isParent)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text.rich(
                              TextSpan(
                                style: Theme.of(context).textTheme.bodyMedium,
                                children: const [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // THIS IS THE FIX for "there's no checkbox for
                    // Student/Teacher, so I can't create an account":
                    // this used to be a plain Icon + text with a
                    // GestureDetector on the text (no visible checkbox at
                    // all), so nothing on screen looked tappable, and
                    // `_agreedToTerms` could never become true -- meaning
                    // `_submit` always failed with "Please agree to the
                    // Terms and Privacy Policy." with no way to satisfy
                    // it. Now it's a real Checkbox, same as the Parent
                    // flow, just with wording appropriate to
                    // Student/Teacher verification.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: GestureDetector(
                              onTap: () => setState(
                                  () => _agreedToTerms = !_agreedToTerms),
                              child: Text(
                                'I agree to undergo the secure verification '
                                'process required by your institution, and '
                                'accept the Terms of Service and Privacy '
                                'Policy.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.lg),

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
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_submitLabel),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          (_isParent) ? 'Already have an account? ' : 'Already verified? ',
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                                  '/login', (r) => r.isFirst,
                                  arguments: widget.role),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(_isParent ? 'Log In' : 'Sign In'),
                        ),
                      ],
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
}

/// Label-above-field date picker matching [AuthTextField]'s look. Not a
/// [TextFormField] because there's no keyboard input — tapping anywhere
/// opens [showDatePicker] — so it carries its own [errorText] instead of
/// plugging into `Form` validation directly (see
/// `_validateRoleSpecificFields` in the parent).
class _DateOfBirthField extends StatelessWidget {
  const _DateOfBirthField({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final String? errorText;

  String _display(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurface,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              prefixIcon: const Icon(Icons.cake_outlined,
                  size: 20, color: AppColors.outline),
              errorText: errorText,
            ),
            child: Text(
              value != null ? _display(value!) : '',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.onSurface),
            ),
          ),
        ),
      ],
    );
  }
}

/// Label-above-field gender dropdown matching [AuthTextField]'s look.
/// Values map 1:1 to the backend's `Gender` enum via [GenderX.apiValue].
class _GenderField extends StatelessWidget {
  const _GenderField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final Gender? value;
  final ValueChanged<Gender?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.onSurface,
                letterSpacing: 0,
              ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Gender>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppColors.outline),
          decoration: InputDecoration(
            hintText: 'Select gender',
            prefixIcon: const Icon(Icons.badge_outlined,
                size: 20, color: AppColors.outline),
            errorText: errorText,
          ),
          items: Gender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}