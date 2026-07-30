import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Container with a soft radial glow effect behind it.
/// Used for neon/glow visual effects on cards and icons.
class GlowContainer extends StatelessWidget {
  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = AppColors.glowPurple,
    this.glowRadius = 60,
    this.glowOpacity = 0.3,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double glowOpacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowOpacity),
            blurRadius: glowRadius,
            spreadRadius: -glowRadius / 3,
          ),
        ],
      ),
      child: child,
    );
  }
}
