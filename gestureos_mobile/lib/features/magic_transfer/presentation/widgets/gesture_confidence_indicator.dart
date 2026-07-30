import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class GestureConfidenceIndicator extends StatelessWidget {
  const GestureConfidenceIndicator({
    super.key,
    required this.confidence,
    required this.label,
  });

  final double confidence;
  final String label;

  @override
  Widget build(BuildContext context) {
    final percent = (confidence * 100).toInt();
    final barColor = confidence > 0.9
        ? AppColors.success
        : confidence > 0.7
            ? AppColors.accent
            : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 160,
            height: 8,
            color: AppColors.card,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: confidence.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, barColor],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$percent%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
