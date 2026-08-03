import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';
import 'package:gesture_os/shared/services/audio_service.dart';
import 'package:gesture_os/shared/services/network_service.dart';

// ---------------------------------------------------------------------------
//  New 6-state flow (open-hand only, no fist)
//   idle → openHandDetected → handConfirmed → packing → packed → carrying
// ---------------------------------------------------------------------------

enum MagicPickupStep {
  idle,
  openHandDetected,
  handConfirmed,
  packing,
  packed,
  carrying,
}

class MagicPickupState {
  const MagicPickupState({
    this.step = MagicPickupStep.idle,
    this.confidence = 0.0,
    this.packingProgress = 0.0,
    this.isDebugMode = false,
    this.selectedFileCount = 0,
    this.handX = 0.5,
    this.handY = 0.5,
  });

  final MagicPickupStep step;
  final double confidence;
  final double packingProgress;
  final bool isDebugMode;
  final int selectedFileCount;
  final double handX;
  final double handY;

  bool get isIdle => step == MagicPickupStep.idle;
  bool get isOpenHandDetected => step == MagicPickupStep.openHandDetected;
  bool get isHandConfirmed => step == MagicPickupStep.handConfirmed;
  bool get isPacking => step == MagicPickupStep.packing;
  bool get isPacked => step == MagicPickupStep.packed;
  bool get isCarrying => step == MagicPickupStep.carrying;
  bool get isComplete => step == MagicPickupStep.packed;

  MagicPickupState copyWith({
    MagicPickupStep? step,
    double? confidence,
    double? packingProgress,
    bool? isDebugMode,
    int? selectedFileCount,
    double? handX,
    double? handY,
  }) {
    return MagicPickupState(
      step: step ?? this.step,
      confidence: confidence ?? this.confidence,
      packingProgress: packingProgress ?? this.packingProgress,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      selectedFileCount: selectedFileCount ?? this.selectedFileCount,
      handX: handX ?? this.handX,
      handY: handY ?? this.handY,
    );
  }
}

class MagicPickupNotifier extends StateNotifier<MagicPickupState> {
  final Ref _ref;
  MagicPickupNotifier(this._ref) : super(const MagicPickupState());

  Timer? _handConfirmTimer;

  @override
  void dispose() {
    _handConfirmTimer?.cancel();
    super.dispose();
  }

  void setDebugMode(bool value) {
    state = state.copyWith(isDebugMode: value);
  }

  void setSelectedFileCount(int count) {
    state = state.copyWith(selectedFileCount: count);
  }

  // ========================================================================
  //  Called by camera_preview_widget on reliable hand transitions
  // ========================================================================

  void onHandDetected(GestureResult result) {
    if (state.step != MagicPickupStep.idle) return;
    state = state.copyWith(
      step: MagicPickupStep.openHandDetected,
      confidence: result.confidence,
    );
    AudioService.playHandDetected();
    _startHandConfirmTimer();
  }

  void onHandLost() {
    if (state.step == MagicPickupStep.openHandDetected ||
        state.step == MagicPickupStep.handConfirmed) {
      _handConfirmTimer?.cancel();
      state = const MagicPickupState();
    }
  }

  void updateConfidence(double confidence) {
    state = state.copyWith(confidence: confidence.clamp(0.0, 1.0));
  }

  void updateHandPosition(double x, double y) {
    state = state.copyWith(handX: x.clamp(0.0, 1.0), handY: y.clamp(0.0, 1.0));
  }

  // ========================================================================
  //  Timer: openHandDetected → handConfirmed (500 ms steady hold)
  // ========================================================================

  void _startHandConfirmTimer() {
    _handConfirmTimer?.cancel();
    _handConfirmTimer = Timer(const Duration(milliseconds: 500), () {
      if (state.step != MagicPickupStep.openHandDetected) return;
      state = state.copyWith(
        step: MagicPickupStep.handConfirmed,
        confidence: state.confidence,
      );
      AudioService.playPickupStart();
      _startPacking();
    });
  }

  // ========================================================================
  //  Real packing: handConfirmed → packed (file preparation)
  // ========================================================================

  void _startPacking() {
    state = state.copyWith(
      step: MagicPickupStep.packing,
      packingProgress: 0.0,
    );

    _doPacking();
  }

  Future<void> _doPacking() async {
    final files = _ref.read(transferProvider).selectedFiles;
    final total = files.length;

    if (total == 0) {
      _completePacking();
      return;
    }

    state = state.copyWith(selectedFileCount: total);

    for (int i = 0; i < total; i++) {
      if (state.step != MagicPickupStep.packing) return;
      final file = files[i];
      final entity = FileSystemEntity.typeSync(file.path);
      if (entity == FileSystemEntityType.notFound) {
        continue;
      }

      final progress = ((i + 1) / total).clamp(0.0, 1.0);
      state = state.copyWith(packingProgress: progress);

      // Small yield to keep UI responsive
      await Future.delayed(const Duration(milliseconds: 16));
    }

    _completePacking();
  }

  void _completePacking() {
    if (state.step != MagicPickupStep.packing) return;
    state = state.copyWith(
      step: MagicPickupStep.packed,
      packingProgress: 1.0,
    );
    AudioService.playPackingComplete();
  }

  void transitionToCarrying() {
    if (state.step != MagicPickupStep.packed) return;
    state = state.copyWith(step: MagicPickupStep.carrying);
    _ref.read(transferProvider.notifier).setStatus(TransferState.carrying);
    NetworkService.instance.startServer();
  }

  // ========================================================================
  //  Advance helpers (used by DebugSimulationButton)
  // ========================================================================

  void advanceToOpenHandDetected() {
    if (state.step != MagicPickupStep.idle) return;
    state = state.copyWith(
      step: MagicPickupStep.openHandDetected,
      confidence: 0.85,
    );
    AudioService.playHandDetected();
    _startHandConfirmTimer();
  }

  void advanceToPacking() {
    if (state.step != MagicPickupStep.openHandDetected &&
        state.step != MagicPickupStep.handConfirmed) {
      return;
    }
    _handConfirmTimer?.cancel();
    AudioService.playPickupStart();
    _startPacking();
  }

  void advanceToPacked() {
    if (state.step != MagicPickupStep.packing) return;
    _completePacking();
  }

  void simulateAdvance() {
    switch (state.step) {
      case MagicPickupStep.idle:
        advanceToOpenHandDetected();
      case MagicPickupStep.openHandDetected:
      case MagicPickupStep.handConfirmed:
        advanceToPacking();
      case MagicPickupStep.packing:
        advanceToPacked();
      case MagicPickupStep.packed:
      case MagicPickupStep.carrying:
        break;
    }
  }

  void resetToIdle() {
    _handConfirmTimer?.cancel();
    state = const MagicPickupState();
  }
}

final magicPickupProvider =
    StateNotifierProvider<MagicPickupNotifier, MagicPickupState>((ref) {
  return MagicPickupNotifier(ref);
});
