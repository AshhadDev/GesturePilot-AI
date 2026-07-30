import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';

class GlowingOrb extends StatefulWidget {
  const GlowingOrb({super.key, this.size = 200});

  final double size;

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final t = _pulseController.value;
        final scale = 0.85 + t * 0.15;
        final glowOpacity = 0.15 + t * 0.2;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withValues(alpha: glowOpacity + 0.1),
                      blurRadius: 60 + t * 20,
                      spreadRadius: 10 + t * 5,
                    ),
                    BoxShadow(
                      color: AppColors.accent
                          .withValues(alpha: glowOpacity),
                      blurRadius: 80 + t * 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size * 0.55,
                  height: widget.size * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3 + t * 0.2),
                        AppColors.accent.withValues(alpha: 0.6),
                        AppColors.primary.withValues(alpha: 0.8),
                        AppColors.primary.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.45, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: scale * 0.6,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.6 + t * 0.3),
                        AppColors.accentLight.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
