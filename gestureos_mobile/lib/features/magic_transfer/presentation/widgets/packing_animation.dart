import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class PackingAnimation extends StatelessWidget {
  const PackingAnimation({
    super.key,
    required this.progress,
    this.size = 200,
  });

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filesPhase = (progress * 3).clamp(0.0, 1.0);
    const particlePhase = 0.33;
    const orbPhase = 0.66;
    final t = progress;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _PackingPainter(
          progress: t,
          filesPhase: filesPhase,
          particlePhase: particlePhase,
          orbPhase: orbPhase,
        ),
      ),
    );
  }
}

class _PackingPainter extends CustomPainter {
  _PackingPainter({
    required this.progress,
    required this.filesPhase,
    required this.particlePhase,
    required this.orbPhase,
  });

  final double progress;
  final double filesPhase;
  final double particlePhase;
  final double orbPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;

    if (progress < 0.45) {
      _drawFiles(canvas, center, size, filesPhase, paint);
    }

    if (progress >= 0.25 && progress < 0.65) {
      _drawParticles(canvas, center, size, (progress - 0.25) / 0.4, paint);
    }

    if (progress >= 0.5) {
      _drawOrb(canvas, center, (progress - 0.5) / 0.5);
    }
  }

  void _drawFiles(Canvas canvas, Offset center, Size size, double phase, Paint paint) {
    final fileCount = 4;
    for (int i = 0; i < fileCount; i++) {
      final angle = (i / fileCount) * 2 * math.pi;
      final dist = (size.width * 0.35) * (1 - phase);
      final shrink = 1.0 - phase * 0.5;
      final x = center.dx + math.cos(angle) * dist;
      final y = center.dy + math.sin(angle) * dist;
      final w = 16 * shrink;
      final h = 20 * shrink;
      paint.color = AppColors.accent.withValues(alpha: 1.0 - phase * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          const Radius.circular(3),
        ),
        paint,
      );
      if (shrink > 0.3) {
        paint.color = AppColors.textPrimary.withValues(alpha: 0.5 * (1 - phase));
        canvas.drawRect(
          Rect.fromCenter(center: Offset(x, y - 2), width: w * 0.6, height: 3 * shrink),
          paint,
        );
      }
    }
  }

  void _drawParticles(Canvas canvas, Offset center, Size size, double phase, Paint paint) {
    final count = 12;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + phase * math.pi;
      final spreadDist = size.width * (0.15 + phase * 0.2);
      final x = center.dx + math.cos(angle) * spreadDist;
      final y = center.dy + math.sin(angle) * spreadDist;
      final alpha = (1.0 - phase) * 0.8;
      paint.color = AppColors.accent.withValues(alpha: alpha);
      final r = 2.0 + (1.0 - phase) * 2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  void _drawOrb(Canvas canvas, Offset center, double phase) {
    final orbSize = 10 + phase * 30;
    final alpha = phase.clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..color = AppColors.primary.withValues(alpha: alpha * 0.5);
    canvas.drawCircle(center, orbSize + 15, glowPaint);

    final orbPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: alpha),
          AppColors.primary.withValues(alpha: alpha * 0.8),
          AppColors.primary.withValues(alpha: alpha * 0.3),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: orbSize));
    canvas.drawCircle(center, orbSize, orbPaint);
  }

  @override
  bool shouldRepaint(covariant _PackingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
