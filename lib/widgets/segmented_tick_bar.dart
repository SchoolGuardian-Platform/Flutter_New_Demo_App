import 'package:flutter/material.dart';

/// Reusable Segmented Vertical-Tick Bar widget for stress level breakdown duration ratios
class SegmentedTickBar extends StatelessWidget {
  const SegmentedTickBar({
    super.key,
    required this.color,
    required this.filledRatio, // 0.0 to 1.0
    this.totalTicks = 22,
    this.height = 16,
  });

  final Color color;
  final double filledRatio;
  final int totalTicks;
  final double height;

  @override
  Widget build(BuildContext context) {
    final activeCount = (totalTicks * filledRatio.clamp(0.0, 1.0)).round();

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (int i = 0; i < totalTicks; i++)
            Container(
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: i < activeCount ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
