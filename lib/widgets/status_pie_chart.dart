import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// One wedge of a [StatusPieChart].
class PieSlice {
  const PieSlice({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;
}

/// A small, dependency-free pie chart (`CustomPainter`, no charting
/// package required) with a label/legend beside it -- same
/// zero-extra-deps approach as `_PendingBarChart` in
/// `screens/admin/admin_overview_tab.dart`, just a different chart shape.
///
/// Renders nothing but an empty-state message if every slice is zero (or
/// the list is empty), rather than drawing a divide-by-zero circle.
class StatusPieChart extends StatelessWidget {
  const StatusPieChart({
    super.key,
    required this.title,
    required this.slices,
    this.size = 96,
  });

  final String title;
  final List<PieSlice> slices;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.outlineVariant),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (total <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('No data yet.', style: TextStyle(color: AppColors.outline)),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CustomPaint(
                    painter: _PiePainter(slices: slices, total: total),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slices
                        .where((s) => s.value > 0)
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: _LegendRow(slice: s, total: total),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.slice, required this.total});

  final PieSlice slice;
  final double total;

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (slice.value / total * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: slice.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(slice.label,
              style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
        ),
        Text('$pct%',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({required this.slices, required this.total});

  final List<PieSlice> slices;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    var startAngle = -90 * (3.1415926535 / 180); // start at 12 o'clock

    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * 2 * 3.1415926535;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
      startAngle += sweep;
    }

    // Donut cutout so the legend's colors read clearly even for a
    // single-slice (100%) chart.
    final holePaint = Paint()..color = AppColors.surfaceContainerLowest;
    canvas.drawCircle(rect.center, size.width * 0.32, holePaint);
  }

  @override
  bool shouldRepaint(covariant _PiePainter oldDelegate) =>
      oldDelegate.slices != slices || oldDelegate.total != total;
}
