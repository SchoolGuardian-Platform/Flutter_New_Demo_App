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

// CORRECTED: the previous version of this screen assumed the backend
// matched the `studentId` field against the student's *internal* `User.id`
// (a UUID), so it forced the parent to enter a UUID here. That was wrong --
// `requestParentStudentRelationship` in `relationship.service.ts` actually
// queries `prisma.user.findFirst({ where: { studentId: input.studentId } })`,
// which matches the human-readable Student ID (e.g. "SG-2026-000123", see
// `generateStudentId` in `utils/date.ts`) that's shown on the student's own
// profile page -- NOT their internal UUID. So this field now accepts that
// format instead.
//
// ONE CAVEAT WE CAN'T FIX FROM THIS APP: `createRelationshipSchema` in
// `relationship.validator.ts` still declares `studentId: z.string().uuid()`,
// so the backend's own request validation will reject a non-UUID value
// with a 400 before it ever reaches the lookup above -- i.e. ID-based
// linking is currently broken server-side for any real Student ID. Email
// lookup (`studentEmail`, validated as a plain email) does not have this
// problem, which is why it's the default mode below. Fixing ID lookup for
// real requires relaxing that `.uuid()` constraint on the backend to
// `z.string().min(1)`. Until then this screen surfaces the backend's
// rejection as a clear message rather than a generic error.
final RegExp _studentIdPattern = RegExp(r'^[A-Za-z]{2,}-\d{4}-\d{4,}$');

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
      // A 400 in Student-ID mode most often means the server-side request
      // validator rejected the value before the lookup ever ran (see the
      // caveat above `_studentIdPattern`) -- nudge toward Email, which
      // doesn't hit that validation gap, rather than showing a raw
      // "bad request" message.
      setState(() => _submitError = _mode == _LookupMode.studentId &&
              e.statusCode == 400
          ? "The server didn't accept that Student ID. Try Email instead."
          : e.message);
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
      if (!_studentIdPattern.hasMatch(trimmed)) {
        return 'Enter the Student ID shown on their profile, e.g. '
            'SG-2026-000123.';
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
                      'email is the most reliable option right now -- if '
                      'Student ID lookup is rejected, switch to Email.',
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
                  label: Text('Student ID'),
                  icon: Icon(Icons.badge_outlined),
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
                    ? 'Student ID'
                    : 'Student email',
                hintText: _mode == _LookupMode.studentId
                    ? 'e.g. SG-2026-000123'
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