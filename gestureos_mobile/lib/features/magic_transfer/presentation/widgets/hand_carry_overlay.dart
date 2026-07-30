import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

/// Visual overlay for carry mode – renders a pulsing orb "inside" the fist
/// with glow, breathing pulse, and tiny particles leaking through fingers.
class HandCarryOverlay extends StatelessWidget {
  final List<HandLandmark>? landmarks;
  final double intensity;

  const HandCarryOverlay({
    super.key,
    this.landmarks,
    this.intensity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (landmarks == null || landmarks!.length < 21) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CarryPainter(landmarks!, intensity),
        );
      },
    );
  }
}

class _CarryPainter extends CustomPainter {
  final List<HandLandmark> landmarks;
  final double intensity;

  _CarryPainter(this.landmarks, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    // Mirror x for front-facing camera, map normalized → pixels
    final pts = <Offset>[];
    for (final lm in landmarks) {
      pts.add(Offset(
        (1.0 - lm.x) * size.width,
        lm.y * size.height,
      ));
    }

    final wrist = pts[0];
    final palmCenter = _centroid(pts, 5, 17); // MCP joints form palm
    final orbPos = Offset(
      (wrist.dx + palmCenter.dx) / 2,
      (wrist.dy + palmCenter.dy) / 2,
    );

    final t = DateTime.now().millisecondsSinceEpoch / 1000;
    final pulse = 0.85 + (math.sin(t * 3.0) * 0.5 + 0.5) * 0.15;
    final alpha = (0.3 + intensity * 0.7).clamp(0.0, 1.0);
    final orbRadius = 6.0 + intensity * 4.0;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: alpha * 0.25),
          AppColors.primary.withValues(alpha: alpha * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orbPos, radius: 30 * pulse));

    canvas.drawCircle(orbPos, 30 * pulse, glowPaint);

    // Orb core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: alpha * 0.9),
          AppColors.accent.withValues(alpha: alpha * 0.8),
          AppColors.primary.withValues(alpha: alpha * 0.6),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: orbPos, radius: orbRadius * pulse));

    canvas.drawCircle(orbPos, orbRadius * pulse, corePaint);

    // Leaking particles
    final particleCount = (8 + (intensity * 12).round()).clamp(4, 20);
    for (int i = 0; i < particleCount; i++) {
      final angle = (i / particleCount) * math.pi * 2 + t * 1.5;
      final dist = orbRadius * pulse +
          4.0 +
          (math.sin(t * 2.0 + i * 1.7) * 0.5 + 0.5) * 12;
      final px = orbPos.dx + math.cos(angle) * dist;
      final py = orbPos.dy + math.sin(angle) * dist;
      final pAlpha = (0.3 + (math.sin(t * 4.0 + i) * 0.5 + 0.5) * 0.5) * alpha;

      canvas.drawCircle(
        Offset(px, py),
        1.5 + (math.sin(t * 3.0 + i) * 0.5 + 0.5) * 1.5,
        Paint()..color = AppColors.accent.withValues(alpha: pAlpha),
      );
    }

    // Subtle hand illumination (radial wash over palm points)
    final washPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: alpha * 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: orbPos, radius: 50));

    canvas.drawCircle(orbPos, 50, washPaint);
  }

  Offset _centroid(List<Offset> pts, int start, int end) {
    double sx = 0, sy = 0;
    int n = 0;
    for (int i = start; i <= end && i < pts.length; i++) {
      sx += pts[i].dx;
      sy += pts[i].dy;
      n++;
    }
    return n > 0 ? Offset(sx / n, sy / n) : Offset.zero;
  }

  @override
  bool shouldRepaint(_CarryPainter old) =>
      landmarks != old.landmarks || intensity != old.intensity;
}
