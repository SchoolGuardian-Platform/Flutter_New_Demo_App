import 'package:flutter/material.dart';
import '../../models/health_overview_models.dart';
import '../../models/user.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../widgets/screen_time_overview_card.dart';
import '../../widgets/sleep_overview_card.dart';
import '../../widgets/stress_score_card.dart';
import '../../widgets/todays_digest_card.dart';
import '../../widgets/vitals_grid_card.dart';

class BiometricHealthOverviewPage extends StatefulWidget {
  const BiometricHealthOverviewPage({super.key, this.user});

  static const routeName = '/biometric-health-overview';

  final User? user;

  @override
  State<BiometricHealthOverviewPage> createState() => _BiometricHealthOverviewPageState();
}

class _BiometricHealthOverviewPageState extends State<BiometricHealthOverviewPage> {
  int _navIndex = 0;

  // Mock Weekly Sleep Data
  final List<SleepDayMetric> _sleepDays = const [
    SleepDayMetric(dayLabel: 'M', hours: 6.5),
    SleepDayMetric(dayLabel: 'T', hours: 7.0),
    SleepDayMetric(dayLabel: 'W', hours: 5.8),
    SleepDayMetric(dayLabel: 'T', hours: 6.2),
    SleepDayMetric(dayLabel: 'F', hours: 7.5),
    SleepDayMetric(dayLabel: 'S', hours: 8.2),
    SleepDayMetric(dayLabel: 'S', hours: 6.8, isHighlighted: true),
  ];

  // Mock Stress Sparkline Values
  final List<double> _stressSparkline = const [0.3, 0.45, 0.25, 0.6, 0.5, 0.46, 0.4];

  // Mock 2x2 Vital Metrics
  final List<VitalMetricItem> _vitals = const [
    VitalMetricItem(
      title: 'Current Weight',
      value: '200',
      unit: 'lbs',
      trendPercentage: '+ 10%',
      isPositiveTrend: true,
      icon: Icons.monitor_weight_outlined,
      accentColor: Color(0xFF10B981),
    ),
    VitalMetricItem(
      title: 'Active Min',
      value: '294',
      unit: 'min',
      trendPercentage: '↑ Active',
      isPositiveTrend: true,
      icon: Icons.directions_run_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    VitalMetricItem(
      title: 'Last Heart Rate',
      value: '74',
      unit: 'bpm',
      trendPercentage: '+ 1%',
      isPositiveTrend: true,
      icon: Icons.favorite_border_rounded,
      accentColor: Color(0xFFEF4444),
    ),
    VitalMetricItem(
      title: 'Last HRV',
      value: '56',
      unit: 'ms',
      trendPercentage: '↓ 10%',
      isPositiveTrend: false,
      icon: Icons.graphic_eq_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
  ];

  // Mock Today's Digest Recommendation
  final DigestRecommendation _digest = const DigestRecommendation(
    categoryLabel: "TODAY'S DIGEST",
    headline: 'Keep your next meal light and filling',
    bodyText: "You're at 67% of your calories, macros look good—carbs are a bit low.",
    icon: Icons.lightbulb_outline_rounded,
  );

  void _showDetailModal(String title, String description) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Soft off-white / light slate
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Feed
            ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                // Top Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: const [
                            Text(
                              '• 126 DATA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF6B7280),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // User Status Emoji Badge (🥑)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🥑',
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Sleep Overview Card
                SleepOverviewCard(
                  durationText: '6h 52m',
                  qualityStatus: 'Good',
                  weeklyDays: _sleepDays,
                  onTapNavigation: () => _showDetailModal(
                    'Sleep Analysis Details',
                    'You achieved 6 hours 52 minutes of sleep last night (82% efficiency). Deep sleep: 1h 40m, REM: 1h 55m.',
                  ),
                ),
                const SizedBox(height: 16),

                // 1b. Phone Screen Time Overview Card
                ScreenTimeOverviewCard(
                  metric: const ScreenTimeMetric(
                    totalTimeText: '4h 12m',
                    trendText: '↓ 45m vs yesterday',
                    pickupsCount: 42,
                    firstPickupTime: '07:15 AM',
                    categoryBreakdown: {
                      'Study & Reading': 0.42,
                      'Educational Media': 0.30,
                      'Social & Chat': 0.28,
                    },
                  ),
                  onTapDetails: () => _showDetailModal(
                    'Phone Screen Time Breakdown',
                    'Total active screen time today is 4 hours 12 minutes (down 45 minutes from yesterday). Primary categories: 1h 48m Study Apps, 1h 15m Educational Media, 1h 09m Social Messaging.',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Stress Score Card
                StressScoreCard(
                  score: 46,
                  statusText: 'Manageable',
                  sparklineValues: _stressSparkline,
                  onTapNavigation: () => _showDetailModal(
                    'Real-Time Stress Variability',
                    'Your stress score of 46 is in the manageable green zone. HRV is steady at 56 ms.',
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 2x2 Vital Metrics Grid
                VitalsGridSection(vitals: _vitals),
                const SizedBox(height: 16),

                // 4. Today's Digest Recommendation Card
                TodaysDigestCard(digest: _digest),
              ],
            ),

            // 5. Floating Bottom Navigation Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingBottomNavBar(
                currentIndex: _navIndex,
                onTap: (idx) => setState(() => _navIndex = idx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
