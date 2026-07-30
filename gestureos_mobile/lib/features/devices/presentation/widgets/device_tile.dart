import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/device_model.dart';

class DeviceTile extends StatelessWidget {
  final Device device;
  final bool isTrusted;
  final VoidCallback? onTap;
  final VoidCallback? onTrust;
  final VoidCallback? onForget;

  const DeviceTile({
    super.key,
    required this.device,
    this.isTrusted = false,
    this.onTap,
    this.onTrust,
    this.onForget,
  });

  IconData _platformIcon() {
    switch (device.platform) {
      case DevicePlatform.android: return Icons.phone_android_rounded;
      case DevicePlatform.iOS: return Icons.phone_iphone_rounded;
      case DevicePlatform.windows: return Icons.computer_rounded;
      case DevicePlatform.macOS: return Icons.laptop_mac_rounded;
      case DevicePlatform.linux: return Icons.terminal_rounded;
      case DevicePlatform.web: return Icons.language_rounded;
      case DevicePlatform.unknown: return Icons.devices_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = device.isOnline;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTrusted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isOnline
                        ? AppColors.primaryGradient
                        : LinearGradient(colors: [
                            AppColors.textSecondary.withValues(alpha: 0.3),
                            AppColors.textSecondary.withValues(alpha: 0.1),
                          ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _platformIcon(),
                    color: isOnline ? Colors.white : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${device.platformLabel} \u2022 ${device.ip}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isTrusted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Trusted',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                if (!isOnline)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  )
                else if (device.status == DeviceStatus.online || device.status == DeviceStatus.trusted)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                if (onTrust != null && !isTrusted)
                  _actionButton(Icons.favorite_border_rounded, AppColors.primary, onTrust!),
                if (onForget != null)
                  _actionButton(Icons.close_rounded, AppColors.error, onForget!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
