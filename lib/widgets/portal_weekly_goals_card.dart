import 'package:flutter/material.dart';
import '../models/portal_dashboard_models.dart';
import '../theme/kukie_accent.dart';

class PortalWeeklyGoalsCard extends StatelessWidget {
  const PortalWeeklyGoalsCard({
    super.key,
    required this.goals,
    required this.onAddGoal,
    this.onTapGoal,
  });

  final List<PortalGoalItem> goals;
  final VoidCallback onAddGoal;
  final ValueChanged<PortalGoalItem>? onTapGoal;

  @override
  Widget build(BuildContext context) {
    final totalCompleted = goals.fold<int>(0, (sum, g) => sum + g.completedCount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${goals.length} goals are waiting for you this week!',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: onAddGoal,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('New goal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: KukieAccent.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: const BorderSide(color: KukieAccent.cardBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal Items List
          for (final goal in goals) ...[
            InkWell(
              onTap: onTapGoal != null ? () => onTapGoal!(goal) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Text(
                          '${goal.completedCount}/${goal.totalCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          goal.streakText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Tap to log progress +1 ⚡',
                          style: TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: goal.progressFraction,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE5E7EB),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Footer Row
          Text(
            'Completed $totalCompleted goals for this week',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
