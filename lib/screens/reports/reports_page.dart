import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';
import 'academic_report_page.dart';
import 'attendance_report_page.dart';
import 'wellbeing_report_page.dart';

/// Interactive Reports hub, reachable from every role's dashboard.
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const routeName = '/reports';

  static const _categories = [
    _ReportCategory(
      icon: Icons.trending_up,
      title: 'Academic Report',
      subtitle: 'Grades, coursework, and progress over time.',
      routeName: AcademicReportPage.routeName,
    ),
    _ReportCategory(
      icon: Icons.event_available_outlined,
      title: 'Attendance Report',
      subtitle: 'Daily attendance history and patterns.',
      routeName: AttendanceReportPage.routeName,
    ),
    _ReportCategory(
      icon: Icons.favorite_border,
      title: 'Wellbeing Report',
      subtitle: 'Wellbeing check-ins and trends.',
      routeName: WellbeingReportPage.routeName,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reports & Analytics')),
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
                const Icon(Icons.analytics_outlined, color: KukieAccent.violet),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Select a report below to view real-time academic, attendance, and wellbeing metrics.',
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
              onTap: () => Navigator.of(context).pushNamed(category.routeName),
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
    required this.routeName,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String routeName;
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
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 14, color: AppColors.outline),
      ),
    );
  }
}
