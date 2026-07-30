import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

enum FeedbackEvent {
  handDetected,
  fistLocked,
  packing,
  transferStart,
  transferSuccess,
  transferCancel,
  transferError,
  receiverUnpack,
  deviceFound,
}

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void play(FeedbackEvent event) {
    if (!_enabled) return;
    _hapticForEvent(event);
    _visualForEvent(event);
  }

  void _hapticForEvent(FeedbackEvent event) {
    switch (event) {
      case FeedbackEvent.handDetected:
        HapticFeedback.lightImpact();
      case FeedbackEvent.fistLocked:
        HapticFeedback.mediumImpact();
      case FeedbackEvent.packing:
        HapticFeedback.heavyImpact();
      case FeedbackEvent.transferStart:
        HapticFeedback.heavyImpact();
      case FeedbackEvent.transferSuccess:
        _successHaptic();
      case FeedbackEvent.transferCancel:
        HapticFeedback.mediumImpact();
      case FeedbackEvent.transferError:
        HapticFeedback.heavyImpact();
      case FeedbackEvent.receiverUnpack:
        HapticFeedback.mediumImpact();
      case FeedbackEvent.deviceFound:
        HapticFeedback.lightImpact();
    }
  }

  void _successHaptic() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 250), () {
      HapticFeedback.lightImpact();
    });
  }

  void _visualForEvent(FeedbackEvent event) {
    // Visual feedback is handled by UI widgets; this method can trigger
    // screen-wide visual effects if needed in the future.
  }
}

class VisualFeedbackOverlay extends StatefulWidget {
  final Widget child;
  final FeedbackEvent? triggerEvent;

  const VisualFeedbackOverlay({
    super.key,
    required this.child,
    this.triggerEvent,
  });

  @override
  State<VisualFeedbackOverlay> createState() => _VisualFeedbackOverlayState();
}

class _VisualFeedbackOverlayState extends State<VisualFeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rippleController;
  Color _rippleColor = AppColors.accent;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(VisualFeedbackOverlay old) {
    super.didUpdateWidget(old);
    if (widget.triggerEvent != null && widget.triggerEvent != old.triggerEvent) {
      _triggerRipple(widget.triggerEvent!);
    }
  }

  void _triggerRipple(FeedbackEvent event) {
    switch (event) {
      case FeedbackEvent.handDetected:
        _rippleColor = AppColors.primary;
      case FeedbackEvent.fistLocked:
        _rippleColor = AppColors.accent;
      case FeedbackEvent.transferSuccess:
        _rippleColor = AppColors.success;
      case FeedbackEvent.transferError:
        _rippleColor = AppColors.error;
      default:
        _rippleColor = AppColors.accent;
    }
    _rippleController.forward(from: 0);
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rippleController,
      builder: (context, _) {
        final rippleProgress = _rippleController.value;
        final rippleAlpha = (1 - rippleProgress) * 0.3;

        return Stack(
          children: [
            widget.child,
            if (rippleProgress > 0 && rippleProgress < 1)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RipplePainter(
                      progress: rippleProgress,
                      color: _rippleColor,
                      alpha: rippleAlpha,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double alpha;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.alpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final r = maxR * progress;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - progress),
    );
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      progress != old.progress || color != old.color;
}
