import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Animated logo icon for the splash screen.
/// Displays a futuristic gesture hand icon with purple gradient.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: -8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.back_hand_rounded,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}
