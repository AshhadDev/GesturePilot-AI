import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class SuccessCelebration extends StatefulWidget {
  final double size;
  final String totalSize;
  final int fileCount;
  final String duration;

  const SuccessCelebration({
    super.key,
    this.size = 200,
    this.totalSize = '',
    this.fileCount = 0,
    this.duration = '',
  });

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<_CelebrationParticle> _particles = [];
  final math.Random _random = math.Random();
  bool _hapticFired = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    for (int i = 0; i < 40; i++) {
      _particles.add(_CelebrationParticle(
        x: _random.nextDouble() * widget.size,
        y: _random.nextDouble() * widget.size,
        vx: (_random.nextDouble() - 0.5) * 2,
        vy: -_random.nextDouble() * 3 - 1,
        size: 2 + _random.nextDouble() * 4,
        color: _random.nextBool()
            ? AppColors.accent
            : _random.nextBool()
                ? AppColors.primary
                : AppColors.success,
        phase: _random.nextDouble(),
      ));
    }

    _fireHaptic();
  }

  void _fireHaptic() {
    if (_hapticFired) return;
    _hapticFired = true;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.05;
          p.alpha -= 0.003;
          if (p.alpha <= 0) {
            p.alpha = 0.8;
            p.x = _random.nextDouble() * widget.size;
            p.y = widget.size;
            p.vy = -_random.nextDouble() * 3 - 1;
          }
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CelebrationPainter(particles: _particles, time: t),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [AppColors.success, AppColors.primary],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withValues(alpha: 0.4),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Transfer Complete',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    if (widget.totalSize.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.totalSize}  ·  ${widget.fileCount} Files  ·  ${widget.duration}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 12, color: AppColors.success),
                          SizedBox(width: 4),
                          Text(
                            'Verified with SHA-256',
                            style: TextStyle(fontSize: 10, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CelebrationParticle {
  double x, y, vx, vy, size;
  double alpha = 0.8;
  final Color color;
  final double phase;

  _CelebrationParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.phase,
  });
}

class _CelebrationPainter extends CustomPainter {
  final List<_CelebrationParticle> particles;
  final double time;

  _CelebrationPainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.alpha <= 0) continue;
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size,
        Paint()..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) => true;
}

class ErrorAnimation extends StatefulWidget {
  final double size;
  final String title;
  final String description;
  final bool showRetry;

  const ErrorAnimation({
    super.key,
    this.size = 160,
    required this.title,
    this.description = '',
    this.showRetry = true,
  });

  @override
  State<ErrorAnimation> createState() => _ErrorAnimationState();
}

class _ErrorAnimationState extends State<ErrorAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _glowController]),
      builder: (context, _) {
        final shake = _shakeController.value;
        final glow = _glowController.value;
        final shakeOffset = math.sin(shake * math.pi * 8) * 4 * (1 - shake);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.15 + glow * 0.1),
                      blurRadius: 30 + glow * 20,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _ErrorRingPainter(glow: glow),
                  child: Center(
                    child: Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            if (widget.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ErrorRingPainter extends CustomPainter {
  final double glow;

  _ErrorRingPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppColors.error.withValues(alpha: 0.1 + glow * 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0,
      glow * math.pi * 2,
      false,
      Paint()
        ..color = AppColors.error.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ErrorRingPainter old) => glow != old.glow;
}
