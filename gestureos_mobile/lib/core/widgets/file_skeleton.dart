import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Skeleton loading placeholder for file grid items.
class FileSkeleton extends StatelessWidget {
  const FileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(40, 40, 10),
              _shimmerBox(22, 22, 11),
            ],
          ),
          const Spacer(),
          _shimmerBox(double.infinity, 12, 4),
          const SizedBox(height: 6),
          _shimmerBox(60, 10, 4),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
