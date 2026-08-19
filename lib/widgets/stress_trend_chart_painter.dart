import 'package:flutter/material.dart';
import '../models/stress_tracker_models.dart';

/// CustomPainter for rendering the smooth stress trend spline chart with Y-axis gridlines & vertical gradient
class StressTrendChartPainter extends CustomPainter {
  StressTrendChartPainter({
    required this.points,
  });

  final List<StressChartPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 24.0;

    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height - bottomMargin;

    // 1. Draw Y-Axis Gridlines & Labels [100, 80, 60, 40, 20, 0]
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    );

    const yLevels = [100, 80, 60, 40, 20, 0];
    for (final level in yLevels) {
      final y = chartHeight * (1.0 - (level / 100.0));

      // Gridline
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y-axis label
      final textPainter = TextPainter(
        text: TextSpan(text: '$level', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    if (points.length < 2) return;

    // 2. Map data points to Canvas coordinates
    final offsets = <Offset>[];
    final stepX = chartWidth / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = leftMargin + (i * stepX);
      final y = chartHeight * (1.0 - (points[i].value / 100.0).clamp(0.0, 1.0));
      offsets.add(Offset(x, y));
    }

    // 3. Build Smooth Spline Path
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlPoint1 = Offset(current.dx + (next.dx - current.dx) / 2, current.dy);
      final controlPoint2 = Offset(current.dx + (next.dx - current.dx) / 2, next.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, next.dx, next.dy);
    }

    // 4. Draw Underneath Gradient Area
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, chartHeight)
      ..lineTo(offsets.first.dx, chartHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFF97316).withValues(alpha: 0.25),
        const Color(0xFF06B6D4).withValues(alpha: 0.03),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Spline Line with Dynamic Vertical Gradient
    final strokeGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFEF4444), // Coral Red Peak
        Color(0xFFF59E0B), // Amber Medium
        Color(0xFF06B6D4), // Cyan Low
      ],
      stops: [0.0, 0.5, 1.0],
    );

    final strokePaint = Paint()
      ..shader = strokeGradient.createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 6. Draw Peak Points Dots
    final dotFillPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length; i++) {
      if (points[i].value >= 60) {
        final pointOffset = offsets[i];
        canvas.drawCircle(pointOffset, 5, dotFillPaint);
        canvas.drawCircle(pointOffset, 5, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StressTrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
