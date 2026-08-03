import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';

class WaitingBanner extends StatefulWidget {
  const WaitingBanner({super.key, required this.phase, this.progress = 0.0});

  final ConnectionPhase phase;
  final double progress;

  @override
  State<WaitingBanner> createState() => _WaitingBannerState();
}

class _WaitingBannerState extends State<WaitingBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  Timer? _dotsTimer;
  int _dots = 0;

  String _baseMessage() {
    switch (widget.phase) {
      case ConnectionPhase.offline:
        return 'Listening';
      case ConnectionPhase.searching:
        return 'Searching';
      case ConnectionPhase.connecting:
        return 'Preparing secure session';
      case ConnectionPhase.connected:
        return 'Waiting for incoming transfer';
      case ConnectionPhase.receiving:
        return 'Receiving';
      case ConnectionPhase.completed:
        return 'Completed';
    }
  }

  IconData get _icon {
    switch (widget.phase) {
      case ConnectionPhase.offline:
        return Icons.wifi_off_rounded;
      case ConnectionPhase.searching:
        return Icons.radar_rounded;
      case ConnectionPhase.connecting:
        return Icons.shield_rounded;
      case ConnectionPhase.connected:
        return Icons.wifi_tethering_rounded;
      case ConnectionPhase.receiving:
        return Icons.download_rounded;
      case ConnectionPhase.completed:
        return Icons.check_circle_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 450), (_) {
      if (mounted) setState(() => _dots = (_dots + 1) % 4);
    });
  }

  @override
  void dispose() {
    _dotsTimer?.cancel();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final receiving = widget.phase == ConnectionPhase.receiving;
    final completed = widget.phase == ConnectionPhase.completed;
    final accent =
        completed ? AppColors.success : AppColors.accent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.14),
            AppColors.card,
            accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: accent.withValues(alpha: 0.28),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, _) {
              return Transform.rotate(
                angle: widget.phase == ConnectionPhase.searching
                    ? _iconController.value * 2 * 3.14159
                    : 0,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    _icon,
                    color: accent,
                    size: 22,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          '${_baseMessage()}${'.' * _dots}',
                          key: ValueKey(_baseMessage()),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                if (receiving) ...[
                  const SizedBox(height: AppDimensions.spacingSm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      minHeight: 4,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.phase != ConnectionPhase.completed)
            Text(
              receiving
                  ? '${(widget.progress * 100).round()}%'
                  : 'live',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }
}
