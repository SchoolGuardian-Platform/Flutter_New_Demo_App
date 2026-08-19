import 'package:flutter/material.dart';

/// Physics Model for an Anti-Gravity Floating Node
class AntiGravityPhysicsNode {
  AntiGravityPhysicsNode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.metricText,
    required this.accentColor,
    required this.glowColor,
    required this.icon,
    required this.anchorOffset,
    this.mass = 1.0,
    this.phaseOffset = 0.0,
    this.floatSpeed = 1.0,
    this.floatAmplitude = 12.0,
  })  : currentPosition = anchorOffset,
        velocity = Offset.zero;

  final String id;
  final String title;
  final String subtitle;
  final String metricText;
  final Color accentColor;
  final Color glowColor;
  final IconData icon;

  final Offset anchorOffset;
  Offset currentPosition;
  Offset velocity;

  final double mass;
  final double phaseOffset;
  final double floatSpeed;
  final double floatAmplitude;

  bool isDragging = false;

  void resetToAnchor() {
    currentPosition = anchorOffset;
    velocity = Offset.zero;
  }
}

/// Particle Dust Model for Background Parallax
class StarParticle {
  StarParticle({
    required this.position,
    required this.radius,
    required this.alpha,
    required this.speed,
    required this.depth,
  });

  Offset position;
  double radius;
  double alpha;
  double speed;
  double depth; // 0.1 (far) to 1.0 (near) for parallax calculation
}
