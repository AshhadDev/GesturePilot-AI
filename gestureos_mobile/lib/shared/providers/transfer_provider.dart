import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/error_recovery_service.dart';
import 'package:gesture_os/shared/services/transfer_history.dart';
import 'package:gesture_os/shared/services/transfer_queue.dart';
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
    this.queueId = '',
    this.isPaused = false,
    this.recoveryMessage = '',
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
  final String queueId;
  final bool isPaused;
  final String recoveryMessage;

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
    String? queueId,
    bool? isPaused,
    String? recoveryMessage,
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
      queueId: queueId ?? this.queueId,
      isPaused: isPaused ?? this.isPaused,
      recoveryMessage: recoveryMessage ?? this.recoveryMessage,
    );
  }
}

class TransferNotifier extends StateNotifier<TransferStateData> {
  TransferNotifier() : super(const TransferStateData());

  StreamSubscription<TransferProgress>? _progressSub;
  StreamSubscription<TransferQueueEvent>? _queueSub;
  int _startTimestamp = 0;
  double _finalSpeed = 0;

  void _listenQueue() {
    _queueSub ??= TransferQueueManager.instance.events.listen((event) {
      if (event.type == 'paused' && event.item.status != TransferQueueItemStatus.transferring) {
        state = state.copyWith(isPaused: true);
      } else if (event.type == 'resumed' || event.type == 'started') {
        state = state.copyWith(isPaused: false);
      } else if (event.type == 'completed') {
        _recordHistory('completed');
        setStatus(TransferState.success);
      } else if (event.type == 'failed') {
        final error = event.item.error ?? 'Transfer failed';
        _analyzeError(error);
        _recordHistory('failed', error: error);
        state = state.copyWith(
          status: TransferState.failed,
          transferError: error,
        );
      }
    });
  }

  void _analyzeError(String error) {
    final action = ErrorRecoveryService.instance.analyzeError(error);
    if (action.type == RecoveryType.retry || action.type == RecoveryType.waitForDevice) {
      state = state.copyWith(recoveryMessage: action.message);
    }
  }

  Future<void> _recordHistory(String status, {String? error}) async {
    final target = state.targetDevice;
    if (target == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final duration = _startTimestamp > 0
          ? DateTime.now().millisecondsSinceEpoch - _startTimestamp
          : 0;
      final totalBytes = state.selectedFiles.fold<int>(0, (s, f) => s + f.sizeBytes);
      final record = TransferRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        senderId: info.id,
        senderName: info.name,
        receiverId: target.id,
        receiverName: target.name,
        fileNames: state.selectedFiles.map((f) => f.name).toList(),
        totalBytes: totalBytes,
        speedBytesPerSec: _finalSpeed,
        durationMs: duration,
        status: status,
        checksum: '',
        errorMessage: error,
      );
      await TransferHistoryService.instance.addRecord(record);
    } catch (_) {}
  }

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

    _startTimestamp = DateTime.now().millisecondsSinceEpoch;
    _finalSpeed = 0;

    state = state.copyWith(
      status: TransferState.transferring,
      transferProgress: 0.0,
      transferSpeed: '',
      remainingTime: '',
      currentFile: '',
      transferredSize: '',
      transferError: '',
      isPaused: false,
      recoveryMessage: '',
    );

    _progressSub?.cancel();
    _progressSub = TransferService.instance.progressStream.listen((p) {
      _finalSpeed = p.speedBytesPerSec;
      state = state.copyWith(
        transferProgress: p.progress,
        currentFile: p.currentFileName,
        transferSpeed: p.speedFormatted,
        remainingTime: p.remainingFormatted,
        transferredSize: p.transferredFormatted,
      );
      if (p.status == 'completed') {
        _recordHistory('completed');
        setStatus(TransferState.success);
      } else if (p.status == 'failed' || p.error != null) {
        final err = p.error ?? 'Transfer failed';
        _analyzeError(err);
        _recordHistory('failed', error: err);
        state = state.copyWith(
          status: TransferState.failed,
          transferError: err,
        );
      }
    });

    _listenQueue();
    TransferQueueManager.instance.enqueue(files: files, targetDevice: target).then((id) {
      state = state.copyWith(queueId: id);
    });
  }

  void pauseTransfer() {
    final qid = state.queueId;
    if (qid.isNotEmpty) {
      TransferQueueManager.instance.pause(qid);
    }
  }

  void resumeTransfer() {
    final qid = state.queueId;
    if (qid.isNotEmpty) {
      TransferQueueManager.instance.resume(qid);
      TransferService.instance.sendFiles(files: state.selectedFiles, target: state.targetDevice!);
    }
  }

  void retryTransfer() {
    final qid = state.queueId;
    if (qid.isNotEmpty) {
      TransferQueueManager.instance.retry(qid);
    }
    state = state.copyWith(status: TransferState.waitingDesktop, recoveryMessage: '');
  }

  void cancelTransfer() {
    final qid = state.queueId;
    if (qid.isNotEmpty) {
      TransferQueueManager.instance.cancel(qid);
    }
    _recordHistory('cancelled');
    _progressSub?.cancel();
    state = const TransferStateData();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _queueSub?.cancel();
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
