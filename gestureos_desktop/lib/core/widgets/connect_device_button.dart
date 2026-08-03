import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';

class ConnectDeviceButton extends StatefulWidget {
  const ConnectDeviceButton({
    super.key,
    this.onPressed,
    this.label = 'Connect Device',
  });

  final VoidCallback? onPressed;
  final String label;

  @override
  State<ConnectDeviceButton> createState() => _ConnectDeviceButtonState();
}

class _ConnectDeviceButtonState extends State<ConnectDeviceButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapCancel: () => setState(() => _isPressed = false),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed?.call();
        },
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: AppDimensions.animNormal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingXl,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              gradient: _isHovered
                  ? AppColors.primaryGradient
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primary],
                    ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: _isHovered ? 0.55 : 0.35,
                  ),
                  blurRadius: _isHovered ? 32 : 20,
                  spreadRadius: _isHovered ? 4 : 0,
                  offset: const Offset(0, 6),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 48,
                    spreadRadius: -4,
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isHovered
                      ? Icons.qr_code_scanner_rounded
                      : Icons.add_link_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
