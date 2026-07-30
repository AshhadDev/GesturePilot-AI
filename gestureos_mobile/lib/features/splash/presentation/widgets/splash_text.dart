import 'package:flutter/material.dart';

import 'package:gesture_os/core/constants/app_constants.dart';
import 'package:gesture_os/core/theme/app_colors.dart';

/// App name and tagline text for the splash screen.
/// Animated with staggered fade-in effects.
class SplashText extends StatelessWidget {
  const SplashText({
    super.key,
    required this.textOpacityAnimation,
    required this.taglineOpacityAnimation,
  });

  final Animation<double> textOpacityAnimation;
  final Animation<double> taglineOpacityAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FadeTransition(
          opacity: textOpacityAnimation,
          child: Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 8),
        FadeTransition(
          opacity: taglineOpacityAnimation,
          child: Text(
            AppConstants.appTagline,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}
