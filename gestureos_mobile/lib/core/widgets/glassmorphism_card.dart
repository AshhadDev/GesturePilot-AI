import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final GestureTapCallback? onTap;
  final double blurIntensity;

  const GlassmorphismCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderColor,
    this.boxShadow,
    this.onTap,
    this.blurIntensity = 12,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(
          color: (borderColor ?? AppColors.border).withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: boxShadow,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      ),
        child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

class PremiumGlassCard extends StatefulWidget {
  final Widget child;
  final double width;
  final double height;
  final double? borderRadius;
  final Color? glowColor;
  final bool animateBorder;
  final GestureTapCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius,
    this.glowColor,
    this.animateBorder = true,
    this.onTap,
    this.padding,
  });

  @override
  State<PremiumGlassCard> createState() => _PremiumGlassCardState();
}

class _PremiumGlassCardState extends State<PremiumGlassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? AppColors.accent;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowPhase = _glowController.value;
        final glowAlpha = (0.1 + glowPhase * 0.2).clamp(0.0, 0.3);

        return Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
            border: Border.all(
              color: glow.withValues(alpha: widget.animateBorder ? glowAlpha : 0.15),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: glowAlpha * 0.5),
                blurRadius: 12 + glowPhase * 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedShadowContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final double elevation;
  final double borderRadius;

  const AnimatedShadowContainer({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.elevation = 8,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: elevation * 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: elevation * 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
