import 'package:flutter/material.dart';
import 'package:schoolguardian_app/models/relationship.dart';

import '../../core/api_exception.dart';
import '../../models/account_status.dart';
import '../../models/student_link.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'link_student_page.dart';

/// Parent's "Linked Students" tab -- the verified students connected to
/// this parent's account. Backed by `GET /parents/my-students`
/// (`ParentService.getMyStudents`). The FAB opens
/// `LinkStudentPage` to request a new link; this list refreshes when
/// that screen is popped, since a newly-requested link won't show up
/// here until an admin approves it, but it's cheap to re-check.
class MyStudentsPage extends StatefulWidget {
  const MyStudentsPage({super.key});

  static const routeName = '/parent/my-students';

  @override
  State<MyStudentsPage> createState() => _MyStudentsPageState();
}

class _MyStudentsPageState extends State<MyStudentsPage> {
  final _parentService = ParentService();
  List<StudentLink>? _students;
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
      final students = await _parentService.getMyStudents();
      if (!mounted) return;
      setState(() => _students = students);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong loading your students.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openLinkStudent() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LinkStudentPage()),
    );
    if (linked == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Linked Students')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openLinkStudent,
        icon: const Icon(Icons.add),
        label: const Text('Link a Student'),
      ),
    );
  }

  Widget _buildBody() {
    final students = _students;

    if (_loading && students == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && students == null) {
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
    if (students == null || students.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: const [
            SizedBox(
              height: 320,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No linked students yet. Tap "Link a Student" below to '
                    'send a request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.outline),
                  ),
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
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl2),
        itemCount: students.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) => _StudentLinkCard(link: students[index]),
      ),
    );
  }
}

class _StudentLinkCard extends StatelessWidget {
  const _StudentLinkCard({required this.link});

  final StudentLink link;

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
            child: const Icon(Icons.school_outlined, color: KukieAccent.violet, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(link.fullName,
                          style: Theme.of(context).textTheme.labelLarge),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        link.relationshipType.label,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(link.email, style: Theme.of(context).textTheme.bodySmall),
                if (link.status != null && link.status != AccountStatus.active)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Student account status: ${link.status!.name}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.warning),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
