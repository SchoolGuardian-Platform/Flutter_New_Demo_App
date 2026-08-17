import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/kukie_accent.dart';

class WellbeingReportPage extends StatelessWidget {
  const WellbeingReportPage({super.key, this.studentId = 'STU-1001'});

  static const routeName = '/reports/wellbeing';
  final String studentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Wellbeing Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.deepPurple.shade900],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wellbeing & Social Balance Score',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  '92 / 100 · Excellent',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Student ID: $studentId · Alexander Hayes',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Wellness Indicators',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _WellnessCard(
            title: 'Academic Engagement',
            rating: 'High (95%)',
            description: 'Participates actively in STEM lectures and group problem-solving.',
            icon: Icons.psychology,
            color: Colors.blue,
          ),
          const _WellnessCard(
            title: 'Peer Interaction & Teamwork',
            rating: 'Strong (90%)',
            description: 'Collaborates effectively on robotics and computer science projects.',
            icon: Icons.groups,
            color: Colors.purple,
          ),
          const _WellnessCard(
            title: 'Stress & Focus Management',
            rating: 'Balanced (88%)',
            description: 'Shows good focus during exam periods and manages workload well.',
            icon: Icons.sentiment_satisfied_alt,
            color: Colors.teal,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Teacher Guidance Log',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
              border: Border.all(color: KukieAccent.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dr. Elizabeth Vance (STEM Faculty)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '"Alexander shows great enthusiasm for robotics. Continued participation in extra-curricular STEM events will further build his leadership skills."',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessCard extends StatelessWidget {
  const _WellnessCard({
    required this.title,
    required this.rating,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String rating;
  final String description;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(KukieAccent.cardRadius),
        border: Border.all(color: KukieAccent.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(rating,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: color,
                            fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
