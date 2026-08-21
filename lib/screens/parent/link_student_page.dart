import 'package:flutter/material.dart';

import '../../core/api_exception.dart';
import '../../models/relationship.dart';
import '../../services/parent_service.dart';
import '../../theme/kukie_accent.dart';

/// Parent's "Link a Student" form -- request a new `ParentStudentRelationship`.
/// Backed by `POST /parents/relationships` (`ParentService.requestRelationship`).
class LinkStudentPage extends StatefulWidget {
  const LinkStudentPage({super.key});

  static const routeName = '/parent/link-student';

  @override
  State<LinkStudentPage> createState() => _LinkStudentPageState();
}

enum _LookupMode { studentId, email }

final RegExp _studentIdPattern = RegExp(r'^[A-Za-z]{2,}-\d{4}-\d{4,}$');

class _LinkStudentPageState extends State<LinkStudentPage> {
  final _parentService = ParentService();
  final _formKey = GlobalKey<FormState>();
  final _lookupController = TextEditingController();

  _LookupMode _mode = _LookupMode.studentId;
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: KukieAccent.violet, size: 26),
              SizedBox(width: 10),
              Text('Request Sent', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            "We've sent your guardian link request to the school administration "
            "for approval. Once approved, this student will appear in your "
            "Family Portal dashboard.",
            style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: KukieAccent.violet,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
          ? 'Enter the student\'s Account ID'
          : 'Enter the student\'s registered email';
    }
    if (_mode == _LookupMode.email) {
      final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailPattern.hasMatch(trimmed)) {
        return 'Enter a valid email address';
      }
    } else {
      if (!_studentIdPattern.hasMatch(trimmed)) {
        return 'Enter the Student ID shown on their profile, e.g. SG-2026-000123';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Link Student Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Info Banner ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: KukieAccent.violetTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: KukieAccent.cardBorder),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: KukieAccent.violet, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Guardian requests are sent to the school administrator for instant verification. You can find your child by their Student ID (e.g. SG-2026-000123) or Email.',
                      style: TextStyle(
                        color: KukieAccent.ink,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Form Container ──
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
                    'Lookup Method',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'Student ID',
                          icon: Icons.badge_outlined,
                          selected: _mode == _LookupMode.studentId,
                          onTap: () {
                            setState(() {
                              _mode = _LookupMode.studentId;
                              _lookupController.clear();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildChoiceChip(
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          selected: _mode == _LookupMode.email,
                          onTap: () {
                            setState(() {
                              _mode = _LookupMode.email;
                              _lookupController.clear();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _mode == _LookupMode.studentId ? 'Student ID *' : 'Student Email *',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _lookupController,
                    validator: _validateLookup,
                    keyboardType: _mode == _LookupMode.email ? TextInputType.emailAddress : TextInputType.text,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        _mode == _LookupMode.studentId ? Icons.badge_outlined : Icons.mail_outline_rounded,
                        size: 20,
                        color: KukieAccent.violet,
                      ),
                      hintText: _mode == _LookupMode.studentId ? 'e.g. SG-2026-000123' : 'e.g. student@school.edu',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KukieAccent.violet, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Relationship to Student *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<RelationshipType>(
                    initialValue: _relationshipType,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.family_restroom_rounded, size: 20, color: KukieAccent.violet),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: KukieAccent.violet, width: 1.5),
                      ),
                    ),
                    items: RelationshipType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _relationshipType = value);
                      }
                    },
                  ),

                  if (_submitError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        _submitError!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: KukieAccent.violet,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        _submitting ? 'Submitting Request…' : 'Send Guardian Request',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? KukieAccent.violetTint : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KukieAccent.violet : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? KukieAccent.violet : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w900 : FontWeight.bold,
                color: selected ? KukieAccent.violet : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}