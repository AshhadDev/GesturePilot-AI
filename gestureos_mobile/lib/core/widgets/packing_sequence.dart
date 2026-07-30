import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class PackingSequence extends StatefulWidget {
  final double progress;
  final double size;
  final int fileCount;
  final VoidCallback? onComplete;

  const PackingSequence({
    super.key,
    required this.progress,
    this.size = 200,
    this.fileCount = 1,
    this.onComplete,
  });

  @override
  State<PackingSequence> createState() => _PackingSequenceState();
}

class _PackingSequenceState extends State<PackingSequence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shockwaveController;
  bool _completeFired = false;

  @override
  void initState() {
    super.initState();
    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(PackingSequence old) {
    super.didUpdateWidget(old);
    if (widget.progress >= 0.85 && !_completeFired) {
      _completeFired = true;
      _shockwaveController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete?.call();
      });
    }
    if (widget.progress == 0) {
      _completeFired = false;
    }
  }

  @override
  void dispose() {
    _shockwaveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_shockwaveController]),
      builder: (context, _) {
        final t = widget.progress.clamp(0.0, 1.0);
        final shockwave = _shockwaveController.value;
        final time = DateTime.now().millisecondsSinceEpoch / 1000;

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PackingSequencePainter(
              progress: t,
              shockwave: shockwave,
              fileCount: widget.fileCount,
              time: time,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  double angle;
  double dist;
  final double phase;
  double zDepth;
  double initialDist;

  _Particle({
    required this.angle,
    required this.dist,
    this.phase = 0.0,
    this.zDepth = 0.0,
    this.initialDist = 0.0,
  });
}

class _PackingSequencePainter extends CustomPainter {
  final double progress;
  final double shockwave;
  final int fileCount;
  final double time;

  _PackingSequencePainter({
    required this.progress,
    required this.shockwave,
    required this.fileCount,
    required this.time,
  });

  // Particle pool (reused)
  static final List<_Particle> _particlePool = [];
  static bool _poolInitialized = false;

  static void _ensurePool(int count) {
    if (_poolInitialized) return;
    _poolInitialized = true;
    final rng = math.Random(42);
    for (int i = 0; i < count; i++) {
      _particlePool.add(_Particle(
        angle: rng.nextDouble() * math.pi * 2,
        dist: 0.2 + rng.nextDouble() * 0.8,
        phase: rng.nextDouble(),
        zDepth: rng.nextDouble(),
        initialDist: 0.2 + rng.nextDouble() * 0.8,
      ));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    _ensurePool(200);

    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    _drawBackgroundDim(canvas, size, r);
    _drawShockwave(canvas, center, r);

    if (progress < 0.15) {
      _drawFileCards(canvas, center, r);
    }

    if (progress >= 0.1 && progress < 0.4) {
      _drawExplosion(canvas, center, r);
    }

    if (progress >= 0.3 && progress < 0.6) {
      _drawSpiral(canvas, center, r);
    }

    if (progress >= 0.5 && progress < 0.7) {
      _drawCompression(canvas, center, r);
    }

    if (progress >= 0.65 && progress < 0.85) {
      _drawEnergyEnterFist(canvas, center, r);
    }

    if (progress >= 0.8 && progress < 0.9) {
      _drawFlash(canvas, size);
    }

    if (progress >= 0.85) {
      _drawSuccessPulse(canvas, center, r);
    }
  }

  void _drawBackgroundDim(Canvas canvas, Size size, double r) {
    final dim = (progress * 0.5).clamp(0.0, 0.5);
    if (dim > 0) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        r + 20,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.black.withValues(alpha: dim),
              Colors.transparent,
            ],
            stops: const [0.0, 1.0],
          ).createShader(
              Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: r + 20)),
      );
    }
  }

  void _drawShockwave(Canvas canvas, Offset center, double r) {
    if (shockwave <= 0) return;

    final waveRadius = r * 0.3 + shockwave * r * 1.8;
    final alpha = (1 - shockwave) * 0.5;

    for (int i = 0; i < 3; i++) {
      final offset = i * 8.0 * shockwave;
      final ringAlpha = alpha * (1 - i * 0.3);
      final ringWidth = (3 - i) * (1 - shockwave) + 0.5;

      canvas.drawCircle(
        center,
        waveRadius + offset,
        Paint()
          ..color = AppColors.accent.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth,
      );
    }
  }

  void _drawFileCards(Canvas canvas, Offset center, double r) {
    final phase = (progress / 0.15).clamp(0.0, 1.0);
    final easeIn = phase * phase;
    final count = fileCount.clamp(1, 8);

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + time * 0.2;
      final dist = r * 1.3 * easeIn + (1 - easeIn) * r * 0.2;
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final cardW = 14 + easeIn * 10;
      final cardH = cardW * 1.3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, py), width: cardW, height: cardH),
          const Radius.circular(2),
        ),
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.6 * easeIn)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // File type icon
      canvas.drawCircle(
        Offset(px, py - cardH * 0.15),
        2.5,
        Paint()..color = AppColors.primary.withValues(alpha: 0.5 * easeIn),
      );
    }

    // Center glow building up
    canvas.drawCircle(
      center,
      r * 0.2 * easeIn,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.1 * easeIn),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.2)),
    );
  }

  void _drawExplosion(Canvas canvas, Offset center, double r) {
    final phase = ((progress - 0.1) / 0.3).clamp(0.0, 1.0);
    final easeOut = 1 - (1 - phase) * (1 - phase);
    final count = _particlePool.length;
    final explosionRadius = r * 0.8 + easeOut * r * 0.5;

    for (int i = 0; i < count; i++) {
      final p = _particlePool[i];
      final angle = p.angle + time * 0.3;
      final spread = p.initialDist * explosionRadius;
      final dist = spread * (0.3 + easeOut * 0.7);
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;

      // Z-depth effect: closer = brighter
      final zScale = 0.6 + p.zDepth * 0.4;
      final particleAlpha = (1 - easeOut * 0.5) * zScale;
      final particleSize = 1.5 + (1 - easeOut) * 2.0 + p.zDepth * 1.5;

      canvas.drawCircle(
        Offset(px, py),
        particleSize,
        Paint()..color = AppColors.accent.withValues(alpha: particleAlpha * 0.5),
      );

      // Glow on larger particles
      if (p.zDepth > 0.6) {
        canvas.drawCircle(
          Offset(px, py),
          particleSize * 3,
          Paint()
            ..color = AppColors.primary.withValues(alpha: particleAlpha * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }
  }

  void _drawSpiral(Canvas canvas, Offset center, double r) {
    final phase = ((progress - 0.3) / 0.3).clamp(0.0, 1.0);
    final easeIn = phase * phase;
    final count = _particlePool.length;

    for (int i = 0; i < count; i++) {
      final p = _particlePool[i];
      final t = (i / count) * easeIn;
      if (t <= 0) continue;

      final spiralAngle = t * math.pi * 6 + time + p.phase * 0.5;
      final spiralDist = r * 0.9 * (1 - t * 0.92);
      final px = center.dx + math.cos(spiralAngle) * spiralDist;
      final py = center.dy + math.sin(spiralAngle) * spiralDist;
      final alpha = (1 - t) * 0.6 * easeIn;
      final size = (2.5 * (1 - t) + 0.5) * (0.8 + p.zDepth * 0.4);

      canvas.drawCircle(
        Offset(px, py),
        size,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );

      // Particle glow trail
      if (p.zDepth > 0.5 && alpha > 0.1) {
        canvas.drawCircle(
          Offset(px, py),
          size * 3,
          Paint()
            ..color = AppColors.primary.withValues(alpha: alpha * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }

    // Center glow growing
    final centerGlow = (easeIn * 0.4).clamp(0.0, 0.4);
    canvas.drawCircle(
      center,
      r * 0.3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: centerGlow),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.3)),
    );
  }

  void _drawCompression(Canvas canvas, Offset center, double r) {
    final phase = ((progress - 0.5) / 0.2).clamp(0.0, 1.0);
    final easeIn = phase * phase;

    // Compressing energy ring
    final ringRadius = r * 0.8 * (1 - easeIn * 0.6);
    final ringAlpha = (0.3 + easeIn * 0.3) * (1 - easeIn * 0.3);

    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: ringAlpha),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius)),
    );

    // Bright core growing
    final coreRadius = r * 0.08 + easeIn * r * 0.15;
    final coreAlpha = 0.3 + easeIn * 0.6;

    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: coreAlpha),
            AppColors.accent.withValues(alpha: coreAlpha * 0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius * 2)),
    );

    // Light rays during compression
    final rayCount = 6;
    for (int i = 0; i < rayCount; i++) {
      final rayAngle = (i / rayCount) * math.pi * 2 + time * 0.5;
      final rayLength = ringRadius * 0.3 * (1 + math.sin(time + i) * 0.3);

      canvas.drawLine(
        Offset(
          center.dx + math.cos(rayAngle) * coreRadius,
          center.dy + math.sin(rayAngle) * coreRadius,
        ),
        Offset(
          center.dx + math.cos(rayAngle) * (coreRadius + rayLength),
          center.dy + math.sin(rayAngle) * (coreRadius + rayLength),
        ),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.3 * easeIn)
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  void _drawEnergyEnterFist(Canvas canvas, Offset center, double r) {
    final phase = ((progress - 0.65) / 0.2).clamp(0.0, 1.0);
    final easeIn = phase;

    // Orb rises upward and shrinks
    final orbRadius = r * 0.22 * (1 - easeIn * 0.7);
    final riseOffset = -r * 0.8 * easeIn;
    final orbCenter = Offset(center.dx, center.dy + riseOffset);

    // Energy trail behind orb
    for (int i = 0; i < 10; i++) {
      final t = i / 10.0;
      final trailOffset = riseOffset + t * r * 0.3 * (1 - easeIn);
      final trailAlpha = (1 - t) * 0.2 * (1 - easeIn);
      canvas.drawCircle(
        Offset(center.dx, center.dy + trailOffset),
        orbRadius * (1 - t * 0.5),
        Paint()
          ..color = AppColors.accent.withValues(alpha: trailAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Orb glow
    canvas.drawCircle(
      orbCenter,
      orbRadius * 3,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.3 * (1 - easeIn)),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: orbRadius * 3)),
    );

    // Orb core
    canvas.drawCircle(
      orbCenter,
      orbRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9 * (1 - easeIn * 0.5)),
            AppColors.accent.withValues(alpha: 0.8 * (1 - easeIn * 0.5)),
            AppColors.primary.withValues(alpha: 0.6 * (1 - easeIn * 0.5)),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: orbCenter, radius: orbRadius)),
    );
  }

  void _drawFlash(Canvas canvas, Size size) {
    final phase = ((progress - 0.80) / 0.1).clamp(0.0, 1.0);
    // Flash rises and fades
    final flashAlpha = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    final flashAlphaClamped = flashAlpha.clamp(0.0, 0.6);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: flashAlphaClamped),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Bright center flash
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4 * flashAlpha,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: flashAlphaClamped * 0.8),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: size.width * 0.4,
        )),
    );
  }

  void _drawSuccessPulse(Canvas canvas, Offset center, double r) {
    final phase = ((progress - 0.85) / 0.15).clamp(0.0, 1.0);
    final easeOut = 1 - (1 - phase) * (1 - phase);

    // Gentle expanding ring
    final pulseRadius = r * 0.3 + easeOut * r * 0.6;
    final pulseAlpha = (1 - easeOut) * 0.2;

    canvas.drawCircle(
      center,
      pulseRadius,
      Paint()
        ..color = AppColors.success.withValues(alpha: pulseAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * (1 - easeOut),
    );

    // Residual glow
    canvas.drawCircle(
      center,
      r * 0.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.1 * easeOut),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.25)),
    );
  }

  @override
  bool shouldRepaint(_PackingSequencePainter old) =>
      progress != old.progress || shockwave != old.shockwave;
}
