import 'package:flutter/material.dart';
import 'package:schoolguardian_app/models/relationship.dart';

import '../../core/api_exception.dart';
import '../../models/guardian_link.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Student's "Linked Guardians" tab -- the verified parents/guardians
/// connected to this student's account. Backed by the one implemented
/// student endpoint, `GET /students/my-guardians`
/// (`StudentService.getMyGuardians`).
class GuardiansPage extends StatefulWidget {
  const GuardiansPage({super.key});

  static const routeName = '/student/guardians';

  @override
  State<GuardiansPage> createState() => _GuardiansPageState();
}

class _GuardiansPageState extends State<GuardiansPage> {
  final _studentService = StudentService();
  List<GuardianLink>? _guardians;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guardians = await _studentService.getMyGuardians();
      if (!mounted) return;
      setState(() => _guardians = guardians);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong loading your guardians.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Linked Guardians')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final guardians = _guardians;

    if (_loading && guardians == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && guardians == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (guardians == null || guardians.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(
              height: 280,
              child: Center(
                child: Text(
                  'No linked guardians yet.',
                  style: TextStyle(color: AppColors.outline),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: guardians.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _GuardianCard(guardian: guardians[index]),
      ),
    );
  }
}

class _GuardianCard extends StatelessWidget {
  const _GuardianCard({required this.guardian});

  final GuardianLink guardian;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: KukieAccent.violetTint,
              shape: BoxShape.circle,
            ),
            // Guardians are always PARENT-role accounts, but the backend
            // response for this endpoint never includes a `role` field
            // (see GuardianLink) -- a fixed family icon is used instead
            // of anything derived from the response.
            child: const Icon(Icons.family_restroom,
                color: KukieAccent.violet, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guardian.fullName, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(guardian.email, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(guardian.relationshipType.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
