import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/antigravity_physics_models.dart';
import '../../models/user.dart';
import '../../widgets/antigravity_floating_card.dart';
import '../../widgets/star_particle_dust_painter.dart';

class AntiGravityZeroGDashboardPage extends StatefulWidget {
  const AntiGravityZeroGDashboardPage({super.key, this.user});

  static const routeName = '/antigravity-zerog-dashboard';

  final User? user;

  @override
  State<AntiGravityZeroGDashboardPage> createState() => _AntiGravityZeroGDashboardPageState();
}

class _AntiGravityZeroGDashboardPageState extends State<AntiGravityZeroGDashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  bool _isZeroGActive = true;
  Offset _parallaxOffset = Offset.zero;

  // Star Particle Dust
  final List<StarParticle> _starParticles = [];

  // Floating Physics Nodes
  late List<AntiGravityPhysicsNode> _nodes;

  @override
  void initState() {
    super.initState();

    // Generate 60 Random Star Dust Particles for Deep Void Parallax
    final rand = math.Random();
    for (int i = 0; i < 60; i++) {
      _starParticles.add(
        StarParticle(
          position: Offset(rand.nextDouble() * 400, rand.nextDouble() * 800),
          radius: 1.0 + rand.nextDouble() * 2.5,
          alpha: 0.2 + rand.nextDouble() * 0.7,
          speed: 0.2 + rand.nextDouble() * 0.8,
          depth: 0.1 + rand.nextDouble() * 0.9,
        ),
      );
    }

    // Initialize 3 Core Physics Nodes with Anchor Slot Positions
    _nodes = [
      AntiGravityPhysicsNode(
        id: 'node_vitals',
        title: 'Orbital Vitals Capsule',
        subtitle: 'Telemetry Ring & Pulsing Heart',
        metricText: '98.4% Sync',
        accentColor: const Color(0xFF06B6D4), // Cyan
        glowColor: const Color(0xFF06B6D4),
        icon: Icons.shield_moon_rounded,
        anchorOffset: const Offset(40, 140),
        mass: 1.2,
        phaseOffset: 0.0,
        floatSpeed: 1.2,
        floatAmplitude: 14.0,
      ),
      AntiGravityPhysicsNode(
        id: 'node_energy',
        title: 'Focus & Energy Level',
        subtitle: 'Liquid Wave Physics Bubble',
        metricText: '3.84 / 4.0',
        accentColor: const Color(0xFF10B981), // Electric Mint
        glowColor: const Color(0xFF10B981),
        icon: Icons.bolt_rounded,
        anchorOffset: const Offset(40, 280),
        mass: 1.0,
        phaseOffset: 1.5,
        floatSpeed: 1.0,
        floatAmplitude: 16.0,
      ),
      AntiGravityPhysicsNode(
        id: 'node_stress',
        title: 'Stress & Velocity Vector',
        subtitle: 'Zero-G Inertia Trajectory',
        metricText: '46 Manageable',
        accentColor: const Color(0xFF8B5CF6), // Violet
        glowColor: const Color(0xFF8B5CF6),
        icon: Icons.graphic_eq_rounded,
        anchorOffset: const Offset(40, 420),
        mass: 1.5,
        phaseOffset: 3.0,
        floatSpeed: 0.8,
        floatAmplitude: 10.0,
      ),
    ];

    // High-performance 60 FPS Ticker loop for continuous floating physics
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onPanUpdateNode(AntiGravityPhysicsNode node, DragUpdateDetails details) {
    setState(() {
      node.currentPosition += details.delta;
      node.velocity = details.delta;
      _parallaxOffset = Offset(
        (_parallaxOffset.dx + details.delta.dx * 0.001).clamp(-1.0, 1.0),
        (_parallaxOffset.dy + details.delta.dy * 0.001).clamp(-1.0, 1.0),
      );
    });
  }

  void _onPanEndNode(AntiGravityPhysicsNode node, DragEndDetails details) {
    setState(() {
      node.isDragging = false;
      node.velocity = details.velocity.pixelsPerSecond / 100;
    });
  }

  void _toggleZeroG(bool active) {
    setState(() {
      _isZeroGActive = active;
      if (!active) {
        // Electromagnetic re-docking spring recoil to anchor slots
        for (final node in _nodes) {
          node.resetToAnchor();
        }
      } else {
        // Explosive dispersion offset
        final rand = math.Random();
        for (final node in _nodes) {
          node.velocity = Offset(
            (rand.nextDouble() - 0.5) * 40,
            (rand.nextDouble() - 0.5) * 40,
          );
        }
      }
    });
  }

  void _showDetailModal(AntiGravityPhysicsNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(node.icon, color: node.accentColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  node.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Zero-G Physics State: Mass = ${node.mass}kg • Velocity = (${node.velocity.dx.toStringAsFixed(1)}, ${node.velocity.dy.toStringAsFixed(1)})',
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: node.accentColor,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close Orbit View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _ticker,
        builder: (context, child) {
          final time = _ticker.value * 2 * math.pi * 5;

          // Update floating physics positions frame by frame
          for (final node in _nodes) {
            if (!node.isDragging && _isZeroGActive) {
              // Sine-wave idle bobbing + damp velocity decay
              final idleY = math.sin(time * node.floatSpeed + node.phaseOffset) * node.floatAmplitude * 0.08;
              node.currentPosition += Offset(node.velocity.dx * 0.05, node.velocity.dy * 0.05 + idleY);
              node.velocity *= 0.96; // Inertia damping

              // Screen Boundary Bounce Damping
              if (node.currentPosition.dx < 10 || node.currentPosition.dx > screenSize.width - 270) {
                node.velocity = Offset(-node.velocity.dx * 0.8, node.velocity.dy);
              }
              if (node.currentPosition.dy < 90 || node.currentPosition.dy > screenSize.height - 220) {
                node.velocity = Offset(node.velocity.dx, -node.velocity.dy * 0.8);
              }
            }
          }

          return Stack(
            children: [
              // 1. Deep Void Parallax Background Canvas with Star Dust
              RepaintBoundary(
                child: CustomPaint(
                  size: screenSize,
                  painter: StarParticleDustPainter(
                    particles: _starParticles,
                    parallaxOffset: _parallaxOffset,
                    time: _ticker.value * 10,
                  ),
                ),
              ),

              // Top Title & Zero-G Status Header
              Positioned(
                top: 50,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Anti-Gravity Hub',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isZeroGActive ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isZeroGActive ? 'ZERO-G UNCOUPLED (DRAG & FLICK)' : 'ELECTROMAGNETIC DOCKED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _isZeroGActive ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // 2. Interactive Anti-Gravity Floating Bento Cards
              for (final node in _nodes)
                Positioned(
                  left: node.currentPosition.dx.clamp(10.0, screenSize.width - 270.0),
                  top: node.currentPosition.dy.clamp(90.0, screenSize.height - 200.0),
                  child: RepaintBoundary(
                    child: AntiGravityFloatingCard(
                      node: node,
                      waveValue: _ticker.value,
                      onPanStart: (_) => setState(() => node.isDragging = true),
                      onPanUpdate: (details) => _onPanUpdateNode(node, details),
                      onPanEnd: (details) => _onPanEndNode(node, details),
                      onTap: () => _showDetailModal(node),
                    ),
                  ),
                ),

              // 3. Gravity Disruptor Switch / Control Deck
              Positioned(
                bottom: 30,
                left: 30,
                right: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF334155)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isZeroGActive ? Icons.blur_on_rounded : Icons.grid_view_rounded,
                            color: _isZeroGActive ? const Color(0xFF06B6D4) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isZeroGActive ? 'Zero-G Microgravity' : 'Standard Bento Grid',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _isZeroGActive ? 'Frictionless float active' : 'Electromagnetic snap locked',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isZeroGActive,
                        onChanged: _toggleZeroG,
                        activeColor: const Color(0xFF06B6D4),
                        activeTrackColor: const Color(0xFF083344),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
