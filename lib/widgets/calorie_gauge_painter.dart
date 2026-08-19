import 'dart:math' as math;
import 'package:flutter/material.dart';

/// CustomPainter for rendering the semi-circular segmented radial calorie gauge
class CalorieGaugePainter extends CustomPainter {
  CalorieGaugePainter({
    required this.progress, // Value from 0.0 to 1.0
    required this.primaryColor,
    required this.trackColor,
  });

  final double progress;
  final Color primaryColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.72);
    final radius = math.min(size.width / 2, size.height) - 16;

    const startAngle = math.pi * 0.82;
    const sweepAngle = math.pi * 1.36;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor,
          const Color(0xFF0D9488),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw track arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Draw active progress arc
    final activeSweep = sweepAngle * progress.clamp(0.0, 1.0);
    if (activeSweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        progressPaint,
      );
    }

    // Draw segmented tick marks along the arc
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5;

    const totalTicks = 24;
    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (sweepAngle * (i / totalTicks));
      final innerOffset = Offset(
        center.dx + (radius - 7) * math.cos(angle),
        center.dy + (radius - 7) * math.sin(angle),
      );
      final outerOffset = Offset(
        center.dx + (radius + 7) * math.cos(angle),
        center.dy + (radius + 7) * math.sin(angle),
      );
      canvas.drawLine(innerOffset, outerOffset, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CalorieGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
