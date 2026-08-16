import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

/// Reports hub, reachable from every role's dashboard.
///
/// HONEST SCOPE NOTE: `GET /reports/student/{id}/academic|attendance|
/// wellbeing` are all marked `x-implementation-status: planned` in
/// `SchoolGuardian_Final_OpenAPI.yaml` -- i.e. the routes are designed but
/// not live on the backend yet, and per this task's instructions the
/// backend is not being touched here to avoid a merge conflict with
/// ongoing collaborator work. So this screen intentionally does not fire
/// requests that would currently 404; instead it lays out the report
/// categories the API contract already promises, each clearly marked
/// "Coming soon", so the UI is ready to go live the moment those three
/// endpoints ship -- at that point each `_ReportCategoryCard.onTap` just
/// needs a real navigation target instead of the info dialog below.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const routeName = '/reports';

  static const _categories = [
    _ReportCategory(
      icon: Icons.trending_up,
      title: 'Academic Report',
      subtitle: 'Grades, coursework, and progress over time.',
      endpoint: 'GET /reports/student/:id/academic',
    ),
    _ReportCategory(
      icon: Icons.event_available_outlined,
      title: 'Attendance Report',
      subtitle: 'Daily attendance history and patterns.',
      endpoint: 'GET /reports/student/:id/attendance',
    ),
    _ReportCategory(
      icon: Icons.favorite_border,
      title: 'Wellbeing Report',
      subtitle: 'Wellbeing check-ins and trends.',
      endpoint: 'GET /reports/student/:id/wellbeing',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
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
                    'Report data is coming soon — these categories are '
                    "wired up and waiting for the backend's reporting "
                    'endpoints to go live.',
                    style: const TextStyle(
                        color: KukieAccent.ink, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final category in _categories)
            _ReportCategoryCard(
              category: category,
              onTap: () => _showComingSoon(context, category),
            ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, _ReportCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.title),
        content: Text(
          'This report will appear here once ${category.endpoint} is live '
          'on the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _ReportCategory {
  const _ReportCategory({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.endpoint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String endpoint;
}

class _ReportCategoryCard extends StatelessWidget {
  const _ReportCategoryCard({required this.category, required this.onTap});

  final _ReportCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: KukieAccent.violetTint,
            shape: BoxShape.circle,
          ),
          child: Icon(category.icon, color: KukieAccent.violet),
        ),
        title: Text(category.title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(category.subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: const Text('Soon',
              style: TextStyle(fontSize: 11, color: AppColors.outline)),
        ),
      ),
    );
  }
}
