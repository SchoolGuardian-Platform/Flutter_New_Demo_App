import 'package:flutter/material.dart';
import '../models/stress_tracker_models.dart';
import 'stress_trend_chart_painter.dart';

class StressTrendCard extends StatefulWidget {
  const StressTrendCard({
    super.key,
    required this.points,
    required this.onTapNavigation,
  });

  final List<StressChartPoint> points;
  final VoidCallback onTapNavigation;

  @override
  State<StressTrendCard> createState() => _StressTrendCardState();
}

class _StressTrendCardState extends State<StressTrendCard> {
  String _selectedMetric = 'Metric 1';

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.show_chart_rounded, size: 20, color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  Text(
                    "Today's Stress",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF9CA3AF)),
                onPressed: widget.onTapNavigation,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interactive Spline Line Chart with Y-Axis gridlines
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              size: const Size(double.infinity, 180),
              painter: StressTrendChartPainter(points: widget.points),
            ),
          ),
          const SizedBox(height: 8),

          // X-Axis Timestamps Row
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('06:30 AM', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                Text('07:00 AM', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                Text('07:30 AM', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Footer Toggle: Metric Switcher Pills ("Metric 1", "Metric 2")
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _metricPill('Metric 1'),
              const SizedBox(width: 8),
              _metricPill('Metric 2'),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _metricPill(String label) {
    final isSelected = _selectedMetric == label;
    return InkWell(
      onTap: () => setState(() => _selectedMetric = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}
