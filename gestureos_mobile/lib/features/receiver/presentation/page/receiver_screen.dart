import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/enhanced_orb.dart';
import 'package:gesture_os/core/widgets/glassmorphism_card.dart';
import 'package:gesture_os/core/widgets/receiver_scan_animation.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/camera_preview_widget.dart';
import 'package:gesture_os/features/receiver/providers/receiver_provider.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';
import 'package:gesture_os/shared/services/network_service.dart';

class ReceiverScreen extends ConsumerStatefulWidget {
  const ReceiverScreen({super.key});

  @override
  ConsumerState<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends ConsumerState<ReceiverScreen>
    with TickerProviderStateMixin {
  StreamSubscription<TcpConnection>? _connSub;
  late final AnimationController _flyInController;
  late final AnimationController _explodeController;
  late final AnimationController _pulseController;
  bool _showExplosion = false;

  @override
  void initState() {
    super.initState();
    _connSub = NetworkService.instance.onIncomingConnection.listen((conn) {
      final notifier = ref.read(receiverProvider.notifier);
      notifier.onIncomingConnection(conn.remoteHost);
    });

    _flyInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _explodeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _flyInController.dispose();
    _explodeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerFlyIn() {
    _flyInController.forward(from: 0);
    _showExplosion = false;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _explodeController.forward(from: 0);
        setState(() => _showExplosion = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rs = ref.watch(receiverProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 16),
                CameraPreviewWidget(
                  height: 140,
                  showGlow: !rs.isIdle,
                  debugMode: false,
                  currentStateLabel: _stateLabel(rs.step),
                  onHandDetected: (_) =>
                      ref.read(receiverProvider.notifier).onClosedFistDetected(),
                  onHandLost: () =>
                      ref.read(receiverProvider.notifier).onHandLost(),
                  onFistLost: () =>
                      ref.read(receiverProvider.notifier).onFistLost(),
                  onConfidenceUpdate: (c) {},
                  onHandPosition: (_, _) {},
                ),
                const SizedBox(height: 16),
                Expanded(child: _buildBody(rs)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ReceiverState rs) {
    switch (rs.step) {
      case ReceiverStep.idle:
        return _buildIdle();
      case ReceiverStep.closedFistDetected:
        return _buildClosedFist();
      case ReceiverStep.waitingForOpenHand:
        return _buildWaitingOpen();
      case ReceiverStep.unpacking:
        if (!_showExplosion) _triggerFlyIn();
        return _buildUnpacking(rs);
      case ReceiverStep.completed:
        return _buildCompleted(rs);
    }
  }

  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ReceiverScanAnimation(size: 180),
        const SizedBox(height: 16),
        PremiumGlassCard(
          height: 70,
          padding: const EdgeInsets.all(16),
          glowColor: AppColors.accent,
          animateBorder: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.back_hand_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Make a fist to receive',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Your hand will become the receiver',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClosedFist() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Awakening orb animation',
            child: const EnhancedOrb(
              size: 100,
              state: OrbState.awakening,
              intensity: 0.8,
            ),
          ),
          const SizedBox(height: 24),
          PremiumGlassCard(
            height: 70,
            padding: const EdgeInsets.all(16),
            glowColor: AppColors.accent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pan_tool_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open your hand',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Release to prepare for incoming files',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingOpen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Waiting for transfer orb animation',
            child: const EnhancedOrb(
              size: 100,
              state: OrbState.active,
              intensity: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          PremiumGlassCard(
            height: 70,
            padding: const EdgeInsets.all(16),
            glowColor: AppColors.primary,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.wifi_tethering_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waiting for transfer...',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Sender will connect shortly',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpacking(ReceiverState rs) {
    final progress = rs.transferProgress;

    return AnimatedBuilder(
      animation: Listenable.merge([_flyInController, _explodeController, _pulseController]),
      builder: (context, _) {
        final flyIn = _flyInController.value;
        final explode = _explodeController.value;
        final pulse = _pulseController.value;

        // Phase 1 (0-0.15): Orb flies into hand
        final flyInScale = 0.5 + flyIn * 0.5;
        final flyInOpacity = (1 - flyIn).clamp(0.0, 1.0);
        final flyInY = (1 - flyIn) * 80;

        // Phase 2 (0.15-0.35): Explosion
        final explodePhase = explode;
        final showExplosion = _showExplosion && explodePhase < 1.0;

        // Phase 3 (0.35+): Reconstruction
        final reconPhase =
            ((progress - 0.15) / 0.85).clamp(0.0, 1.0);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fly-in orb
                  if (flyIn < 1.0)
                    Transform.translate(
                      offset: Offset(0, flyInY),
                      child: Opacity(
                        opacity: flyInOpacity,
                        child: Transform.scale(
                          scale: flyInScale,
                          child: const EnhancedOrb(
                            size: 80,
                            state: OrbState.transferring,
                            intensity: 1.0,
                          ),
                        ),
                      ),
                    ),
                  // Explosion particles
                  if (showExplosion)
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _ExplosionPainter(
                        phase: explodePhase,
                        fileCount: rs.fileCount > 0 ? rs.fileCount : 3,
                      ),
                    ),
                  // Reconstruction phase
                  if (reconPhase > 0)
                    CustomPaint(
                      size: const Size(200, 200),
                      painter: _ReconstructionPainter(
                        phase: reconPhase,
                        fileCount: rs.fileCount > 0 ? rs.fileCount : 3,
                        pulse: pulse,
                      ),
                    ),
                  // Progress indicator ring
                  if (reconPhase > 0)
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          progress: reconPhase,
                          pulse: pulse,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PremiumGlassCard(
              height: 130,
              padding: const EdgeInsets.all(16),
              glowColor: AppColors.accent,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Center(
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reconPhase < 0.5
                                  ? 'Receiving files...'
                                  : 'Reconstructing...',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (rs.senderName.isNotEmpty)
                              Text(
                                'from ${rs.senderName}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompleted(ReceiverState rs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Transfer complete checkmark',
            child: const EnhancedOrb(
              size: 110,
              state: OrbState.completed,
              progress: 1.0,
              intensity: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          PremiumGlassCard(
            height: 70,
            padding: const EdgeInsets.all(16),
            glowColor: AppColors.success,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Files received!',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${rs.fileCount} file${rs.fileCount == 1 ? '' : 's'} from ${rs.senderName}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              ref.read(transferProvider.notifier).setStatus(TransferState.success);
              context.goNamed(RouteNames.transferSuccess);
            },
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
                  'Done',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.home),
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
          'Receive Files',
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

  String _stateLabel(ReceiverStep step) {
    switch (step) {
      case ReceiverStep.idle:
        return 'Waiting';
      case ReceiverStep.closedFistDetected:
        return 'Fist Detected';
      case ReceiverStep.waitingForOpenHand:
        return 'Open Hand';
      case ReceiverStep.unpacking:
        return 'Receiving';
      case ReceiverStep.completed:
        return 'Complete';
    }
  }
}

class _ExplosionPainter extends CustomPainter {
  final double phase;
  final int fileCount;

  _ExplosionPainter({required this.phase, required this.fileCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Expanding particle ring
    final ringRadius = 20 + phase * 80;
    canvas.drawCircle(
      center,
      ringRadius,
      Paint()
        ..color = AppColors.accent.withValues(alpha: (1 - phase) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - phase),
    );

    // Particle burst
    final burstCount = 20;
    for (int i = 0; i < burstCount; i++) {
      final angle = (i / burstCount) * math.pi * 2;
      final dist = phase * 90;
      final px = center.dx + math.cos(angle) * dist;
      final py = center.dy + math.sin(angle) * dist;
      final alpha = (1 - phase).clamp(0.0, 1.0);
      final size_ = 2 + (1 - phase) * 3;

      canvas.drawCircle(
        Offset(px, py),
        size_,
        Paint()..color = AppColors.accent.withValues(alpha: alpha),
      );
    }

    // Shockwave
    if (phase < 0.5) {
      final shockR = phase * 2 * 60;
      canvas.drawCircle(
        center,
        shockR,
        Paint()
          ..color = Colors.white.withValues(alpha: (1 - phase * 2) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - phase * 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ExplosionPainter old) => phase != old.phase;
}

class _ReconstructionPainter extends CustomPainter {
  final double phase;
  final int fileCount;
  final double pulse;

  _ReconstructionPainter({
    required this.phase,
    required this.fileCount,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final fileCountD = fileCount.toDouble();

    // File icons flying in from orbit
    for (int i = 0; i < fileCount; i++) {
      final orbitAngle = (i / fileCountD) * math.pi * 2;
      final entryPhase = ((phase * fileCountD - i) / fileCountD).clamp(0.0, 1.0);
      final dist = (1 - entryPhase) * 80;
      final size_ = 10 + entryPhase * 20;
      final alpha = entryPhase;

      final fx = center.dx + math.cos(orbitAngle) * dist;
      final fy = center.dy + math.sin(orbitAngle) * dist;

      // File card
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(fx, fy), width: size_, height: size_ * 1.3),
        const Radius.circular(3),
      );

      canvas.drawRRect(
        rect,
        Paint()
          ..color = AppColors.accent.withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // File icon line
      if (entryPhase > 0.5) {
        final lineAlpha = (entryPhase - 0.5) * 2;
        canvas.drawLine(
          Offset(fx - size_ * 0.25, fy - size_ * 0.1),
          Offset(fx + size_ * 0.25, fy - size_ * 0.1),
          Paint()
            ..color = AppColors.primary.withValues(alpha: lineAlpha * 0.6)
            ..strokeWidth = 1.5,
        );
        canvas.drawLine(
          Offset(fx - size_ * 0.25, fy + size_ * 0.1),
          Offset(fx + size_ * 0.25, fy + size_ * 0.1),
          Paint()
            ..color = AppColors.primary.withValues(alpha: lineAlpha * 0.4)
            ..strokeWidth = 1,
        );
      }
    }

    // Success glow when complete
    if (phase >= 0.95) {
      final glowAlpha = (phase - 0.95) * 20;
      canvas.drawCircle(
        center,
        30 + pulse * 10,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.success.withValues(alpha: glowAlpha * 0.3),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: 50)),
      );
    }
  }

  @override
  bool shouldRepaint(_ReconstructionPainter old) =>
      phase != old.phase || pulse != old.pulse;
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _ProgressRingPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppColors.border.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        -math.pi / 2,
        progress * math.pi * 2,
        false,
        Paint()
          ..shader = SweepGradient(
            colors: [
              AppColors.accent,
              AppColors.success.withValues(alpha: 0.8),
            ],
            stops: [0.0, progress],
          ).createShader(Rect.fromCircle(center: center, radius: r))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // Animated dash
    final dashAngle = (pulse * math.pi * 2) % (math.pi * 2);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      dashAngle - 0.1,
      0.2,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      progress != old.progress || pulse != old.pulse;
}
