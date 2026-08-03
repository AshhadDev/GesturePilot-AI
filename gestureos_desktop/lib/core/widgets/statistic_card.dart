import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';

class StatisticCard extends StatefulWidget {
  const StatisticCard({
    super.key,
    required this.label,
    required this.icon,
    this.value = '',
    this.animatedValue,
    this.decimals = 0,
    this.suffix = '',
    this.accentColor = AppColors.accent,
  });

  final String label;
  final IconData icon;
  final String value;
  final double? animatedValue;
  final int decimals;
  final String suffix;
  final Color accentColor;

  @override
  State<StatisticCard> createState() => _StatisticCardState();
}

class _StatisticCardState extends State<StatisticCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  String _format(double v) {
    if (widget.decimals == 0) return v.round().toString();
    final fixed = v.toStringAsFixed(widget.decimals);
    return fixed.replaceAll(RegExp(r'\.0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapCancel: () => setState(() => _isPressed = false),
          onTapUp: (_) => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: AppDimensions.animFast,
              padding: const EdgeInsets.all(AppDimensions.cardPadding),
              decoration: BoxDecoration(
                color: _isHovered
                    ? AppColors.cardHover
                    : AppColors.card,
                borderRadius: BorderRadius.circular(
                  AppDimensions.cardRadius,
                ),
                border: Border.all(
                  color: _isHovered
                      ? accent.withValues(alpha: 0.35)
                      : AppColors.border,
                  width: 1,
                ),
                boxShadow: [
                  if (_isHovered)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    child: Icon(widget.icon, color: accent, size: 20),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  if (widget.animatedValue != null)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: widget.animatedValue!),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text(
                        '${_format(v)}${widget.suffix}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  const SizedBox(height: AppDimensions.spacingXs),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
