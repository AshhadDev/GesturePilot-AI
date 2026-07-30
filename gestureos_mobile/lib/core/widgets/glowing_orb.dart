import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Animated glowing orb used throughout the Magic Transfer flow.
/// Pulses, rotates rings, and emits a soft purple glow.
class GlowingOrb extends StatefulWidget {
  const GlowingOrb({
    super.key,
    this.size = 200,
    this.intensity = 1.0,
    this.showRings = true,
    this.showParticles = true,
  });

  final double size;
  final double intensity;
  final bool showRings;
  final bool showParticles;

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Listenable _mergedListenable;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _mergedListenable = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.6,
      height: widget.size * 1.6,
      child: AnimatedBuilder(
        animation: _mergedListenable,
        builder: (context, _) {
          final t = _controller.value;
          final pulse = 0.85 + (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.15;
          final particleAlpha = 0.3 + (math.sin(t * math.pi * 2) * 0.5 + 0.5) * 0.4;

          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size * 1.4,
                height: widget.size * 1.4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: 0.2 * widget.intensity,
                      ),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              if (widget.showRings) ...[
                Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: Container(
                    width: widget.size * 1.2,
                    height: widget.size * 1.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -t * 2 * math.pi * 0.7,
                  child: Container(
                    width: widget.size * 1.35,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ],
              Transform.scale(
                scale: pulse,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.6),
                        AppColors.primary.withValues(alpha: 0.8),
                        AppColors.primary.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.4 * widget.intensity),
                        blurRadius: 40,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.showParticles)
                ...List.generate(8, (i) {
                  final angle = (i / 8) * 2 * math.pi + t * 2 * math.pi;
                  final dist = widget.size * 0.6 +
                      (math.sin(t * math.pi * 2 + i) * 15);
                  final x = math.cos(angle) * dist;
                  final y = math.sin(angle) * dist;
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withValues(alpha: particleAlpha),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
