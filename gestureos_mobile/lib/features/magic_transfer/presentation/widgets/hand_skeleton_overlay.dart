import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/data/mediapipe_service.dart';
import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

class HandSkeletonOverlay extends StatelessWidget {
  final List<HandLandmark>? landmarks;
  final double intensity;

  const HandSkeletonOverlay({
    super.key,
    this.landmarks,
    this.intensity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (landmarks == null || landmarks!.length != 21) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _SkeletonPainter(landmarks!, intensity),
        );
      },
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  final List<HandLandmark> landmarks;
  final double intensity;

  _SkeletonPainter(this.landmarks, this.intensity);

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.length != 21) return;

    // Mirror x for front-facing camera and map normalized → pixel coords
    final pts = <Offset>[];
    for (final lm in landmarks) {
      pts.add(Offset(
        (1.0 - lm.x) * size.width,
        lm.y * size.height,
      ));
    }

    final alpha = (0.35 + intensity * 0.65).clamp(0.0, 1.0);

    // Glow pass — draw thick blurred lines behind main lines
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: alpha * 0.15)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final conn in MediapipeService.handConnections) {
      canvas.drawLine(pts[conn[0]], pts[conn[1]], glowPaint);
    }

    // Main neon skeleton lines
    final linePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: alpha * 0.55)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final conn in MediapipeService.handConnections) {
      canvas.drawLine(pts[conn[0]], pts[conn[1]], linePaint);
    }

    // Joint dots
    final dotPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: alpha * 0.8)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < pts.length; i++) {
      final isTip = MediapipeService.fingertips.contains(i);
      final radius = isTip ? 3.5 : 2.0;

      // Fingertip glow
      if (isTip) {
        final tipGlowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: alpha * 0.4),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: pts[i], radius: 10));
        canvas.drawCircle(pts[i], 10, tipGlowPaint);
      }

      canvas.drawCircle(pts[i], radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      landmarks != old.landmarks || intensity != old.intensity;
}
