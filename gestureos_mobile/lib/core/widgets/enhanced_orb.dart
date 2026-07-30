import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

enum OrbState {
  idle,
  awakening,
  active,
  carrying,
  packing,
  launching,
  transferring,
  completed,
  error,
}

class EnhancedOrb extends StatefulWidget {
  final double size;
  final OrbState state;
  final double progress;
  final double intensity;
  final Offset targetPosition;
  final String? currentFile;
  final String? transferSpeed;
  final String? eta;
  final String? transferredSize;

  const EnhancedOrb({
    super.key,
    this.size = 140,
    this.state = OrbState.idle,
    this.progress = 0.0,
    this.intensity = 0.0,
    this.targetPosition = Offset.zero,
    this.currentFile,
    this.transferSpeed,
    this.eta,
    this.transferredSize,
  });

  @override
  State<EnhancedOrb> createState() => _EnhancedOrbState();
}

class _EnhancedOrbState extends State<EnhancedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _heartbeatController;
  late final AnimationController _particleController;
  late final AnimationController _sparkController;
  final math.Random _random = math.Random();

  // Spring physics state
  double _currentX = 0;
  double _currentY = 0;
  double _velocityX = 0;
  double _velocityY = 0;
  double _prevTargetX = 0;
  double _prevTargetY = 0;

  // Previous positions for motion trail
  final _trailHistory = <Offset>[];
  static const int _trailLength = 6;

  // Spark timers
  double _nextSparkTime = 0;
  final _sparks = <_Spark>[];

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _sparkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _heartbeatController.dispose();
    _particleController.dispose();
    _sparkController.dispose();
    super.dispose();
  }

  void _triggerHeartbeat() {
    _heartbeatController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    _updateSpring();
    _updateSparks();

    final active = widget.state != OrbState.idle;
    if (active) _triggerHeartbeat();

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_breathController, _heartbeatController, _particleController, _sparkController]),
      builder: (context, _) {
        final breath = _breathController.value;
        final heartbeat =
            _heartbeatController.value * (1 - _heartbeatController.value) * 4;

        // Compute motion blur offset based on velocity
        final blurDx = (_velocityX * 0.3).clamp(-8.0, 8.0);
        final blurDy = (_velocityY * 0.3).clamp(-8.0, 8.0);

        // Magnetic stretch when hand is close (high intensity)
        final stretch = 1.0 + widget.intensity * 0.06;

        return Container(
          width: widget.size * 2.2,
          height: widget.size * 2.2,
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(_currentX, _currentY),
            child: Opacity(
              opacity: widget.state == OrbState.error ? 0.6 + breath * 0.4 : 1.0,
              child: CustomPaint(
                size: Size(widget.size * stretch, widget.size / stretch),
                painter: _OrbPainter(
                  state: widget.state,
                  progress: widget.progress,
                  intensity: widget.intensity,
                  breath: breath,
                  heartbeat: heartbeat,
                  time: _particleController.value * math.pi * 2,
                  sparkTime: _sparkController.value * 100,
                  random: _random,
                  sparks: _sparks,
                  trail: _trailHistory,
                  blurDx: blurDx,
                  blurDy: blurDy,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updateSpring() {
    final targetX = widget.targetPosition.dx;
    final targetY = widget.targetPosition.dy;

    // Track velocity for prediction
    final dt = 0.016;

    // Velocity-based prediction for smooth following
    final velX = (targetX - _prevTargetX) / dt;
    final velY = (targetY - _prevTargetY) / dt;
    _prevTargetX = targetX;
    _prevTargetY = targetY;

    // Blend target with prediction for smooth following
    final followX = targetX + (velX * 0.04);
    final followY = targetY + (velY * 0.04);

    // Softer spring = magnetic feel
    final stiffness = 120.0; // Lower = softer, more lag
    final damping = 12.0; // Lower = more overshoot

    final forceX = (followX - _currentX) * stiffness;
    final forceY = (followY - _currentY) * stiffness;

    _velocityX = (_velocityX + forceX * dt) * (1 - damping * dt);
    _velocityY = (_velocityY + forceY * dt) * (1 - damping * dt);

    _currentX += _velocityX * dt;
    _currentY += _velocityY * dt;

    // Store trail history for motion blur
    _trailHistory.add(Offset(_currentX, _currentY));
    if (_trailHistory.length > _trailLength) {
      _trailHistory.removeAt(0);
    }

    if (mounted) setState(() {});
  }

  void _updateSparks() {
    final active = widget.state != OrbState.idle && widget.state != OrbState.completed;
    if (!active) {
      _sparks.clear();
      return;
    }

    _nextSparkTime -= 0.016;
    if (_nextSparkTime <= 0) {
      final angle = _random.nextDouble() * math.pi * 2;
      final dist = widget.size * 0.3 * _random.nextDouble();
      _sparks.add(_Spark(
        x: math.cos(angle) * dist,
        y: math.sin(angle) * dist,
        life: 1.0,
        speed: 0.5 + _random.nextDouble() * 1.5,
        angle: angle + (_random.nextDouble() - 0.5) * 0.5,
        length: 3 + _random.nextDouble() * 6,
      ));
      _nextSparkTime = 0.05 + _random.nextDouble() * 0.15;

      // Keep spark count low
      if (_sparks.length > 8) _sparks.removeAt(0);
    }

    for (int i = _sparks.length - 1; i >= 0; i--) {
      _sparks[i].life -= 0.03;
      _sparks[i].x += math.cos(_sparks[i].angle) * _sparks[i].speed;
      _sparks[i].y += math.sin(_sparks[i].angle) * _sparks[i].speed;
      if (_sparks[i].life <= 0) _sparks.removeAt(i);
    }
  }
}

class _Spark {
  double x, y, life, speed, angle, length;
  _Spark({
    required this.x,
    required this.y,
    required this.life,
    required this.speed,
    required this.angle,
    required this.length,
  });
}

class _OrbPainter extends CustomPainter {
  final OrbState state;
  final double progress;
  final double intensity;
  final double breath;
  final double heartbeat;
  final double time;
  final double sparkTime;
  final math.Random random;
  final List<_Spark> sparks;
  final List<Offset> trail;
  final double blurDx;
  final double blurDy;

  _OrbPainter({
    required this.state,
    required this.progress,
    required this.intensity,
    required this.breath,
    required this.heartbeat,
    required this.time,
    required this.sparkTime,
    required this.random,
    required this.sparks,
    required this.trail,
    required this.blurDx,
    required this.blurDy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (size.width / 2).clamp(1.0, double.infinity);
    final pulseRadius =
        baseRadius * (1.0 + breath * 0.05 + heartbeat * 0.04);

    // Draw motion blur trail behind orb
    _drawMotionBlur(canvas, center, pulseRadius);

    // Multi-layer volumetric glow
    _drawVolumetricGlow(canvas, center, pulseRadius);

    // Animated light rays
    _drawLightRays(canvas, center, pulseRadius);

    // Energy surface arcs
    _drawEnergyArcs(canvas, center, pulseRadius);

    // Plasma interior
    _drawPlasma(canvas, center, pulseRadius);

    // Orb core
    _drawOrbCore(canvas, center, pulseRadius);

    // Dynamic reflections
    _drawReflections(canvas, center, pulseRadius);

    // Progress ring
    _drawProgressRing(canvas, center, pulseRadius);

    // Electrical sparks
    _drawSparks(canvas, center, pulseRadius);

    // Particle system
    if (state == OrbState.idle) {
      _drawIdleParticles(canvas, center, pulseRadius);
    } else {
      _drawActiveParticles(canvas, center, pulseRadius);
    }

    // Comet trail for launching
    if (state == OrbState.launching) {
      _drawCometTrail(canvas, center, pulseRadius);
    }

    // Energy distortion edge
    _drawDistortionEdge(canvas, center, pulseRadius);

    // Top bloom overlay
    _drawBloom(canvas, center, pulseRadius);

    // Info labels
    if (state == OrbState.transferring || state == OrbState.packing) {
      _drawOverlayInfo(canvas, center, pulseRadius, size);
    }
  }

  void _drawMotionBlur(Canvas canvas, Offset center, double radius) {
    if (trail.length < 2) return;
    final speed = math.sqrt(blurDx * blurDx + blurDy * blurDy);
    if (speed < 0.5) return;

    for (int i = 0; i < trail.length - 1; i++) {
      final t = i / trail.length;
      final alpha = (1 - t) * 0.08 * (speed / 5).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(
          center.dx + trail[i].dx - blurDx * (1 - t),
          center.dy + trail[i].dy - blurDy * (1 - t),
        ),
        radius * (0.6 + t * 0.4),
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );
    }
  }

  void _drawVolumetricGlow(Canvas canvas, Offset center, double radius) {
    final glowRadius = radius * 4.0;
    final alpha = (0.12 + intensity * 0.4 + breath * 0.06 + heartbeat * 0.1)
        .clamp(0.0, 0.7);

    // Layer 1: Wide diffuse glow
    canvas.drawCircle(
      center,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: alpha * 0.6),
            AppColors.primary.withValues(alpha: alpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
    );

    // Layer 2: Inner bright glow
    canvas.drawCircle(
      center,
      radius * 2.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: alpha * 0.3),
            AppColors.accent.withValues(alpha: alpha * 0.4),
            Colors.transparent,
          ],
          stops: const [0.0, 0.3, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 2.5)),
    );

    // Layer 3: Pulse ring glow
    final ringPulse = (math.sin(time * 2) + 1) / 2;
    canvas.drawCircle(
      center,
      radius * (1.5 + ringPulse * 0.5),
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.15 * ringPulse * intensity),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(
            Rect.fromCircle(center: center, radius: radius * 2)),
    );
  }

  void _drawLightRays(Canvas canvas, Offset center, double radius) {
    final rayCount = 8;
    final rayAlpha =
        (0.04 + intensity * 0.08 + breath * 0.03).clamp(0.0, 0.2);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    for (int i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * math.pi * 2 + time * 0.15;
      canvas.save();
      canvas.rotate(angle);

      final rayPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.accent.withValues(alpha: rayAlpha),
            AppColors.primary.withValues(alpha: rayAlpha * 0.5),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(0, -2, 120, 4));

      canvas.drawRect(Rect.fromLTWH(radius * 0.3, -1.5, radius * 2, 3), rayPaint);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawEnergyArcs(Canvas canvas, Offset center, double radius) {
    if (state == OrbState.idle && intensity < 0.1) return;

    final arcCount = 3;
    for (int i = 0; i < arcCount; i++) {
      final arcAngle = time * (0.5 + i * 0.2) + (i / arcCount) * math.pi * 2;
      final arcLength = 0.8 + math.sin(time * 0.7 + i) * 0.3;
      final arcAlpha =
          (0.15 + intensity * 0.2 + breath * 0.05).clamp(0.0, 0.5);
      final arcRadius = radius * (1.05 + math.sin(time + i) * 0.03);

      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: arcAngle,
          endAngle: arcAngle + arcLength,
          colors: [
            AppColors.accent.withValues(alpha: arcAlpha),
            AppColors.primary.withValues(alpha: arcAlpha * 0.6),
            AppColors.success.withValues(alpha: arcAlpha * 0.3),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 0.8, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: arcRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 + math.sin(time + i) * 0.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        arcAngle,
        arcLength,
        false,
        arcPaint,
      );
    }
  }

  void _drawPlasma(Canvas canvas, Offset center, double radius) {
    final coreRadius = radius * 0.85;

    // Base gradient
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            AppColors.accent.withValues(alpha: 0.7),
            AppColors.primary.withValues(alpha: 0.6),
            AppColors.secondary.withValues(alpha: 0.4),
          ],
          stops: const [0.0, 0.25, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius)),
    );

    // Animated plasma swirls (multiple overlapping sine-wave circles)
    final swirlCount = 5;
    for (int i = 0; i < swirlCount; i++) {
      final swirlAngle = time * (0.3 + i * 0.15) + (i / swirlCount) * math.pi * 2;
      final swirlDist = coreRadius * 0.4 + math.sin(time * 0.7 + i * 1.3) * coreRadius * 0.2;
      final swirlRadius =
          coreRadius * (0.3 + math.sin(time * 0.5 + i * 0.9) * 0.15);
      final sx = center.dx + math.cos(swirlAngle) * swirlDist;
      final sy = center.dy + math.sin(swirlAngle) * swirlDist;
      final swirlAlpha =
          (0.15 + intensity * 0.2 + math.sin(time + i) * 0.05).clamp(0.0, 0.4);

      canvas.drawCircle(
        Offset(sx, sy),
        swirlRadius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: swirlAlpha * 1.5),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(
              center: Offset(sx, sy), radius: swirlRadius)),
      );
    }

    // Inner bright core
    canvas.drawCircle(
      center,
      coreRadius * 0.25,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: center, radius: coreRadius * 0.25)),
    );
  }

  void _drawOrbCore(Canvas canvas, Offset center, double radius) {
    final fillProgress =
        state == OrbState.transferring || state == OrbState.packing
            ? progress
            : 1.0;
    final coreRadius = radius * (0.5 + fillProgress * 0.3);

    // Edge darkening ring
    canvas.drawCircle(
      center,
      coreRadius * 1.05,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            AppColors.secondary.withValues(alpha: 0.3 * (1 - fillProgress)),
          ],
          stops: const [0.7, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: coreRadius * 1.05)),
    );
  }

  void _drawReflections(Canvas canvas, Offset center, double radius) {
    // Moving specular highlight
    final highlightAngle = time * 0.4;
    final hx = center.dx + math.cos(highlightAngle) * radius * 0.3;
    final hy = center.dy + math.sin(highlightAngle) * radius * 0.3;

    canvas.drawCircle(
      Offset(hx, hy),
      radius * 0.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(hx, hy), radius: radius * 0.2)),
    );

    // Secondary smaller highlight
    final h2Angle = highlightAngle + 2.5;
    final h2x = center.dx + math.cos(h2Angle) * radius * 0.5;
    final h2y = center.dy + math.sin(h2Angle) * radius * 0.4;
    canvas.drawCircle(
      Offset(h2x, h2y),
      radius * 0.08,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: Offset(h2x, h2y), radius: radius * 0.08)),
    );
  }

  void _drawProgressRing(Canvas canvas, Offset center, double radius) {
    if (state != OrbState.transferring && state != OrbState.packing) return;

    final ringRadius = radius * 1.3;
    final ringPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, ringRadius, ringPaint);

    if (progress > 0) {
      // Animated dash on progress ring
      final dashAngle = time % (math.pi * 2);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        dashAngle - 0.15,
        0.3,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );

      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: const [AppColors.primary, AppColors.accent, AppColors.success],
          stops: [0.0, progress * 0.7, progress],
        ).createShader(Rect.fromCircle(center: center, radius: ringRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        progressPaint,
      );
    }
  }

  void _drawSparks(Canvas canvas, Offset center, double radius) {
    if (state == OrbState.idle || state == OrbState.completed) return;

    for (final spark in sparks) {
      final sx = center.dx + spark.x;
      final sy = center.dy + spark.y;
      final alpha = spark.life * 0.8;

      // Spark line
      final ex = sx + math.cos(spark.angle) * spark.length;
      final ey = sy + math.sin(spark.angle) * spark.length;

      canvas.drawLine(
        Offset(sx, sy),
        Offset(ex, ey),
        Paint()
          ..color = Colors.white.withValues(alpha: alpha)
          ..strokeWidth = 1.0 + spark.life
          ..strokeCap = StrokeCap.round,
      );

      // Spark glow
      canvas.drawCircle(
        Offset(sx, sy),
        spark.life * 2,
        Paint()
          ..color = AppColors.accent.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  void _drawIdleParticles(Canvas canvas, Offset center, double radius) {
    final count = 16;
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + time * 0.2 + breath * 0.3;
      final orbitRadius =
          radius * (1.2 + math.sin(time * 0.5 + i * 1.1) * 0.15);

      // Z-depth simulation: varying sizes based on distance
      final zPhase = math.sin(time * 0.3 + i * 2.3);
      final layerScale = 0.7 + (zPhase + 1) * 0.15;
      final dist = orbitRadius * layerScale;
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final particleSize = 1.5 + zPhase.abs() * 0.8;

      canvas.drawCircle(
        Offset(px, py),
        particleSize,
        Paint()
          ..color = AppColors.primary
              .withValues(alpha: 0.25 + math.sin(time + i) * 0.08),
      );
    }
  }

  void _drawActiveParticles(Canvas canvas, Offset center, double radius) {
    final count = 28 + (intensity * 16).round();
    final magnetStrength = intensity;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + time * (0.7 + intensity * 0.4);
      final orbitDist =
          radius * 0.6 + math.sin(time * 1.3 + i * 2.1) * radius * 0.35;

      // Magnetic pull toward center when hand is close
      final pullFactor = 1.0 - magnetStrength * 0.3;
      final dist = orbitDist * pullFactor;

      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final particleSize = 1.5 + math.sin(time * 3 + i) * 1.2;
      final alpha =
          (0.35 + math.sin(time * 2 + i * 1.7) * 0.2 + intensity * 0.3)
              .clamp(0.0, 1.0);

      final colors = [AppColors.accent, AppColors.primary, AppColors.success];
      final color = colors[i % colors.length];

      canvas.drawCircle(
        Offset(px, py),
        particleSize * (1.0 + magnetStrength * 0.3),
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter =
              magnetStrength > 0.5 ? const MaskFilter.blur(BlurStyle.normal, 2) : null,
      );
    }

    // Inward spiral trail for packing/carrying
    if (state == OrbState.packing || state == OrbState.carrying) {
      final trailCount = 14;
      for (int i = 0; i < trailCount; i++) {
        final t = ((time + i / trailCount) % 1.0);
        final spiralAngle = t * math.pi * 8;
        final spiralDist = radius * 1.8 * (1 - t * t);
        final px = center.dx + math.cos(spiralAngle) * spiralDist;
        final py = center.dy + math.sin(spiralAngle) * spiralDist;
        final tAlpha = (1 - t) * 0.5;

        canvas.drawCircle(
          Offset(px, py),
          2.5 * (1 - t) + 0.5,
          Paint()..color = AppColors.accent.withValues(alpha: tAlpha),
        );

        // Glow around trail particles
        canvas.drawCircle(
          Offset(px, py),
          5 * (1 - t),
          Paint()
            ..color = AppColors.primary.withValues(alpha: tAlpha * 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
      }
    }
  }

  void _drawCometTrail(Canvas canvas, Offset center, double radius) {
    final trailLen = 18;
    for (int i = 0; i < trailLen; i++) {
      final t = i / trailLen;
      final angle = -math.pi / 2 + t * 0.5;
      final dist = radius * 0.7 + t * t * radius * 4;
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final alpha = (1 - t) * (1 - t) * 0.6;
      final size = 4 * (1 - t) + 0.5;

      canvas.drawCircle(
        Offset(px, py),
        size,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );

      canvas.drawCircle(
        Offset(px, py),
        size * 4,
        Paint()
          ..color = AppColors.primary.withValues(alpha: alpha * 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  void _drawDistortionEdge(Canvas canvas, Offset center, double radius) {
    if (state == OrbState.idle && intensity < 0.2) return;

    final edgeAlpha = (0.08 + intensity * 0.1).clamp(0.0, 0.3);
    final segments = 24;

    final path = Path();
    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * math.pi * 2;
      final wobble = math.sin(angle * 5 + time * 3) * 3 +
          math.sin(angle * 3 + time * 2) * 2;
      final r = radius * 1.02 + wobble;
      final px = center.dx + math.cos(angle) * r;
      final py = center.dy + math.sin(angle) * r;
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: edgeAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawBloom(Canvas canvas, Offset center, double radius) {
    final bloomAlpha =
        (0.05 + intensity * 0.15 + breath * 0.04).clamp(0.0, 0.3);

    canvas.drawCircle(
      center,
      radius * 1.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: bloomAlpha),
            Colors.transparent,
          ],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Error state: red bloom
    if (state == OrbState.error) {
      canvas.drawCircle(
        center,
        radius * 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.red.withValues(alpha: 0.2 + breath * 0.1),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 2))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Completed state: green bloom
    if (state == OrbState.completed) {
      canvas.drawCircle(
        center,
        radius * 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.success.withValues(alpha: 0.15 + heartbeat * 0.1),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 2))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _drawOverlayInfo(
      Canvas canvas, Offset center, double radius, Size size) {
    // Small text labels rendered above orb
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + radius + 8),
    );
  }

  @override
  bool shouldRepaint(_OrbPainter old) =>
      state != old.state ||
      progress != old.progress ||
      intensity != old.intensity ||
      breath != old.breath ||
      heartbeat != old.heartbeat ||
      time != old.time ||
      blurDx != old.blurDx ||
      blurDy != old.blurDy ||
      sparks.length != old.sparks.length;
}
