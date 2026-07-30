import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/enhanced_orb.dart';
import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/camera_preview_widget.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

class CarryingScreen extends ConsumerStatefulWidget {
  const CarryingScreen({super.key});

  @override
  ConsumerState<CarryingScreen> createState() => _CarryingScreenState();
}

class _CarryingScreenState extends ConsumerState<CarryingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _walkController;
  GestureResult? _lastResult;

  // Walking simulation
  double _walkPhase = 0;
  double _orbTilt = 0;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _walkController.dispose();
    super.dispose();
  }

  void _onContinue() {
    ref.read(transferProvider.notifier).setStatus(TransferState.waitingDesktop);
    context.goNamed(RouteNames.waitingDesktop);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgController, _walkController]),
        builder: (context, _) {
          _walkPhase = _walkController.value * math.pi * 2;
          _orbTilt = math.sin(_walkPhase) * 0.06;

          final shift = _bgController.value;

          return Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2 + shift * 0.15),
                radius: 1.2,
                colors: [
                  AppColors.primary.withValues(alpha: 0.06 + shift * 0.04),
                  AppColors.background,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const Spacer(flex: 1),
                    _buildOrbSection(),
                    const SizedBox(height: 16),
                    CameraPreviewWidget(
                      height: 140,
                      debugMode: false,
                      currentStateLabel: 'Carrying',
                      onConfidenceUpdate: (_) {},
                      onHandPosition: (_, _) {},
                    ),
                    const Spacer(flex: 1),
                    _buildInstructionCard(),
                    const Spacer(flex: 2),
                    _buildContinueButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.magicTransfer),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Carrying',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildOrbSection() {
    final confidence = _lastResult?.confidence ?? 0.5;
    final walkBob = math.sin(_walkPhase) * 6;

    // Orb floats beside fist with trail particles
    return Stack(
      alignment: Alignment.center,
      children: [
        // Falling trail particles
        CustomPaint(
          size: const Size(260, 260),
          painter: _TrailPainter(
            time: _walkPhase,
            intensity: confidence,
            walkBob: walkBob,
            orbTilt: _orbTilt,
          ),
        ),
        // Tilted orb with walking bob
        Transform.translate(
          offset: Offset(8 + _orbTilt * 40, walkBob),
          child: Transform.rotate(
            angle: _orbTilt,
            child: EnhancedOrb(
              size: 110,
              state: OrbState.carrying,
              intensity: confidence,
              progress: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: AppColors.accent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Walk to your desktop',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep your hand closed.\nThe orb is carrying your files.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return GestureDetector(
      onTap: _onContinue,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "I'm at my desktop",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final double time;
  final double intensity;
  final double walkBob;
  final double orbTilt;

  _TrailPainter({
    required this.time,
    required this.intensity,
    this.walkBob = 0,
    this.orbTilt = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2 + 8 + orbTilt * 40, size.height / 2 + walkBob);

    // Falling trail particles behind orb
    final count = 20;
    for (int i = 0; i < count; i++) {
      final t = (i / count);
      final age = ((time / (math.pi * 2)) + t) % 1.0;
      final fallAngle = -math.pi / 2 + math.sin(age * math.pi * 3 + i) * 0.3;
      final fallDist = 20 + age * 80 + math.sin(age * 5 + i) * 10;
      final px = center.dx + math.cos(fallAngle) * fallDist + math.sin(time + i) * 8;
      final py = center.dy + math.sin(fallAngle) * fallDist + age * 40;

      final alpha = (1 - age) * 0.4 * intensity;
      final pSize = 2 * (1 - age) + 0.5;

      canvas.drawCircle(
        Offset(px, py),
        pSize,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );

      // Glow for larger particles
      if (pSize > 1.5) {
        canvas.drawCircle(
          Offset(px, py),
          pSize * 3,
          Paint()
            ..color = AppColors.primary.withValues(alpha: alpha * 0.15)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // Motion lines
    if (intensity > 0.3) {
      for (int i = 0; i < 6; i++) {
        final linePhase = ((time / (math.pi * 2)) + i / 6) % 1.0;
        final lx = center.dx + math.sin(time * 0.5 + i) * 30 - 20;
        final ly = center.dy - 30 + linePhase * 80;
        final lAlpha = (1 - linePhase) * 0.15 * intensity;
        final lWidth = 1.5 + math.sin(time + i) * 0.5;

        canvas.drawLine(
          Offset(lx - 10, ly),
          Offset(lx + 10, ly),
          Paint()
            ..color = AppColors.accent.withValues(alpha: lAlpha)
            ..strokeWidth = lWidth
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      time != old.time || intensity != old.intensity || walkBob != old.walkBob;
}
