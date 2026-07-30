import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_os/core/theme/app_colors.dart';

/// Badge indicating connection status to a desktop device.
class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({
    super.key,
    required this.label,
    this.isConnected = false,
  });

  final String label;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isConnected ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
