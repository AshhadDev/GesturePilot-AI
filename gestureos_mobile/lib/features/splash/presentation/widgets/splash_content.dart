import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/glow_container.dart';
import 'package:gesture_os/features/splash/presentation/widgets/splash_logo.dart';
import 'package:gesture_os/features/splash/presentation/widgets/splash_text.dart';

/// Content layout for the splash screen.
/// Composes logo, app name, and tagline with animations.
class SplashContent extends StatelessWidget {
  const SplashContent({
    super.key,
    required this.logoScaleAnimation,
    required this.logoOpacityAnimation,
    required this.textOpacityAnimation,
    required this.taglineOpacityAnimation,
    required this.glowAnimation,
  });

  final Animation<double> logoScaleAnimation;
  final Animation<double> logoOpacityAnimation;
  final Animation<double> textOpacityAnimation;
  final Animation<double> taglineOpacityAnimation;
  final Animation<double> glowAnimation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.background,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0x1A7C3AED),
            AppColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            GlowContainer(
              glowRadius: 80,
              glowOpacity: 0.25,
              child: ScaleTransition(
                scale: logoScaleAnimation,
                child: FadeTransition(
                  opacity: logoOpacityAnimation,
                  child: const SplashLogo(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SplashText(
              textOpacityAnimation: textOpacityAnimation,
              taglineOpacityAnimation: taglineOpacityAnimation,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
