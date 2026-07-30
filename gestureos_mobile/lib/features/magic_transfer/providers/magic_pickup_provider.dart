import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/shared/services/audio_service.dart';

// ---------------------------------------------------------------------------
// State machine (sender side):
//   idle → openHandDetected → fistConfirmed → packing → packed
// ---------------------------------------------------------------------------

enum MagicPickupStep {
  idle,
  openHandDetected,
  fistConfirmed,
  packing,
  packed,
}

class MagicPickupState {
  const MagicPickupState({
    this.step = MagicPickupStep.idle,
    this.confidence = 0.0,
    this.holdProgress = 0.0,
    this.packingProgress = 0.0,
    this.isDebugMode = false,
    this.selectedFileCount = 0,
    this.handX = 0.5,
    this.handY = 0.5,
  });

  final MagicPickupStep step;
  final double confidence;
  final double holdProgress;
  final double packingProgress;
  final bool isDebugMode;
  final int selectedFileCount;
  final double handX;
  final double handY;

  bool get isIdle => step == MagicPickupStep.idle;
  bool get isOpenHandDetected => step == MagicPickupStep.openHandDetected;
  bool get isFistConfirmed => step == MagicPickupStep.fistConfirmed;
  bool get isPacking => step == MagicPickupStep.packing;
  bool get isPacked => step == MagicPickupStep.packed;
  bool get isComplete => step == MagicPickupStep.packed;

  MagicPickupState copyWith({
    MagicPickupStep? step,
    double? confidence,
    double? holdProgress,
    double? packingProgress,
    bool? isDebugMode,
    int? selectedFileCount,
    double? handX,
    double? handY,
  }) {
    return MagicPickupState(
      step: step ?? this.step,
      confidence: confidence ?? this.confidence,
      holdProgress: holdProgress ?? this.holdProgress,
      packingProgress: packingProgress ?? this.packingProgress,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      selectedFileCount: selectedFileCount ?? this.selectedFileCount,
      handX: handX ?? this.handX,
      handY: handY ?? this.handY,
    );
  }
}

class MagicPickupNotifier extends StateNotifier<MagicPickupState> {
  MagicPickupNotifier() : super(const MagicPickupState());

  Timer? _fistHoldTimer;
  Timer? _packingTimer;

  @override
  void dispose() {
    _fistHoldTimer?.cancel();
    _packingTimer?.cancel();
    super.dispose();
  }

  void setDebugMode(bool value) {
    state = state.copyWith(isDebugMode: value);
  }

  void setSelectedFileCount(int count) {
    state = state.copyWith(selectedFileCount: count);
  }

  // ========================================================================
  //  Camera callbacks
  // ========================================================================

  /// Hand appeared — transition idle → openHandDetected.
  /// The downstream onFistDetected handles advancing to fistConfirmed
  /// if the hand is already a fist; for open palms the user closes
  /// their fist and onFistDetected handles that too.
  void onHandDetected(GestureResult result) {
    if (state.step != MagicPickupStep.idle) return;
    state = state.copyWith(
      step: MagicPickupStep.openHandDetected,
      confidence: result.confidence,
    );
    AudioService.playHandDetected();
  }

  /// Fist appeared — transition openHandDetected → fistConfirmed + 300 ms hold.
  void onFistDetected(GestureResult result) {
    if (state.step != MagicPickupStep.openHandDetected) return;
    state = state.copyWith(
      step: MagicPickupStep.fistConfirmed,
      confidence: result.confidence,
      holdProgress: 0.0,
    );
    AudioService.playFistConfirmed();
    _startFistHoldTimer();
  }

  /// Fist opened (but hand still present) — revert to openHandDetected.
  void onFistLost() {
    if (state.step == MagicPickupStep.fistConfirmed) {
      _fistHoldTimer?.cancel();
      state = state.copyWith(
        step: MagicPickupStep.openHandDetected,
        holdProgress: 0.0,
      );
    } else if (state.step == MagicPickupStep.idle) {
      // Hand was a fist when it first appeared — now it's an open palm.
      state = state.copyWith(step: MagicPickupStep.openHandDetected);
      AudioService.playHandDetected();
    }
  }

