import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class PremiumErrorOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final Color? accentColor;

  const PremiumErrorOverlay({
    super.key,
    required this.title,
    required this.message,
    this.details,
    this.onRetry,
    this.onCancel,
    this.accentColor,
  });

  @override
  State<PremiumErrorOverlay> createState() => _PremiumErrorOverlayState();
}

class _PremiumErrorOverlayState extends State<PremiumErrorOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final AnimationController _glowController;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.error;

    return AnimatedBuilder(
      animation: Listenable.merge([_animController, _glowController]),
      builder: (context, _) {
        final enter = _animController.value;
        final glow = _glowController.value;
        final scale = 0.8 + enter * 0.2;
        final opacity = enter;

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated error icon with glow
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.2 + glow * 0.2),
                            blurRadius: 20 + glow * 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _ErrorIconPainter(
                          phase: glow,
                          color: accent,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.details != null) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => setState(() => _showDetails = !_showDetails),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showDetails ? 'Hide details' : 'Show details',
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                              ),
                            ),
                            Icon(
                              _showDetails
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: accent,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      if (_showDetails)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.border,
                            ),
                          ),
                          child: Text(
                            widget.details!,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onCancel != null)
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        if (widget.onRetry != null) ...[
                          if (widget.onCancel != null)
                            const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onRetry,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accent, accent.withValues(alpha: 0.8)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorIconPainter extends CustomPainter {
  final double phase;
  final Color color;

  _ErrorIconPainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      center,
      r * (0.9 + math.sin(phase * math.pi) * 0.05),
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    canvas.drawCircle(
      center,
      r * 0.6,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r * 0.6)),
    );
  }

  @override
  bool shouldRepaint(_ErrorIconPainter old) => phase != old.phase;
}
