import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_os/core/theme/app_colors.dart';

/// Badge indicating connection status to a desktop device.
class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({
    super.key,
    required this.label,
    this.isConnected = false,
    this.isPending = false,
  });

  final String label;
  final bool isConnected;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final color = isConnected
        ? AppColors.success
        : (isPending ? AppColors.secondary : AppColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color,
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
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
