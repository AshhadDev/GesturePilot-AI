import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';

class ConnectionBadge extends StatelessWidget {
  const ConnectionBadge({
    super.key,
    required this.status,
    this.label,
  });

  final DeviceConnectionStatus status;
  final String? label;

  Color get _color {
    switch (status) {
      case DeviceConnectionStatus.disconnected:
        return AppColors.textTertiary;
      case DeviceConnectionStatus.searching:
        return AppColors.accent;
      case DeviceConnectionStatus.connecting:
        return const Color(0xFF3B82F6);
      case DeviceConnectionStatus.connected:
        return AppColors.success;
    }
  }

  String get _defaultLabel {
    switch (status) {
      case DeviceConnectionStatus.disconnected:
        return 'Offline';
      case DeviceConnectionStatus.searching:
        return 'Searching';
      case DeviceConnectionStatus.connecting:
        return 'Connecting';
      case DeviceConnectionStatus.connected:
        return 'Connected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            child: Text(label ?? _defaultLabel),
          ),
        ],
      ),
    );
  }
}
