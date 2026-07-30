import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/services/transfer_service.dart';

enum ReceiverStep {
  idle,
  closedFistDetected,
  waitingForOpenHand,
  unpacking,
  completed,
}

class ReceiverState {
  const ReceiverState({
    this.step = ReceiverStep.idle,
    this.confidence = 0.0,
    this.unpackProgress = 0.0,
    this.senderName = '',
    this.fileNames = const [],
    this.transferProgress = 0.0,
    this.fileCount = 0,
  });

  final ReceiverStep step;
  final double confidence;
  final double unpackProgress;
  final String senderName;
  final List<String> fileNames;
  final double transferProgress;
  final int fileCount;

  bool get isIdle => step == ReceiverStep.idle;
  bool get isClosedFistDetected => step == ReceiverStep.closedFistDetected;
  bool get isWaitingForOpenHand => step == ReceiverStep.waitingForOpenHand;
  bool get isUnpacking => step == ReceiverStep.unpacking;
  bool get isCompleted => step == ReceiverStep.completed;

  ReceiverState copyWith({
    ReceiverStep? step,
    double? confidence,
    double? unpackProgress,
    String? senderName,
    List<String>? fileNames,
    double? transferProgress,
    int? fileCount,
  }) {
    return ReceiverState(
      step: step ?? this.step,
      confidence: confidence ?? this.confidence,
      unpackProgress: unpackProgress ?? this.unpackProgress,
      senderName: senderName ?? this.senderName,
      fileNames: fileNames ?? this.fileNames,
      transferProgress: transferProgress ?? this.transferProgress,
      fileCount: fileCount ?? this.fileCount,
    );
  }
}

class ReceiverNotifier extends StateNotifier<ReceiverState> {
  ReceiverNotifier() : super(const ReceiverState());

  StreamSubscription<TransferProgress>? _progressSub;

  void onClosedFistDetected() {
    if (state.step != ReceiverStep.idle) return;
    state = state.copyWith(
      step: ReceiverStep.closedFistDetected,
      confidence: 0.85,
    );
  }

  void onFistLost() {
    if (state.step == ReceiverStep.closedFistDetected) {
      state = state.copyWith(step: ReceiverStep.waitingForOpenHand);
    }
  }

  void onOpenHandDetected() {
    if (state.step == ReceiverStep.waitingForOpenHand) {
      state = state.copyWith(
        step: ReceiverStep.unpacking,
        unpackProgress: 0.0,
        transferProgress: 0.0,
      );
      _startListening();
    }
  }

  void onHandLost() {
    if (state.step == ReceiverStep.closedFistDetected ||
        state.step == ReceiverStep.waitingForOpenHand) {
      state = state.copyWith(step: ReceiverStep.idle, confidence: 0.0);
    }
  }

  void completeUnpack() {
    if (state.step != ReceiverStep.unpacking) return;
    state = state.copyWith(
      step: ReceiverStep.completed,
      unpackProgress: 1.0,
      transferProgress: 1.0,
    );
  }

  void setTransferMetadata(String sender, List<String> files) {
    state = state.copyWith(
      senderName: sender,
      fileNames: files,
      fileCount: files.length,
    );
  }

  void setTransferProgress(double progress) {
    if (state.step == ReceiverStep.unpacking) {
      state = state.copyWith(transferProgress: progress);
    }
  }

  void onIncomingConnection(String senderName) {
    if (state.step == ReceiverStep.idle ||
        state.step == ReceiverStep.closedFistDetected ||
        state.step == ReceiverStep.waitingForOpenHand) {
      state = state.copyWith(senderName: senderName);
    }
  }

  void _startListening() {
    _progressSub?.cancel();
    _progressSub = TransferService.instance.progressStream.listen((p) {
      if (p.status == 'completed') {
        completeUnpack();
      } else if (p.status == 'failed' || p.error != null) {
        state = state.copyWith(step: ReceiverStep.idle);
      } else {
        state = state.copyWith(
          unpackProgress: p.progress,
          transferProgress: p.progress,
          senderName: p.currentFileName.contains('Receiving from')
              ? p.currentFileName.replaceAll('Receiving from ', '').replaceAll('...', '')
              : state.senderName,
          fileNames: p.currentFileName.isNotEmpty && !p.currentFileName.contains('Receiving from')
              ? [p.currentFileName]
              : state.fileNames,
        );
      }
    });
  }

  void reset() {
    _progressSub?.cancel();
    state = const ReceiverState();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }
}

final receiverProvider =
    StateNotifierProvider<ReceiverNotifier, ReceiverState>((ref) {
  return ReceiverNotifier();
});
