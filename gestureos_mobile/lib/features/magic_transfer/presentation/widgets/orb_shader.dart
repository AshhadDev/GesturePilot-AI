import 'dart:math' as math;

import 'package:flutter/material.dart';

class OrbShader extends StatelessWidget {
  final double time;
  final double intensity;
  final double size;
  final Color primaryColor;
  final Color accentColor;

  const OrbShader({
    super.key,
    required this.time,
    required this.intensity,
    required this.size,
    this.primaryColor = const Color(0xFF7C3AED),
    this.accentColor = const Color(0xFFA855F7),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OrbShaderPainter(time, intensity, primaryColor, accentColor),
    );
  }
}

class _OrbShaderPainter extends CustomPainter {
  final double time;
  final double intensity;
  final Color primary;
  final Color accent;

  _OrbShaderPainter(this.time, this.intensity, this.primary, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final pulse = 0.92 + math.sin(time * math.pi * 2) * 0.08 * intensity;
    final scaledRadius = radius * pulse;

    // Outer aura
    final auraRect = Rect.fromCircle(center: center, radius: radius * 2);
    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withValues(alpha: 0.12 * intensity),
          accent.withValues(alpha: 0.06 * intensity),
          Colors.transparent,
        ],
      ).createShader(auraRect);
    canvas.drawCircle(center, radius * 2, auraPaint);

    // Mid glow ring
    final glowPaint = Paint()
      ..color = primary.withValues(alpha: 0.08 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 1.35, glowPaint);

    // Inner core — radial gradient from white center → accent → primary → transparent
    final coreRect = Rect.fromCircle(center: center, radius: scaledRadius);
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7 * intensity),
          accent.withValues(alpha: 0.5 * intensity),
          primary.withValues(alpha: 0.7 * intensity),
          primary.withValues(alpha: 0.15 * intensity),
        ],
        stops: [0.0, 0.15, 0.45, 1.0],
      ).createShader(coreRect);
    canvas.drawCircle(center, scaledRadius, corePaint);

    // Inner hotspot
    final hotspotPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.3 * intensity),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: scaledRadius * 0.4),
      );
    canvas.drawCircle(center, scaledRadius * 0.4, hotspotPaint);

    // Outer rotating ring
    final ring1Angle = time * math.pi * 2;
    final ringPaint = Paint()
      ..color = accent.withValues(alpha: 0.18 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius * 1.3, ringPaint);

    // Inner rotating ring (counter-rotating)
    ringPaint.color = primary.withValues(alpha: 0.12 * intensity);
    ringPaint.strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.8, ringPaint);

    // Highlight arc on outer ring
    final brightPaint = Paint()
      ..color = accent.withValues(alpha: 0.45 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 1.3),
      ring1Angle,
      math.pi * 0.3,
      false,
      brightPaint,
    );

    // Highlight arc on inner ring
    brightPaint.color = primary.withValues(alpha: 0.35 * intensity);
    brightPaint.strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -ring1Angle * 0.7,
      math.pi * 0.25,
      false,
      brightPaint,
    );
  }

  @override
  bool shouldRepaint(_OrbShaderPainter old) =>
      time != old.time || intensity != old.intensity;
}
