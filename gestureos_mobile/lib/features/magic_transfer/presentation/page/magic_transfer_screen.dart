import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/animated_file_card.dart';
import 'package:gesture_os/core/widgets/enhanced_orb.dart';
import 'package:gesture_os/core/widgets/packing_sequence.dart';
import 'package:gesture_os/core/widgets/success_celebration.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/camera_preview_widget.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/debug_simulation_button.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/gesture_confidence_indicator.dart';
import 'package:gesture_os/features/magic_transfer/providers/magic_pickup_provider.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

class MagicTransferScreen extends ConsumerStatefulWidget {
  const MagicTransferScreen({super.key});

  @override
  ConsumerState<MagicTransferScreen> createState() =>
      _MagicTransferScreenState();
}

class _MagicTransferScreenState extends ConsumerState<MagicTransferScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final state = ref.read(magicPickupProvider);
    if (state.isPacked) {
      ref.read(magicPickupProvider.notifier).transitionToCarrying();
      ref.read(transferProvider.notifier).setStatus(TransferState.carrying);
      context.goNamed(RouteNames.carrying);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ref.watch(magicPickupProvider);
    final files = ref.read(transferProvider).selectedFiles;
    final fileCount = files.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(pickup.step),
              const SizedBox(height: 16),
              CameraPreviewWidget(
                showGlow: pickup.isOpenHandDetected || pickup.isHandConfirmed,
                debugMode: pickup.isDebugMode,
                currentStateLabel: _headerLabel(pickup.step),
                onHandDetected: (result) =>
                    ref.read(magicPickupProvider.notifier).onHandDetected(result),
                onHandLost: () =>
                    ref.read(magicPickupProvider.notifier).onHandLost(),
                onConfidenceUpdate: (confidence) =>
                    ref.read(magicPickupProvider.notifier).updateConfidence(confidence),
                onHandPosition: (x, y) =>
                    ref.read(magicPickupProvider.notifier).updateHandPosition(x, y),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(pickup, fileCount, files)),
              DebugSimulationButton(),
              if (pickup.isPacked) _buildContinueButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MagicPickupStep step) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            ref.read(magicPickupProvider.notifier).resetToIdle();
            context.goNamed(RouteNames.home);
          },
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
          _headerLabel(step),
          style: const TextStyle(
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

  String _headerLabel(MagicPickupStep step) {
    switch (step) {
      case MagicPickupStep.idle:
        return 'Magic Transfer';
      case MagicPickupStep.openHandDetected:
      case MagicPickupStep.handConfirmed:
        return 'Hand Detected';
      case MagicPickupStep.packing:
        return 'Packing Files';
      case MagicPickupStep.packed:
        return 'Files Packed';
      case MagicPickupStep.carrying:
        return 'Carrying';
    }
  }

  Widget _buildBody(MagicPickupState pickup, int fileCount, List<dynamic> files) {
    switch (pickup.step) {
      case MagicPickupStep.idle:
        return _buildIdleState(pickup, files);
      case MagicPickupStep.openHandDetected:
      case MagicPickupStep.handConfirmed:
        return _buildHandDetectedState(pickup, files);
      case MagicPickupStep.packing:
        return _buildPackingState(pickup, fileCount, files);
      case MagicPickupStep.packed:
        return _buildPackedState();
      case MagicPickupStep.carrying:
        return _buildCarryingState();
    }
  }

  Widget _buildIdleState(MagicPickupState pickup, List<dynamic> files) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          EnhancedOrb(
            size: 130,
            state: OrbState.idle,
            intensity: 0,
            targetPosition: Offset(0, 0),
          ),
          const SizedBox(height: 16),
          if (files.isNotEmpty)
            SizedBox(
              height: 100,
              child: FloatingFileCards(
                files: files.cast(),
                containerHeight: 100,
                orbiting: true,
              ),
            ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.back_hand_rounded, color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Show your hand',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hold your open palm in front of the camera\nto begin the magic pickup',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandDetectedState(MagicPickupState pickup, List<dynamic> files) {
    return SingleChildScrollView(
      child: Column(
        children: [
          EnhancedOrb(
            size: 140,
            state: OrbState.awakening,
            intensity: pickup.confidence,
            targetPosition: Offset(pickup.handX, pickup.handY),
          ),
          const SizedBox(height: 16),
          if (files.isNotEmpty)
            SizedBox(
              height: 80,
              child: FloatingFileCards(
                files: files.cast(),
                containerHeight: 80,
                orbiting: true,
              ),
            ),
          const SizedBox(height: 12),
          GestureConfidenceIndicator(
            confidence: pickup.confidence,
            label: 'Hand Confidence',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pan_tool_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Hand Detected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Hold steady',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Keep your hand still to start packing',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackingState(MagicPickupState pickup, int fileCount, List<dynamic> files) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          PackingSequence(
            progress: pickup.packingProgress,
            size: 180,
            fileCount: fileCount,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.electric_bolt_rounded, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Packing ($fileCount files)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Your files are being packed into the orb',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackedState() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SuccessCelebration(
            size: 180,
            fileCount: ref.read(transferProvider).selectedCount,
            totalSize: ref.read(transferProvider).totalSizeFormatted,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Your files are packed',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ready',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Walk to your desktop to transfer',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarryingState() {
    return const Center(
      child: Text(
        'Carrying...',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
