import 'package:flutter/material.dart';
import '../core/api_exception.dart';
import '../models/gender.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/kukie_accent.dart';

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({super.key, required this.user});

  final User user;

  static Future<User?> show(BuildContext context, User user) {
    return showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileModal(user: user),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;

  Gender? _selectedGender;
  DateTime? _selectedDob;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _middleNameController = TextEditingController(text: widget.user.middleName ?? '');
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _phoneController = TextEditingController(text: '');
    _selectedGender = widget.user.gender;
    _selectedDob = widget.user.dateOfBirth;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 15, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: KukieAccent.violet,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final dobString = _selectedDob != null
          ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
          : null;

      final updatedUser = await _authService.updateProfile(
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        gender: _selectedGender,
        dateOfBirth: dobString,
      );

      if (!mounted) return;
      Navigator.of(context).pop(updatedUser);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag Handle & Header ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: KukieAccent.violet, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Edit Personal Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Update your personal profile information.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),

            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ),

            // ── Scrollable Form Body ──
            Flexible(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'First Name *',
                    hint: 'e.g. Nathy',
                    icon: Icons.person_outline_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? 'First name is required' : null,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _middleNameController,
                    label: 'Middle Name',
                    hint: 'e.g. Syu',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Last Name *',
                    hint: 'e.g. Zer',
                    icon: Icons.person_outline_rounded,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Last name is required' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email Address (Disabled field)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: widget.user.email,
                        enabled: false,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Email cannot be changed directly.',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. +251967323308',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  // Gender Select
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gender',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Gender>(
                        initialValue: _selectedGender,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.wc_rounded, size: 20, color: KukieAccent.violet),
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
                        hint: const Text('Select Gender', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                        items: Gender.values.map((g) {
                          return DropdownMenuItem<Gender>(
                            value: g,
                            child: Text(g.label, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedGender = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Date of Birth Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date of Birth',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: KukieAccent.violet),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            _selectedDob != null
                                ? '${_selectedDob!.year}-${_selectedDob!.month.toString().padLeft(2, '0')}-${_selectedDob!.day.toString().padLeft(2, '0')}'
                                : 'Select Date of Birth',
                            style: TextStyle(
                              fontSize: 13,
                              color: _selectedDob != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: KukieAccent.violet,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _saving ? 'Saving Changes…' : 'Save Profile Changes',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: KukieAccent.violet),
            hintText: hint,
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
      ],
    );
  }
}
