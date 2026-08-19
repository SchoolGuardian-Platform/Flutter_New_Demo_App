import 'package:flutter/material.dart';
import '../../models/stress_tracker_models.dart';
import '../../models/user.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../widgets/stress_overview_card.dart';
import '../../widgets/stress_trend_card.dart';
import '../../widgets/stress_trends_preview_card.dart';

class StressLevelDashboardPage extends StatefulWidget {
  const StressLevelDashboardPage({super.key, this.user});

  static const routeName = '/stress-level-dashboard';

  final User? user;

  @override
  State<StressLevelDashboardPage> createState() => _StressLevelDashboardPageState();
}

class _StressLevelDashboardPageState extends State<StressLevelDashboardPage> {
  int _navIndex = 0;

  // Mock Stress Chart Data Points (06:30 AM to 07:30 AM)
  final List<StressChartPoint> _chartPoints = const [
    StressChartPoint(timestamp: '06:30 AM', value: 25.0),
    StressChartPoint(timestamp: '06:40 AM', value: 38.0),
    StressChartPoint(timestamp: '06:50 AM', value: 72.0), // Peak
    StressChartPoint(timestamp: '07:00 AM', value: 55.0),
    StressChartPoint(timestamp: '07:10 AM', value: 42.0),
    StressChartPoint(timestamp: '07:20 AM', value: 68.0), // Peak
    StressChartPoint(timestamp: '07:30 AM', value: 30.0),
  ];

  // Mock Stress Level Breakdown Data (HIGH, MED, LOW)
  final List<StressLevelBreakdownItem> _breakdowns = const [
    StressLevelBreakdownItem(
      levelName: 'HIGH',
      percentage: 20,
      formattedDuration: '0:10:0',
      color: Color(0xFFEF4444),
      filledRatio: 0.20,
    ),
    StressLevelBreakdownItem(
      levelName: 'MED',
      percentage: 59,
      formattedDuration: '0:56:0',
      color: Color(0xFFF59E0B),
      filledRatio: 0.59,
    ),
    StressLevelBreakdownItem(
      levelName: 'LOW',
      percentage: 21,
      formattedDuration: '0:24:0',
      color: Color(0xFF06B6D4),
      filledRatio: 0.21,
    ),
  ];

  // Mock Biometric Trend Metrics
  final List<BiometricTrendMetric> _trendMetrics = const [
    BiometricTrendMetric(
      title: 'Heart Rate Var.',
      value: '68',
      unit: 'ms',
      statusText: 'Optimal HRV',
      icon: Icons.favorite,
      color: Color(0xFF06B6D4),
    ),
    BiometricTrendMetric(
      title: 'Recovery Score',
      value: '85',
      unit: '%',
      statusText: 'Well Rested',
      icon: Icons.battery_charging_full_rounded,
      color: Color(0xFF10B981),
    ),
    BiometricTrendMetric(
      title: 'Resting HR',
      value: '58',
      unit: 'bpm',
      statusText: 'Normal Range',
      icon: Icons.monitor_heart_outlined,
      color: Color(0xFF8B5CF6),
    ),
  ];

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
                backgroundColor: const Color(0xFF06B6D4),
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
            // Scrollable Content Feed
            ListView(
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
                          'Stress Level',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: const [
                            Icon(Icons.shield_moon_outlined, size: 14, color: Color(0xFF06B6D4)),
                            SizedBox(width: 4),
                            Text(
                              'MANAGEABLE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF06B6D4),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // User Status Emoji / Avatar Badge in Soft Yellow Pill
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7), // Soft yellow pill
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

                // 1. Today's Stress Trend Chart Card
                StressTrendCard(
                  points: _chartPoints,
                  onTapNavigation: () => _showDetailModal(
                    'Stress Trend Analysis',
                    'Your stress peak of 72 occurred at 06:50 AM during early morning commute. Current stress level has returned to calm (30).',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Stress Overview Breakdown Card
                StressOverviewCard(
                  breakdowns: _breakdowns,
                  totalDuration: '10:30:00',
                  onTapNavigation: () => _showDetailModal(
                    'Stress Duration Breakdown',
                    'High Stress: 10 mins (20%)\nMedium Stress: 56 mins (59%)\nLow Stress: 24 mins (21%)\nTotal Tracking Duration: 10 hours 30 mins.',
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Trends Section Preview
                StressTrendsPreviewCard(metrics: _trendMetrics),
              ],
            ),

            // 4. Floating Bottom Navigation Bar
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
