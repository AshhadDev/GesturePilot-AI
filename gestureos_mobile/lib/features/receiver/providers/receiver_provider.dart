import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/services/transfer_service.dart';

// ---------------------------------------------------------------------------
//  Receiver state (open-hand only, no fist)
// ---------------------------------------------------------------------------

enum ReceiverStep {
  idle,
  openHandDetected,
  receiving,
  completed,
}

class ReceiverState {
  const ReceiverState({
    this.step = ReceiverStep.idle,
    this.confidence = 0.0,
    this.senderName = '',
    this.senderDevice = '',
    this.fileNames = const [],
    this.fileCount = 0,
    this.totalSize = '',
    this.transferProgress = 0.0,
    this.unpackProgress = 0.0,
  });

  final ReceiverStep step;
  final double confidence;
  final String senderName;
  final String senderDevice;
  final List<String> fileNames;
  final int fileCount;
  final String totalSize;
  final double transferProgress;
  final double unpackProgress;

  bool get isIdle => step == ReceiverStep.idle;
  bool get isOpenHandDetected => step == ReceiverStep.openHandDetected;
  bool get isReceiving => step == ReceiverStep.receiving;
  bool get isCompleted => step == ReceiverStep.completed;

  ReceiverState copyWith({
    ReceiverStep? step,
    double? confidence,
    String? senderName,
    String? senderDevice,
    List<String>? fileNames,
    int? fileCount,
    String? totalSize,
    double? transferProgress,
    double? unpackProgress,
  }) {
    return ReceiverState(
      step: step ?? this.step,
      confidence: confidence ?? this.confidence,
      senderName: senderName ?? this.senderName,
      senderDevice: senderDevice ?? this.senderDevice,
      fileNames: fileNames ?? this.fileNames,
      fileCount: fileCount ?? this.fileCount,
      totalSize: totalSize ?? this.totalSize,
      transferProgress: transferProgress ?? this.transferProgress,
      unpackProgress: unpackProgress ?? this.unpackProgress,
    );
  }
}

class ReceiverNotifier extends StateNotifier<ReceiverState> {
  ReceiverNotifier() : super(const ReceiverState());

  StreamSubscription<TransferProgress>? _progressSub;

  void onOpenHandDetected() {
    if (state.step != ReceiverStep.idle) return;
    state = state.copyWith(
      step: ReceiverStep.openHandDetected,
      confidence: 0.85,
    );
  }

  void onHandLost() {
    if (state.step == ReceiverStep.openHandDetected ||
        state.step == ReceiverStep.receiving) {
      _progressSub?.cancel();
      state = const ReceiverState();
    }
  }

  void onReceivingStarted() {
    if (state.step != ReceiverStep.openHandDetected) return;
    state = state.copyWith(step: ReceiverStep.receiving, transferProgress: 0.0);
    _progressSub?.cancel();
    _subscribeToProgress();
  }

  void onIncomingConnection(String senderName) {
    state = state.copyWith(senderName: senderName);
  }

  void setTransferMetadata({
    required String senderName,
    required String senderDevice,
    required List<String> fileNames,
    required int fileCount,
    required String totalSize,
  }) {
    state = state.copyWith(
      senderName: senderName,
      senderDevice: senderDevice,
      fileNames: fileNames,
      fileCount: fileCount,
      totalSize: totalSize,
    );
  }

  void completeReceive() {
    _progressSub?.cancel();
    state = state.copyWith(
      step: ReceiverStep.completed,
      transferProgress: 1.0,
      unpackProgress: 1.0,
    );
  }

  void _subscribeToProgress() {
    _progressSub = TransferService.instance.progressStream.listen((progress) {
      if (state.step != ReceiverStep.receiving) return;

      final tp = progress.progress;
      state = state.copyWith(
        transferProgress: tp,
        unpackProgress: tp,
      );

      if (progress.status == 'completed') {
        completeReceive();
      }
    });
  }
}

final receiverProvider =
    StateNotifierProvider<ReceiverNotifier, ReceiverState>((ref) {
  return ReceiverNotifier();
});
