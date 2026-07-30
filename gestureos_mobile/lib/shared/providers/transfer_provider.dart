import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/transfer_service.dart';

enum TransferState {
  idle,
  fileSelection,
  magicTransfer,
  carrying,
  waitingDesktop,
  transferring,
  success,
  failed,
}

class TransferStateData {
  const TransferStateData({
    this.status = TransferState.idle,
    this.selectedFiles = const [],
    this.progress = 0.0,
    this.transferSpeed = '',
    this.remainingTime = '',
    this.orbPhase = 0,
    this.targetDevice,
    this.currentFile = '',
    this.transferredSize = '',
    this.transferError = '',
    this.transferProgress = 0.0,
  });

  final TransferState status;
  final List<AppFile> selectedFiles;
  final double progress;
  final String transferSpeed;
  final String remainingTime;
  final int orbPhase;
  final Device? targetDevice;
  final String currentFile;
  final String transferredSize;
  final String transferError;
  final double transferProgress;

  int get selectedCount => selectedFiles.length;

  String get totalSizeFormatted {
    final totalBytes = selectedFiles.fold<int>(0, (s, f) => s + f.sizeBytes);
    if (totalBytes < 1048576) return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    if (totalBytes < 1073741824) {
      return '${(totalBytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / 1073741824).toStringAsFixed(1)} GB';
  }

  TransferStateData copyWith({
    TransferState? status,
    List<AppFile>? selectedFiles,
    double? progress,
    String? transferSpeed,
    String? remainingTime,
    int? orbPhase,
    Device? targetDevice,
    String? currentFile,
    String? transferredSize,
    String? transferError,
    double? transferProgress,
  }) {
    return TransferStateData(
      status: status ?? this.status,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      progress: progress ?? this.progress,
      transferSpeed: transferSpeed ?? this.transferSpeed,
      remainingTime: remainingTime ?? this.remainingTime,
      orbPhase: orbPhase ?? this.orbPhase,
      targetDevice: targetDevice ?? this.targetDevice,
      currentFile: currentFile ?? this.currentFile,
      transferredSize: transferredSize ?? this.transferredSize,
      transferError: transferError ?? this.transferError,
      transferProgress: transferProgress ?? this.transferProgress,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferStateData> {
  TransferNotifier() : super(const TransferStateData());

  StreamSubscription<TransferProgress>? _progressSub;

  void setFiles(List<AppFile> files) {
    state = state.copyWith(selectedFiles: files);
  }

  void toggleFile(AppFile file) {
    final current = state.selectedFiles.toList();
    final index = current.indexWhere((f) => f.path == file.path);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.add(file);
    }
    state = state.copyWith(selectedFiles: current);
  }

  void setStatus(TransferState newStatus) {
    state = state.copyWith(status: newStatus);
  }

  void updateProgress(double value) {
    state = state.copyWith(progress: value);
  }

  void setTransferInfo({required String speed, required String remaining}) {
    state = state.copyWith(transferSpeed: speed, remainingTime: remaining);
  }

  void advanceOrbPhase() {
    state = state.copyWith(orbPhase: state.orbPhase + 1);
  }

  void setTargetDevice(Device device) {
    state = state.copyWith(targetDevice: device);
  }

  void startTransfer() {
    final target = state.targetDevice;
    final files = state.selectedFiles;
    if (target == null || files.isEmpty) return;

    state = state.copyWith(
      status: TransferState.transferring,
      transferProgress: 0.0,
      transferSpeed: '',
      remainingTime: '',
      currentFile: '',
      transferredSize: '',
      transferError: '',
    );

    _progressSub?.cancel();
    _progressSub = TransferService.instance.progressStream.listen((p) {
      state = state.copyWith(
        transferProgress: p.progress,
        currentFile: p.currentFileName,
        transferSpeed: p.speedFormatted,
        remainingTime: p.remainingFormatted,
        transferredSize: p.transferredFormatted,
      );
      if (p.status == 'completed') {
        setStatus(TransferState.success);
      } else if (p.status == 'failed' || p.error != null) {
        state = state.copyWith(
          status: TransferState.failed,
          transferError: p.error ?? 'Transfer failed',
        );
      }
    });

    TransferService.instance.sendFiles(files: files, target: target);
  }

  void retryTransfer() {
    state = state.copyWith(status: TransferState.waitingDesktop);
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  void reset() {
    _progressSub?.cancel();
    state = const TransferStateData();
  }
}

final transferProvider =
    StateNotifierProvider<TransferNotifier, TransferStateData>((ref) {
  return TransferNotifier();
});
