import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'linked_guardians_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key, this.user});

  static const routeName = '/student/profile';
  final User? user;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late String _fullName;
  late String _email;
  late String _studentId;
  late String _schoolCode;
  String _phone = '+1 (555) 432-8765';
  String _dateOfBirth = 'May 18, 2010';
  String _major = 'Computer Science & STEM';
  String _gradeLevel = 'Grade 10';

  @override
  void initState() {
    super.initState();
    _fullName = widget.user?.fullName ?? 'Alexander Hayes';
    _email = widget.user?.email ?? 'alexander.hayes@student.com';
    _studentId = widget.user?.studentId ?? 'STU-1001';
    _schoolCode = widget.user?.schoolCode ?? 'SCH-2026';
  }

  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _fullName);
    final phoneController = TextEditingController(text: _phone);
    final majorController = TextEditingController(text: _major);
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Student Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: majorController,
                  decoration: const InputDecoration(labelText: 'Major / Field of Study'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _fullName = nameController.text.trim();
                  _phone = phoneController.text.trim();
                  _major = majorController.text.trim();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: KukieAccent.success,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Student Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [KukieAccent.violet, KukieAccent.violet.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Text(
                    _fullName.isNotEmpty ? _fullName[0].toUpperCase() : 'S',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Student ID: $_studentId · School Code: $_schoolCode',
                        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _email,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Academic Overview Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatTile(label: 'Semester GPA', value: '3.84 / 4.0'),
                  const SizedBox(
                    height: 32,
                    child: VerticalDivider(),
                  ),
                  _StatTile(label: 'Enrolled Credits', value: '12.0 Cr'),
                  const SizedBox(
                    height: 32,
                    child: VerticalDivider(),
                  ),
                  _StatTile(label: 'Class Rank', value: 'Top 5%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Personal Information Section
          Text(
            'Personal & Account Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: KukieAccent.violet),
                  title: const Text('Full Name'),
                  subtitle: Text(_fullName),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: _showEditProfileDialog,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: KukieAccent.violet),
                  title: const Text('Email Address'),
                  subtitle: Text(_email),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined, color: KukieAccent.violet),
                  title: const Text('Phone Number'),
                  subtitle: Text(_phone),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cake_outlined, color: KukieAccent.violet),
                  title: const Text('Date of Birth'),
                  subtitle: Text(_dateOfBirth),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Enrollment Information Section
          Text(
            'School & Enrollment Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: KukieAccent.violet),
                  title: const Text('Student ID'),
                  subtitle: Text(_studentId),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.school_outlined, color: KukieAccent.violet),
                  title: const Text('School Code'),
                  subtitle: Text(_schoolCode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.grade_outlined, color: KukieAccent.violet),
                  title: const Text('Grade Level'),
                  subtitle: Text(_gradeLevel),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.biotech_outlined, color: KukieAccent.violet),
                  title: const Text('Major / Field of Study'),
                  subtitle: Text(_major),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Linked Guardians Quick Access Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.family_restroom, color: KukieAccent.violet),
              title: const Text('Linked Parents & Guardians'),
              subtitle: const Text('Eleanor Hayes (Mother), Robert Hayes (Father)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LinkedGuardiansPage(studentId: _studentId),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: KukieAccent.violet,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
