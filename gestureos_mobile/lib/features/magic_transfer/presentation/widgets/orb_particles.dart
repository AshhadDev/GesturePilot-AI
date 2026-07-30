import 'dart:math' as math;

import 'package:flutter/material.dart';

class OrbParticles extends StatelessWidget {
  final double time;
  final double intensity;
  final Color color;
  final double size;

  const OrbParticles({
    super.key,
    required this.time,
    required this.intensity,
    required this.size,
    this.color = const Color(0xFFA855F7),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ParticlePainter(time, intensity, color, size),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double time;
  final double intensity;
  final Color color;
  final double size;

  _ParticlePainter(this.time, this.intensity, this.color, this.size);

  static const int particleCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final seed = i * 137.508;
      final orbitalDist = radius * (0.35 + (seed % 47) / 47.0 * 0.85);
      final speed = 0.4 + (seed % 31) / 31.0 * 1.6;
      final phase = (seed % 97) / 97.0 * math.pi * 2;
      final pSize = 1.2 + (seed % 13) / 13.0 * 3.0;

      final angle = time * speed * math.pi * 2 + phase;
      final radialOsc = math.sin(time * 2.0 + phase) * radius * 0.05;
      final dist = orbitalDist + radialOsc;

      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final alpha = (0.25 + (seed % 23) / 23.0 * 0.75) * intensity;

      // Trail dots behind the particle
      for (int t = 1; t <= 3; t++) {
        final ta = angle - t * 0.04 * speed;
        final tx = center.dx + math.cos(ta) * dist;
        final ty = center.dy + math.sin(ta) * dist;
        final ts = pSize * (1.0 - t * 0.25);
        final talpha = alpha * (1.0 - t * 0.3);

        final trailPaint = Paint()
          ..color = color.withValues(alpha: talpha * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(Offset(tx, ty), ts, trailPaint);
      }

      // Main particle body
      final mainPaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(Offset(px, py), pSize, mainPaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      time != old.time || intensity != old.intensity;
}
