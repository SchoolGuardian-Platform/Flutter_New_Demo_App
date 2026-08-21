import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter for rendering concentric triple-ring circular progress graph (Carbs, Protein, Fat)
class ConcentricMacroRingsPainter extends CustomPainter {
  ConcentricMacroRingsPainter({
    required this.carbsFraction,
    required this.proteinFraction,
    required this.fatFraction,
    required this.carbsColor,
    required this.proteinColor,
    required this.fatColor,
  });

  final double carbsFraction;
  final double proteinFraction;
  final double fatFraction;

  final Color carbsColor;
  final Color proteinColor;
  final Color fatColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2 - 8;

    const strokeWidth = 8.0;
    const gap = 12.0;

    // 1. Outer Ring: Carbs
    _drawRing(
      canvas,
      center,
      baseRadius,
      strokeWidth,
      carbsFraction,
      carbsColor,
    );

    // 2. Middle Ring: Protein
    _drawRing(
      canvas,
      center,
      baseRadius - gap,
      strokeWidth,
      proteinFraction,
      proteinColor,
    );

    // 3. Inner Ring: Fat
    _drawRing(
      canvas,
      center,
      baseRadius - (gap * 2),
      strokeWidth,
      fatFraction,
      fatColor,
    );
  }

  void _drawRing(
    Canvas canvas,
    Offset center,
    double radius,
    double strokeWidth,
    double fraction,
    Color color,
  ) {
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw full background ring track
    canvas.drawCircle(center, radius, trackPaint);

    // Draw active arc
    const startAngle = -math.pi / 2;
    final sweepAngle = (2 * math.pi) * fraction.clamp(0.0, 1.0);

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConcentricMacroRingsPainter oldDelegate) {
    return oldDelegate.carbsFraction != carbsFraction ||
        oldDelegate.proteinFraction != proteinFraction ||
        oldDelegate.fatFraction != fatFraction;
  }
}
