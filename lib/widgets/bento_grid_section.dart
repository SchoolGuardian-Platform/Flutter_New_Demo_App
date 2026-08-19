import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/analytics/academic_gpa_progression_page.dart';
import '../screens/biometrics/biometric_health_overview_page.dart';
import '../screens/biometrics/stress_level_dashboard_page.dart';
import '../screens/nutrition/calorie_nutrition_dashboard_page.dart';
import '../screens/student/student_portal_dashboard_page.dart';
import 'bento_academic_card.dart';
import 'bento_health_tile.dart';

/// Full Bento Grid Section hosting Academic and Health Hub modules
class BentoGridSection extends StatelessWidget {
  const BentoGridSection({
    super.key,
    required this.user,
  });

  final User user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Feature Modules & Hub',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '5 Live Bento Modules',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. Academic Hub: Student Portal Dashboard
        BentoAcademicCard(
          title: 'Student Portal Dashboard',
          subtitle: 'Classes, tasks, announcements & schedule',
          badgeText: '● ACTIVE ACADEMIC PORTAL',
          badgeColor: Colors.white,
          badgeBgColor: Colors.white24,
          gradientColors: const [Color(0xFF6366F1), Color(0xFF7C3AED)],
          icon: Icons.dashboard_customize_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            StudentPortalDashboardPage.routeName,
            arguments: user,
          ),
        ),
        const SizedBox(height: 14),

        // 2. GPA Progression & Analytics Card
        BentoAcademicCard(
          title: 'GPA Progression & Analytics',
          subtitle: 'Semester trajectory, grades & target track',
          badgeText: '3.84 GPA • Top 5% Rank',
          badgeColor: const Color(0xFF065F46),
          badgeBgColor: const Color(0xFFA7F3D0),
          gradientColors: const [Color(0xFF0F172A), Color(0xFF1E293B)],
          icon: Icons.auto_graph_rounded,
          onTap: () => Navigator.of(context).pushNamed(
            AcademicGpaProgressionPage.routeName,
            arguments: user,
          ),
        ),
        const SizedBox(height: 16),

        // Health & Wellness Section Title
        const Text(
          'Health & Biometrics Hub',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 12),

        // 2x2 Bento Tiles for Calorie & Stress
        Row(
          children: [
            Expanded(
              child: BentoHealthTile(
                title: 'Calorie Tracker',
                subtitle: 'Radial dial & macros',
                liveMetricBadge: '🔥 1,232 kcal left',
                accentColor: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                icon: Icons.local_fire_department_rounded,
                onTap: () => Navigator.of(context).pushNamed(
                  CalorieNutritionDashboardPage.routeName,
                  arguments: user,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BentoHealthTile(
                title: 'Stress Level',
                subtitle: 'Spline & equalizer',
                liveMetricBadge: '🛡️ Manageable • 46',
                accentColor: const Color(0xFFF97316),
                bgColor: const Color(0xFFFFEDD5),
                icon: Icons.monitor_heart_rounded,
                onTap: () => Navigator.of(context).pushNamed(
                  StressLevelDashboardPage.routeName,
                  arguments: user,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Full-width Biometric Health Overview Tile
        BentoHealthTile(
          title: 'Biometric Health Overview',
          subtitle: 'Multi-sensor sleep, pulse rate & HRV vitals preview',
          liveMetricBadge: '🌙 Sleep 6h 52m • ❤️ 74 bpm • ⚡ HRV 56 ms',
          accentColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFEDE9FE),
          icon: Icons.health_and_safety_rounded,
          isFullWidth: true,
          onTap: () => Navigator.of(context).pushNamed(
            BiometricHealthOverviewPage.routeName,
            arguments: user,
          ),
        ),
      ],
    );
  }
}