  /// Hand left the frame entirely.
  void onHandLost() {
    if (state.step == MagicPickupStep.openHandDetected ||
        state.step == MagicPickupStep.fistConfirmed) {
      _fistHoldTimer?.cancel();
      state = const MagicPickupState();
    }
  }

  /// Update gesture confidence scalar (called every frame).
  void updateConfidence(double confidence) {
    state = state.copyWith(confidence: confidence.clamp(0.0, 1.0));
  }

  /// Update hand position for MagicOrb tracking.
  void updateHandPosition(double x, double y) {
    state = state.copyWith(handX: x.clamp(0.0, 1.0), handY: y.clamp(0.0, 1.0));
  }

  // ========================================================================
  //  Advance helpers (simulateAdvance uses these)
  // ========================================================================

  void advanceToOpenHandDetected() {
    if (state.step != MagicPickupStep.idle) return;
    state = state.copyWith(
      step: MagicPickupStep.openHandDetected,
      confidence: 0.85,
    );
    AudioService.playHandDetected();
  }

  void advanceToFistConfirmed() {
    if (state.step != MagicPickupStep.openHandDetected) return;
    state = state.copyWith(
      step: MagicPickupStep.fistConfirmed,
      confidence: 0.92,
      holdProgress: 0.0,
    );
    AudioService.playFistConfirmed();
    _startFistHoldTimer();
  }

  void advanceToPacking() {
    if (state.step != MagicPickupStep.fistConfirmed) return;
    _fistHoldTimer?.cancel();
    state = state.copyWith(
      step: MagicPickupStep.packing,
      holdProgress: 1.0,
      packingProgress: 0.0,
    );
    AudioService.playPickupStart();
    _simulatePacking();
  }

  void advanceToPacked() {
    if (state.step != MagicPickupStep.packing) return;
    _packingTimer?.cancel();
    state = state.copyWith(
      step: MagicPickupStep.packed,
      packingProgress: 1.0,
    );
    AudioService.playPackingComplete();
  }

  void simulateAdvance() {
    switch (state.step) {
      case MagicPickupStep.idle:
        advanceToOpenHandDetected();
      case MagicPickupStep.openHandDetected:
        advanceToFistConfirmed();
      case MagicPickupStep.fistConfirmed:
        advanceToPacking();
      case MagicPickupStep.packing:
        advanceToPacked();
      case MagicPickupStep.packed:
        break;
    }
  }

  // ========================================================================
  //  Timers
  // ========================================================================

  void _startFistHoldTimer() {
    _fistHoldTimer?.cancel();
    const duration = Duration(milliseconds: 500);
    const interval = Duration(milliseconds: 16);
    final steps = duration.inMilliseconds / interval.inMilliseconds;
    var count = 0;

    _fistHoldTimer = Timer.periodic(interval, (_) {
      if (!_isValidState(MagicPickupStep.fistConfirmed)) {
        _fistHoldTimer?.cancel();
        return;
      }
      count++;
      final progress = (count / steps).clamp(0.0, 1.0);
      state = state.copyWith(holdProgress: progress);
      if (progress >= 1.0) {
        _fistHoldTimer?.cancel();
        advanceToPacking();
      }
    });
  }

  void _simulatePacking() {
    const duration = Duration(milliseconds: 2000);
    const interval = Duration(milliseconds: 16);
    final steps = duration.inMilliseconds / interval.inMilliseconds;
    var count = 0;

    _packingTimer?.cancel();
    _packingTimer = Timer.periodic(interval, (_) {
      if (!_isValidState(MagicPickupStep.packing)) {
        _packingTimer?.cancel();
        return;
      }
      count++;
      final progress = (count / steps).clamp(0.0, 1.0);
      state = state.copyWith(packingProgress: progress);
      if (progress >= 1.0) {
        _packingTimer?.cancel();
        advanceToPacked();
      }
    });
  }

  void resetToIdle() {
    _fistHoldTimer?.cancel();
    _packingTimer?.cancel();
    state = const MagicPickupState();
  }

  bool _isValidState(MagicPickupStep expected) {
    return state.step == expected;
  }
}

final magicPickupProvider =
    StateNotifierProvider<MagicPickupNotifier, MagicPickupState>((ref) {
  return MagicPickupNotifier();
});
