import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/gpa_analytics_models.dart';

/// CustomPainter for rendering the smooth GPA progression spline chart with gradient area fill & target line
class GpaProgressionSplinePainter extends CustomPainter {
  GpaProgressionSplinePainter({
    required this.points,
    required this.targetGpa,
  });

  final List<SemesterGpaPoint> points;
  final double targetGpa;

  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 28.0;

    final chartWidth = size.width - leftMargin;
    final chartHeight = size.height - bottomMargin;

    const minGpa = 3.0;
    const maxGpa = 4.0;

    double mapY(double gpa) {
      final normalized = ((gpa - minGpa) / (maxGpa - minGpa)).clamp(0.0, 1.0);
      return chartHeight * (1.0 - normalized);
    }

    // 1. Draw Y-Axis Gridlines & Scale Labels [4.0, 3.8, 3.6, 3.4, 3.2, 3.0]
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final labelStyle = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: Color(0xFF94A3B8),
    );

    const gpaSteps = [4.0, 3.8, 3.6, 3.4, 3.2, 3.0];
    for (final level in gpaSteps) {
      final y = mapY(level);

      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width, y),
        gridPaint,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: level.toStringAsFixed(1), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6, y - (textPainter.height / 2)),
      );
    }

    // 2. Draw Dashed Target GPA Line (3.80 Target)
    final targetY = mapY(targetGpa);
    final targetPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = leftMargin;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(math.min(startX + dashWidth, size.width), targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // Target Label Badge
    final targetTextPainter = TextPainter(
      text: TextSpan(
        text: 'Target ${targetGpa.toStringAsFixed(2)}',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD97706),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    targetTextPainter.paint(
      canvas,
      Offset(size.width - targetTextPainter.width - 4, targetY - 14),
    );

    if (points.length < 2) return;

    // 3. Map Semester Coordinates
    final offsets = <Offset>[];
    final stepX = chartWidth / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = leftMargin + (i * stepX);
      final y = mapY(points[i].gpa);
      offsets.add(Offset(x, y));
    }

    // 4. Build Smooth Spline Curve Path
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final controlPoint1 = Offset(current.dx + (next.dx - current.dx) / 2, current.dy);
      final controlPoint2 = Offset(current.dx + (next.dx - current.dx) / 2, next.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, next.dx, next.dy);
    }

    // 5. Draw Area Gradient Fill Under Curve
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, chartHeight)
      ..lineTo(offsets.first.dx, chartHeight)
      ..close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6366F1).withValues(alpha: 0.28),
        const Color(0xFF06B6D4).withValues(alpha: 0.02),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 6. Draw Gradient Spline Line (Indigo to Cyan)
    final lineGradient = const LinearGradient(
      colors: [
        Color(0xFF6366F1), // Indigo
        Color(0xFF06B6D4), // Cyan
      ],
    );

    final strokePaint = Paint()
      ..shader = lineGradient.createShader(Rect.fromLTWH(leftMargin, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 7. Draw Glowing Node Points at Coordinates
    final nodeFillPaint = Paint()..color = Colors.white;
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < offsets.length; i++) {
      final pos = offsets[i];
      // Soft glow
      canvas.drawCircle(
        pos,
        7,
        Paint()..color = const Color(0xFF6366F1).withValues(alpha: 0.2),
      );
      canvas.drawCircle(pos, 5, nodeFillPaint);
      canvas.drawCircle(pos, 5, nodeBorderPaint);
    }

    // 8. Floating Tooltip over latest coordinate (Latest Semester)
    final lastOffset = offsets.last;
    final tooltipText = 'GPA ${points.last.gpa.toStringAsFixed(2)}';

    final tooltipTextPainter = TextPainter(
      text: TextSpan(
        text: tooltipText,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipWidth = tooltipTextPainter.width + 12;
    final tooltipHeight = tooltipTextPainter.height + 8;
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(lastOffset.dx, lastOffset.dy - 22),
        width: tooltipWidth,
        height: tooltipHeight,
      ),
      const Radius.circular(8),
    );

    final tooltipBgPaint = Paint()..color = const Color(0xFF4338CA);
    canvas.drawRRect(tooltipRect, tooltipBgPaint);

    tooltipTextPainter.paint(
      canvas,
      Offset(
        lastOffset.dx - (tooltipTextPainter.width / 2),
        lastOffset.dy - 22 - (tooltipTextPainter.height / 2),
      ),
    );
  }

  @override
  bool shouldRepaint(covariant GpaProgressionSplinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.targetGpa != targetGpa;
  }
}
