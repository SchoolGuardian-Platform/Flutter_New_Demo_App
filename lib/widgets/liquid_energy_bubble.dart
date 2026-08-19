import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Fluid Liquid Physics Level widget inside a floating bubble container
class LiquidEnergyBubble extends StatelessWidget {
  const LiquidEnergyBubble({
    super.key,
    required this.fillPercentage, // 0.0 to 1.0
    required this.waveAnimationValue, // 0.0 to 1.0
    required this.color,
  });

  final double fillPercentage;
  final double waveAnimationValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: const Size(70, 70),
          painter: _LiquidWavePainter(
            fillPercentage: fillPercentage,
            waveValue: waveAnimationValue,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _LiquidWavePainter extends CustomPainter {
  _LiquidWavePainter({
    required this.fillPercentage,
    required this.waveValue,
    required this.color,
  });

  final double fillPercentage;
  final double waveValue;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseHeight = size.height * (1.0 - fillPercentage.clamp(0.0, 1.0));
    final path = Path();

    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x += 1) {
      final y = baseHeight + 4.0 * math.sin((x / size.width * 2 * math.pi) + (waveValue * 2 * math.pi));
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final liquidGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color,
        color.withValues(alpha: 0.6),
      ],
    );

    final paint = Paint()
      ..shader = liquidGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Glowing highlight crest line
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final crestPath = Path();
    crestPath.moveTo(0, baseHeight);
    for (double x = 0; x <= size.width; x += 1) {
      final y = baseHeight + 4.0 * math.sin((x / size.width * 2 * math.pi) + (waveValue * 2 * math.pi));
      crestPath.lineTo(x, y);
    }
    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.waveValue != waveValue ||
        oldDelegate.color != color;
  }
}
