import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class ReceiverScanAnimation extends StatefulWidget {
  final double size;

  const ReceiverScanAnimation({super.key, this.size = 200});

  @override
  State<ReceiverScanAnimation> createState() => _ReceiverScanAnimationState();
}

class _ReceiverScanAnimationState extends State<ReceiverScanAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, _) {
        final t = _scanController.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ScanPainter(time: t * math.pi * 2),
        );
      },
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double time;

  _ScanPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Ambient glow
    final breath = (math.sin(time) + 1) / 2;
    canvas.drawCircle(
      center,
      r * 0.8,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.06 + breath * 0.04),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Scanning ring
    final scanAngle = time % (math.pi * 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r * 0.6),
      scanAngle - 0.3,
      0.6,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Scanner dot
    final dotX = center.dx + math.cos(scanAngle) * r * 0.6;
    final dotY = center.dy + math.sin(scanAngle) * r * 0.6;
    canvas.drawCircle(
      Offset(dotX, dotY),
      4,
      Paint()
        ..color = AppColors.accent
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      2,
      Paint()..color = Colors.white,
    );

    // Radar rings
    for (int i = 0; i < 3; i++) {
      final ringPhase = (time / (math.pi * 2) + i / 3) % 1.0;
      final ringRadius = r * 0.3 + ringPhase * r * 0.5;
      final ringAlpha = (1 - ringPhase) * 0.15;

      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = AppColors.primary.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) => time != old.time;
}

class IncomingOrbAnimation extends StatefulWidget {
  final double size;
  final double progress;

  const IncomingOrbAnimation({super.key, this.size = 200, this.progress = 0});

  @override
  State<IncomingOrbAnimation> createState() => _IncomingOrbAnimationState();
}

class _IncomingOrbAnimationState extends State<IncomingOrbAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glow = _glowController.value;
        final incoming = widget.progress;
        final scale = 0.3 + incoming * 0.7;
        final opacity = incoming.clamp(0.0, 1.0);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _IncomingOrbPainter(glow: glow, progress: incoming),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IncomingOrbPainter extends CustomPainter {
  final double glow;
  final double progress;

  _IncomingOrbPainter({required this.glow, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * 0.6;

    // Outer glow
    canvas.drawCircle(
      center,
      r * (2 + glow),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15 + glow * 0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 3)),
    );

    // Core
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Trailing particles
    final count = 6;
    for (int i = 0; i < count; i++) {
      final angle = math.pi + (i / count) * 0.5;
      final dist = r * 0.8 + r * (1 - progress) * 2 * (i / count);
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final alpha = (1 - i / count) * 0.5;
      canvas.drawCircle(
        Offset(px, py),
        2 * (1 - i / count) + 0.5,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_IncomingOrbPainter old) =>
      glow != old.glow || progress != old.progress;
}

class UnpackAnimation extends StatefulWidget {
  final double progress;
  final double size;
  final int fileCount;

  const UnpackAnimation({
    super.key,
    required this.progress,
    this.size = 200,
    this.fileCount = 1,
  });

  @override
  State<UnpackAnimation> createState() => _UnpackAnimationState();
}

class _UnpackAnimationState extends State<UnpackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final t = _particleController.value;
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _UnpackPainter(
            progress: widget.progress,
            fileCount: widget.fileCount,
            time: t * math.pi * 2,
          ),
        );
      },
    );
  }
}

class _UnpackPainter extends CustomPainter {
  final double progress;
  final int fileCount;
  final double time;

  _UnpackPainter({
    required this.progress,
    required this.fileCount,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    if (progress <= 0) return;

    // Phase 1 (0-0.3): Orb explodes into particles
    final explodePhase = (progress / 0.3).clamp(0.0, 1.0);
    if (explodePhase > 0) {
      final explodeCount = 30;
      for (int i = 0; i < explodeCount; i++) {
        final angle = (i / explodeCount) * math.pi * 2;
        final dist = r * 0.3 + explodePhase * r * 0.8;
        final px = center.dx + math.cos(angle + time) * dist;
        final py = center.dy + math.sin(angle + time) * dist;
        final alpha = (1 - explodePhase * 0.5);
        final size = 3 - explodePhase * 2;

        canvas.drawCircle(
          Offset(px, py),
          size,
          Paint()..color = AppColors.accent.withValues(alpha: alpha),
        );
      }
    }

    // Phase 2 (0.3-0.7): Particles reconstruct files
    final reconPhase = ((progress - 0.3) / 0.4).clamp(0.0, 1.0);
    if (reconPhase > 0) {
      final fileCountD = fileCount.toDouble();
      for (int i = 0; i < fileCount; i++) {
        final angle = (i / fileCountD) * math.pi * 2;
        final dist = r * 0.5 * reconPhase;
        final px = center.dx + math.cos(angle) * dist;
        final py = center.dy + math.sin(angle) * dist;
        final size = 8 + reconPhase * 12;
        final alpha = reconPhase;

        // File card outline
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(px, py), width: size, height: size * 1.2),
            const Radius.circular(3),
          ),
          Paint()
            ..color = AppColors.accent.withValues(alpha: alpha * 0.6)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Phase 3 (0.7-1.0): Glow pulse
    final glowPhase = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    if (glowPhase > 0) {
      canvas.drawCircle(
        center,
        r * 0.5 + glowPhase * r * 0.8,
        Paint()
          ..color = AppColors.success.withValues(alpha: (1 - glowPhase) * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - glowPhase),
      );
    }
  }

  @override
  bool shouldRepaint(_UnpackPainter old) =>
      progress != old.progress || fileCount != old.fileCount;
}
