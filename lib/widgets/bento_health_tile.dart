import 'package:flutter/material.dart';

/// Bento Grid Tile widget for Health & Wellness Features with interactive tactile spring & RepaintBoundary
class BentoHealthTile extends StatefulWidget {
  const BentoHealthTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.liveMetricBadge,
    required this.accentColor,
    required this.bgColor,
    required this.icon,
    required this.onTap,
    this.isFullWidth = false,
  });

  final String title;
  final String subtitle;
  final String liveMetricBadge;
  final Color accentColor;
  final Color bgColor;
  final IconData icon;
  final VoidCallback onTap;
  final bool isFullWidth;

  @override
  State<BentoHealthTile> createState() => _BentoHealthTileState();
}

class _BentoHealthTileState extends State<BentoHealthTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: widget.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, color: widget.accentColor, size: 20),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 13, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.liveMetricBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
