import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/theme/app_dimensions.dart';

/// Animated page indicator dots matching reference design exactly.
/// Three small circles, active purple, inactive gray, centered.
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.activeColor = AppColors.secondary,
    this.inactiveColor = AppColors.border,
    this.dotSize = 8.0,
    this.activeDotWidth = 8.0,
    this.spacing = 10.0,
  });

  final int currentPage;
  final int totalPages;
  final Color activeColor;
  final Color inactiveColor;
  final double dotSize;
  final double activeDotWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: AnimatedContainer(
            duration: AppDimensions.durationNormal,
            curve: Curves.easeInOut,
            width: isActive ? activeDotWidth : dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: isActive ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
        );
      }),
    );
  }
}
