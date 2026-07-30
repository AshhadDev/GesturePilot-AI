import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_dimensions.dart';

/// Reusable animation helpers for GestureOS.
/// Provides fade, slide, and scale transition widgets.
class FadeInWidget extends StatelessWidget {
  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = AppDimensions.durationNormal,
    this.delay = Duration.zero,
    this.curve = AppDimensions.curveDefault,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + delay,
      curve: Interval(
        delay.inMicroseconds / (duration + delay).inMicroseconds,
        1.0,
        curve: curve,
      ),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }
}

class SlideInWidget extends StatelessWidget {
  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = AppDimensions.durationNormal,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.1),
    this.curve = AppDimensions.curveDefault,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset beginOffset;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(begin: beginOffset, end: Offset.zero),
      duration: duration + delay,
      curve: Interval(
        delay.inMicroseconds / (duration + delay).inMicroseconds,
        1.0,
        curve: curve,
      ),
      builder: (context, value, child) {
        return Transform.translate(
          offset: value,
          child: child,
        );
      },
      child: child,
    );
  }
}

class ScaleInWidget extends StatelessWidget {
  const ScaleInWidget({
    super.key,
    required this.child,
    this.duration = AppDimensions.durationNormal,
    this.delay = Duration.zero,
    this.beginScale = 0.8,
    this.curve = AppDimensions.curveDefault,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double beginScale;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: beginScale, end: 1.0),
      duration: duration + delay,
      curve: Interval(
        delay.inMicroseconds / (duration + delay).inMicroseconds,
        1.0,
        curve: curve,
      ),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
}
