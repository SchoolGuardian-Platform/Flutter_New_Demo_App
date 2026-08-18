import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Parent's "Link a Student" form -- the only screen that creates a new
/// `ParentStudentRelationship`. Backed by `POST /parents/relationships`
/// (`ParentService.requestRelationship`), which the backend accepts with
/// EITHER a student ID OR a student email (never both), plus a
/// relationship type. The created relationship starts as PENDING and
/// needs an admin to approve it before it shows up anywhere else in the
/// app -- this screen is upfront about that in the confirmation dialog
/// rather than implying the student is linked immediately.
class LinkStudentPage extends StatefulWidget {
  const LinkStudentPage({super.key});

  static const routeName = '/parent/link-student';

  @override
  State<LinkStudentPage> createState() => _LinkStudentPageState();
}

enum _LookupMode { studentId, email }

// Backend (`relationship.validator.ts` / `relationship.service.ts`) only
// accepts a UUID here and matches it against the student's *internal*
// `User.id` -- NOT the human-readable `studentId` (e.g. "STU12345") shown
// on the student's own profile page. Since those are two different values
// and there's no endpoint to resolve one into the other, entering the
// "Student ID" a parent would actually be given can never match. Email
// defaults on and is called out as the reliable option; the ID field is
// relabeled so it doesn't imply the profile-page value will work.
final RegExp _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

class _LinkStudentPageState extends State<LinkStudentPage> {
  final _parentService = ParentService();
  final _formKey = GlobalKey<FormState>();
  final _lookupController = TextEditingController();

  _LookupMode _mode = _LookupMode.email;
  RelationshipType _relationshipType = RelationshipType.mother;
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _lookupController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final value = _lookupController.text.trim();
    try {
      await _parentService.requestRelationship(
        studentId: _mode == _LookupMode.studentId ? value : null,
        studentEmail: _mode == _LookupMode.email ? value : null,
        relationshipType: _relationshipType,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Request sent'),
          content: const Text(
            "We've sent your guardian-link request to the school admin "
            "for approval. Once it's approved, this student will appear "
            "under \"Linked Students\".",
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitError = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _validateLookup(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) {
      return _mode == _LookupMode.studentId
          ? 'Enter the student\'s account ID'
          : 'Enter the student\'s email';
    }
    if (_mode == _LookupMode.email) {
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailPattern.hasMatch(trimmed)) {
        return 'Enter a valid email address';
      }
    } else {
      // The backend requires a UUID here -- it is NOT the "Student ID"
      // shown on the student's profile page. Validating the format
      // client-side surfaces that mismatch immediately instead of a
      // generic "not found" error after a round trip to the server.
      if (!_uuidPattern.hasMatch(trimmed)) {
        return 'This must be the student\'s internal account ID (a long '
            'ID like 8f14e2a1-...), not the Student ID on their profile. '
            'If you don\'t have this, use Email instead.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Link a Student')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: KukieAccent.violetTint,
                borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
                border: Border.all(color: KukieAccent.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: KukieAccent.violet),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Requests go to the school admin for approval before '
                      'the link becomes active. Looking the student up by '
                      'email is the reliable option -- Account ID only '
                      'works if you already have their internal system ID, '
                      'not the Student ID shown on their profile.',
                      style: const TextStyle(
                          color: KukieAccent.ink, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Find the student by',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<_LookupMode>(
              segments: const [
                ButtonSegment(
                  value: _LookupMode.studentId,
                  label: Text('Account ID'),
                  icon: Icon(Icons.fingerprint_outlined),
                ),
                ButtonSegment(
                  value: _LookupMode.email,
                  label: Text('Email'),
                  icon: Icon(Icons.mail_outline),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _lookupController.clear();
                });
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _lookupController,
              validator: _validateLookup,
              keyboardType: _mode == _LookupMode.email
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: _mode == _LookupMode.studentId
                    ? 'Student account ID'
                    : 'Student email',
                hintText: _mode == _LookupMode.studentId
                    ? 'Internal account ID -- not the Student ID on their profile'
                    : 'e.g. student@school.edu',
                filled: true,
                fillColor: AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Your relationship to the student',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: DropdownButton<RelationshipType>(
                    isExpanded: true,
                    value: _relationshipType,
                    items: RelationshipType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _relationshipType = value);
                      }
                    },
                  ),
                ),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_submitError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }
}
