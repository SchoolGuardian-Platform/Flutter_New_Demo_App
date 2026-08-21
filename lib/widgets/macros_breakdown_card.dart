import 'package:flutter/material.dart';
import '../models/nutrition_tracker_models.dart';
import 'concentric_macro_rings_painter.dart';

class MacrosBreakdownCard extends StatelessWidget {
  const MacrosBreakdownCard({
    super.key,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.onTapNavigation,
  });

  final MacroItem carbs;
  final MacroItem protein;
  final MacroItem fat;
  final VoidCallback onTapNavigation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          // Header Row with Green Status Dot Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Macros Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                onPressed: onTapNavigation,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Left Side: 3 Macro Metrics (Carbs, Protein, Fat)
              Expanded(
                child: Column(
                  children: [
                    _macroRow(carbs),
                    const SizedBox(height: 12),
                    _macroRow(protein),
                    const SizedBox(height: 12),
                    _macroRow(fat),
                  ],
                ),
              ),

              // Right Side: Concentric Triple-Ring Progress Graph
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  size: const Size(100, 100),
                  painter: ConcentricMacroRingsPainter(
                    carbsFraction: carbs.fraction,
                    proteinFraction: protein.fraction,
                    fatFraction: fat.fraction,
                    carbsColor: carbs.color,
                    proteinColor: protein.color,
                    fatColor: fat.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroRow(MacroItem item) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                '${item.currentGrams}g / ${item.targetGrams}g',
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Text(
          '${item.percentage}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: item.color,
          ),
        ),
      ],
    );
  }
}
