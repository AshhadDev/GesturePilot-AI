import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class HandEnergyEffect extends StatelessWidget {
  final Offset? handPosition;
  final Offset orbCenter;
  final double time;
  final double intensity;

  const HandEnergyEffect({
    super.key,
    this.handPosition,
    required this.orbCenter,
    required this.time,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HandEnergyPainter(
        handPosition,
        orbCenter,
        time,
        intensity,
      ),
    );
  }
}

class _HandEnergyPainter extends CustomPainter {
  final Offset? handPosition;
  final Offset orbCenter;
  final double time;
  final double intensity;

  _HandEnergyPainter(
    this.handPosition,
    this.orbCenter,
    this.time,
    this.intensity,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (handPosition == null || intensity < 0.01) return;

    final pos = handPosition!;
    final dx = pos.dx - orbCenter.dx;
    final dy = pos.dy - orbCenter.dy;
    final dist = math.sqrt(dx * dx + dy * dy);

    // Connection beam between hand and orb
    if (dist < 400) {
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.25 * intensity),
            AppColors.primary.withValues(alpha: 0.08 * intensity),
          ],
        ).createShader(Rect.fromPoints(orbCenter, pos));
      canvas.drawLine(orbCenter, pos, beamPaint);
    }

    // Hand glow aura
    final glowRect = Rect.fromCircle(center: pos, radius: 40);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.accent.withValues(alpha: 0.35 * intensity),
          AppColors.accent.withValues(alpha: 0.08 * intensity),
          Colors.transparent,
        ],
      ).createShader(glowRect);
    canvas.drawCircle(pos, 40, glowPaint);

    // Pulse ring at hand
    final pulseRadius = 18 + math.sin(time * math.pi * 4) * 8;
    final pulsePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(pos, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(_HandEnergyPainter old) =>
      handPosition != old.handPosition ||
      time != old.time ||
      intensity != old.intensity;
}
