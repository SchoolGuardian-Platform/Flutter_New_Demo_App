import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class LinkedGuardiansPage extends StatefulWidget {
  const LinkedGuardiansPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/student/linked-guardians';
  final String studentId;

  @override
  State<LinkedGuardiansPage> createState() => _LinkedGuardiansPageState();
}

class _LinkedGuardiansPageState extends State<LinkedGuardiansPage> {
  final List<Map<String, String>> _guardians = [
    {
      'id': 'g-1',
      'name': 'Eleanor Hayes',
      'email': 'eleanor.hayes@parent.com',
      'phone': '+1 (555) 234-5678',
      'relationship': 'MOTHER',
      'status': 'VERIFIED BY DIRECTOR',
      'linkedSince': 'Sep 2025',
    },
    {
      'id': 'g-2',
      'name': 'Robert Hayes',
      'email': 'robert.hayes@parent.com',
      'phone': '+1 (555) 876-5432',
      'relationship': 'FATHER',
      'status': 'VERIFIED BY DIRECTOR',
      'linkedSince': 'Sep 2025',
    },
  ];

  Future<void> _showAddGuardianDialog() async {
    final emailController = TextEditingController();
    String selectedRelation = 'GUARDIAN';
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request Link New Guardian'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your parent/guardian email to send a link verification request to school directors.',
                    style: TextStyle(fontSize: 12.5, color: Colors.black87),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Parent / Guardian Email *',
                      hintText: 'e.g. parent@example.com',
                    ),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: selectedRelation,
                    decoration: const InputDecoration(labelText: 'Relationship Type'),
                    items: const [
                      DropdownMenuItem(value: 'MOTHER', child: Text('Mother')),
                      DropdownMenuItem(value: 'FATHER', child: Text('Father')),
                      DropdownMenuItem(value: 'GUARDIAN', child: Text('Legal Guardian')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other Sponsor')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedRelation = val);
                    },
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
                  final email = emailController.text.trim();
                  setState(() {
                    _guardians.add({
                      'id': 'g-${DateTime.now().millisecondsSinceEpoch}',
                      'name': email.split('@').first,
                      'email': email,
                      'phone': '+1 (555) 000-1122',
                      'relationship': selectedRelation,
                      'status': 'PENDING VERIFICATION',
                      'linkedSince': 'Just Now',
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Link request sent for $email! Awaiting Director approval.'),
                      backgroundColor: KukieAccent.success,
                    ),
                  );
                }
              },
              child: const Text('Send Link Request'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Linked Guardians'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardianDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Link Guardian'),
        backgroundColor: KukieAccent.violet,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                const Icon(Icons.family_restroom, color: KukieAccent.violet),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Parents and legal guardians verified by the Director can access your academic progress and confidential guidance notes.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: KukieAccent.ink,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connected Guardians (${_guardians.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              TextButton.icon(
                onPressed: _showAddGuardianDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Request Link'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._guardians.map((g) => _GuardianCard(guardian: g)),
        ],
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.guardian});

  final Map<String, String> guardian;

  @override
  Widget build(BuildContext context) {
    final isVerified = guardian['status'] == 'VERIFIED BY DIRECTOR';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: KukieAccent.violetTint,
                  child: Icon(
                    guardian['relationship'] == 'MOTHER'
                        ? Icons.face_3
                        : Icons.person,
                    color: KukieAccent.violet,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guardian['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '${guardian['relationship']} · ${guardian['email']}',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                  ),
                  child: Text(
                    guardian['status']!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(guardian['phone']!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                  ],
                ),
                Text(
                  'Linked: ${guardian['linkedSince']}',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
