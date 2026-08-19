import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/antigravity_physics_models.dart';

/// CustomPainter for rendering Deep Void background gradient + multi-layer star particle dust
class StarParticleDustPainter extends CustomPainter {
  StarParticleDustPainter({
    required this.particles,
    required this.parallaxOffset,
    required this.time,
  });

  final List<StarParticle> particles;
  final Offset parallaxOffset;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Deep Void / Midnight Slate Background Gradient (#0B0F19 to #111827)
    final bgGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF070A12),
        Color(0xFF0B0F19),
        Color(0xFF111827),
      ],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Multi-Layer Star Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (final p in particles) {
      // Parallax calculation based on depth factor
      final offsetX = (p.position.dx + (parallaxOffset.dx * p.depth * 30.0)) % size.width;
      final offsetY = (p.position.dy + (parallaxOffset.dy * p.depth * 30.0) + (time * p.speed * 20.0)) % size.height;

      particlePaint.color = Colors.white.withValues(
        alpha: (p.alpha * (0.6 + 0.4 * math.sin(time * p.speed))).clamp(0.1, 0.9),
      );

      // Draw glowing particle
      canvas.drawCircle(Offset(offsetX, offsetY), p.radius, particlePaint);

      // Soft glow aura for larger particles
      if (p.radius > 2.0) {
        final auraPaint = Paint()
          ..color = const Color(0xFF06B6D4).withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(offsetX, offsetY), p.radius * 2.5, auraPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StarParticleDustPainter oldDelegate) {
    return true; // Continuously animate star particle dust
  }
}
