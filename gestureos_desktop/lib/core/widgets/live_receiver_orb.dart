import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';

class LiveReceiverOrb extends StatefulWidget {
  const LiveReceiverOrb({
    super.key,
    this.size = 220,
    this.phase = ConnectionPhase.searching,
    this.progress = 0.0,
  });

  final double size;
  final ConnectionPhase phase;
  final double progress;

  @override
  State<LiveReceiverOrb> createState() => _LiveReceiverOrbState();
}

class _LiveReceiverOrbState extends State<LiveReceiverOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breath;
  late final AnimationController _spin;
  late final AnimationController _particles;
  late final AnimationController _pulse;
  Timer? _pulseTimer;
  double _spinSpeed = 1.0;
  bool _particlesInward = false;

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    )..repeat();
    _particles = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..repeat();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && !_pulse.isAnimating) {
        _pulse.forward(from: 0);
      }
    });
    _applyPhase();
  }

  @override
  void didUpdateWidget(covariant LiveReceiverOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _applyPhase();
  }

  void _applyPhase() {
    switch (widget.phase) {
      case ConnectionPhase.receiving:
        _spinSpeed = 3.2;
        _particlesInward = true;
        _spin.duration = const Duration(milliseconds: 3500);
        break;
      case ConnectionPhase.completed:
        _spinSpeed = 1.4;
        _particlesInward = false;
        _spin.duration = const Duration(milliseconds: 8000);
        _pulse.forward(from: 0);
        break;
      case ConnectionPhase.connecting:
        _spinSpeed = 1.6;
        _particlesInward = false;
        _spin.duration = const Duration(milliseconds: 7000);
        break;
      case ConnectionPhase.connected:
        _spinSpeed = 1.0;
        _particlesInward = false;
        _spin.duration = const Duration(milliseconds: 12000);
        break;
      case ConnectionPhase.searching:
      case ConnectionPhase.offline:
        _spinSpeed = 0.7;
        _particlesInward = false;
        _spin.duration = const Duration(milliseconds: 16000);
        break;
    }
    if (_spin.isAnimating) {
      _spin.stop();
      _spin.forward();
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    _breath.dispose();
    _spin.dispose();
    _particles.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final glowBoost = switch (phase) {
      ConnectionPhase.receiving => 0.35,
      ConnectionPhase.completed => 0.25,
      ConnectionPhase.connected => 0.22,
      ConnectionPhase.connecting => 0.15,
      ConnectionPhase.searching => 0.10,
      ConnectionPhase.offline => 0.0,
    };
    final coreColor = switch (phase) {
      ConnectionPhase.completed => AppColors.success,
      _ => AppColors.accent,
    };

    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _spin, _particles, _pulse]),
      builder: (context, _) {
        final t = _breath.value;
        final spinAngle = _spin.value * 2 * math.pi * _spinSpeed;
        final pulse = _pulse.value;
        final baseOpacity = 0.12 + glowBoost + t * 0.18;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient glow
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      coreColor.withValues(alpha: baseOpacity.clamp(0.0, 0.85)),
                      coreColor.withValues(alpha: baseOpacity * 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Pulse ring (expands outward then fades)
              if (pulse > 0)
                Transform.scale(
                  scale: 1 + pulse * 1.6,
                  child: Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: coreColor
                            .withValues(alpha: (1 - pulse) * 0.8),
                        width: 3 * (1 - pulse) + 1,
                      ),
                    ),
                  ),
                ),
              // Rotating outer ring
              Transform.rotate(
                angle: spinAngle,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RingPainter(progress: widget.progress),
                ),
              ),
              // Floating particles
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ParticlePainter(
                  _particles.value,
                  inward: _particlesInward,
                  intensity: baseOpacity,
                ),
              ),
              // Core orb
              Transform.scale(
                scale: 0.86 + t * 0.08,
                child: Container(
                  width: widget.size * 0.56,
                  height: widget.size * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.28 + t * 0.18),
                        coreColor.withValues(alpha: 0.75),
                        AppColors.primary.withValues(alpha: 0.9),
                        AppColors.primary.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.22, 0.5, 0.8, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: coreColor.withValues(
                          alpha: (0.35 + glowBoost + t * 0.2).clamp(0.0, 0.9),
                        ),
                        blurRadius: 60 + t * 30,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),
              // Inner highlight
              Transform.scale(
                scale: 0.55 + t * 0.05,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.55 + t * 0.25),
                        coreColor.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Receiving overlay
              if (phase == ConnectionPhase.receiving)
                Container(
                  width: widget.size * 0.56,
                  height: widget.size * 0.56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background.withValues(alpha: 0.55),
                  ),
                ),
              if (phase == ConnectionPhase.receiving)
                Center(
                  child: Text(
                    '${(widget.progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.46;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const segments = 40;
    for (int i = 0; i < segments; i++) {
      final startAngle = (i / segments) * 2 * math.pi;
      final sweep = (0.5 / segments) * 2 * math.pi;
      final active = (i / segments) < progress.clamp(0.0, 1.0);
      paint.color = AppColors.accentLight.withValues(
        alpha: active ? 0.7 : 0.15,
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t, {required this.inward, required this.intensity});

  final double t;
  final bool inward;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 14; i++) {
      final angle = (i / 14) * 2 * math.pi + t * math.pi * 2;
      final baseDist = size.width * (0.34 + (i % 3) * 0.06);
      final dist = inward ? baseDist * (1 - 0.55 * t) : baseDist;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      final twinkle = 0.5 + math.sin(t * math.pi * 6 + i * 1.7) * 0.3;
      paint.color = AppColors.accentLight.withValues(
        alpha: (twinkle * (0.35 + intensity)).clamp(0.05, 0.95),
      );
      canvas.drawCircle(Offset(x, y), inward ? 3.2 : 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.inward != inward ||
      oldDelegate.intensity != intensity;
}
