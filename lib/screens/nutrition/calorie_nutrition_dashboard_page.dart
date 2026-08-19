import 'package:flutter/material.dart';
import '../../models/nutrition_tracker_models.dart';
import '../../models/user.dart';
import '../../widgets/active_calories_card.dart';
import '../../widgets/calorie_gauge_card.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../widgets/macros_breakdown_card.dart';

class CalorieNutritionDashboardPage extends StatefulWidget {
  const CalorieNutritionDashboardPage({super.key, this.user});

  static const routeName = '/nutrition-dashboard';

  final User? user;

  @override
  State<CalorieNutritionDashboardPage> createState() => _CalorieNutritionDashboardPageState();
}

class _CalorieNutritionDashboardPageState extends State<CalorieNutritionDashboardPage> {
  int _navIndex = 0;

  // Structured Mock Data
  final NutritionCalorieSummary _calorieSummary = const NutritionCalorieSummary(
    baseTarget: 2500,
    consumed: 1268,
    activeBurned: 560,
  );

  final MacroItem _carbs = const MacroItem(
    name: 'Carbs',
    currentGrams: 180,
    targetGrams: 250,
    color: Color(0xFF22C55E), // Emerald Green
  );

  final MacroItem _protein = const MacroItem(
    name: 'Protein',
    currentGrams: 110,
    targetGrams: 150,
    color: Color(0xFFF59E0B), // Amber Orange
  );

  final MacroItem _fat = const MacroItem(
    name: 'Fat',
    currentGrams: 45,
    targetGrams: 65,
    color: Color(0xFF0EA5E9), // Sky Blue
  );

  final ActiveCalorieActivity _activity = const ActiveCalorieActivity(
    totalBurned: 560,
    hourlyTicks: [0.2, 0.3, 0.5, 0.8, 0.4, 0.9, 0.6, 0.7, 0.3, 0.8, 1.0, 0.5, 0.6, 0.4],
  );

  void _showDetailModal(String title, String content) {
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
              content,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
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
    final userName = widget.user != null
        ? '${widget.user!.firstName} ${widget.user!.lastName}'.trim()
        : 'Alex';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Soft off-white background
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
                        // Date Capsule
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.calendar_today, size: 12, color: Color(0xFF0D9488)),
                              SizedBox(width: 4),
                              Text(
                                'TODAY, 12 OCTOBER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome Back, $userName',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),

                    // User Health Avatar Badge (🥑)
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🥑',
                          style: TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Main Calorie Gauge Card
                CalorieGaugeCard(
                  summary: _calorieSummary,
                  onTapNavigation: () => _showDetailModal(
                    'Calorie Target Details',
                    'Your daily calorie budget is based on your BMR of 2500 kcal + 560 kcal active exercise.',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Macros Breakdown Card
                MacrosBreakdownCard(
                  carbs: _carbs,
                  protein: _protein,
                  fat: _fat,
                  onTapNavigation: () => _showDetailModal(
                    'Macro Nutrients Overview',
                    'Carbs: 180g (72% of goal)\nProtein: 110g (73% of goal)\nFat: 45g (69% of goal)',
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Active Calories Card
                ActiveCaloriesCard(
                  activity: _activity,
                  onTapNavigation: () => _showDetailModal(
                    'Active Calories History',
                    'Total 560 kcal burned today from morning run and strength training sessions.',
                  ),
                ),
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
