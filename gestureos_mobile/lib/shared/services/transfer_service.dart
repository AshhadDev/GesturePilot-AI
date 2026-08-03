import 'dart:async';
import 'dart:io';

import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/services/file_manager.dart';
import 'package:gesture_os/shared/services/network_service.dart';
import 'package:gesture_os/shared/services/transfer_receiver.dart';
import 'package:gesture_os/shared/services/transfer_sender.dart';

class TransferProgress {
  final double progress;
  final String currentFileName;
  final int currentFileIndex;
  final int totalFiles;
  final int transferredBytes;
  final int totalBytes;
  final double speedBytesPerSec;
  final int remainingSeconds;
  final String status;
  final String? error;
  final int currentChunk;
  final int totalChunks;

  const TransferProgress({
    this.progress = 0.0,
    this.currentFileName = '',
    this.currentFileIndex = 0,
    this.totalFiles = 1,
    this.transferredBytes = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.remainingSeconds = 0,
    this.status = 'connecting',
    this.error,
    this.currentChunk = 0,
    this.totalChunks = 1,
  });

  String get speedFormatted {
    if (speedBytesPerSec >= 1073741824) {
      return '${(speedBytesPerSec / 1073741824).toStringAsFixed(1)} GB/s';
    }
    if (speedBytesPerSec >= 1048576) {
      return '${(speedBytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
    }
    if (speedBytesPerSec >= 1024) {
      return '${(speedBytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${speedBytesPerSec.toStringAsFixed(0)} B/s';
  }

  String get remainingFormatted {
    if (remainingSeconds <= 0) return 'Calculating...';
    if (remainingSeconds < 60) return '${remainingSeconds}s';
    if (remainingSeconds < 3600) {
      return '${remainingSeconds ~/ 60}m ${remainingSeconds % 60}s';
    }
    return '${remainingSeconds ~/ 3600}h ${(remainingSeconds % 3600) ~/ 60}m';
  }

  String get transferredFormatted {
    if (totalBytes >= 1073741824) {
      return '${(transferredBytes / 1073741824).toStringAsFixed(1)} / ${(totalBytes / 1073741824).toStringAsFixed(1)} GB';
    }
    if (totalBytes >= 1048576) {
      return '${(transferredBytes / 1048576).toStringAsFixed(1)} / ${(totalBytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(transferredBytes / 1024).toStringAsFixed(0)} / ${(totalBytes / 1024).toStringAsFixed(0)} KB';
  }
}

class TransferService {
  TransferService._();
  static final TransferService instance = TransferService._();

  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();
  final TransferSender _sender = TransferSender();
  bool _isTransferring = false;
  int _startTimestamp = 0;

  Stream<TransferProgress> get progressStream => _progressController.stream;
  bool get isTransferring => _isTransferring;

  Future<bool> sendFiles({
    required List<AppFile> files,
    required Device target,
  }) async {
    if (_isTransferring) return false;
    _isTransferring = true;
    _startTimestamp = DateTime.now().microsecondsSinceEpoch;

    final result = await _sender.sendFiles(
      files: files,
      target: target,
      onProgress: _forwardProgress,
    );

    _isTransferring = false;
    return result.success;
  }

  void cancelCurrentTransfer() {
    _sender.cancel();
    _emitProgress(status: 'failed', error: 'Cancelled');
    _isTransferring = false;
  }

  Future<void> handleIncomingTransfer(TcpConnection conn) async {
    if (_isTransferring) return;
    _isTransferring = true;
    _startTimestamp = DateTime.now().microsecondsSinceEpoch;

    final receiver = TransferReceiver();
    final sub = receiver.progressStream.listen((p) {
      _forwardProgress(p);
    });

    try {
      await receiver.handleConnection(conn);
      // Auto-open received files on completion
      await _autoOpenReceivedFiles();
    } finally {
      await sub.cancel();
      _isTransferring = false;
    }
  }

  Future<void> _autoOpenReceivedFiles() async {
    try {
      final baseDir = FileManager.instance.baseDirectory;
      if (!await baseDir.exists()) return;

      final files = <File>[];
      await for (final entity in baseDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }

      // Open the first file as a representative
      if (files.isEmpty) return;
      final file = files.first;
      final path = file.path;

      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      } else if (Platform.isAndroid) {
        _openOnAndroid(path);
      }
    } catch (e) {
      AppLogger.warning('[AutoOpen] Failed: $e');
    }
  }

  void _openOnAndroid(String path) {
    // Platform channel to open file with Android Intent.
    // In production, use MethodChannel to invoke ACTION_VIEW with
    // FileProvider URI. Stub for now.
    AppLogger.info('[AutoOpen] Android open pending for: $path');
  }

  void _forwardProgress(TransferProgress p) {
    final elapsed = DateTime.now().microsecondsSinceEpoch - _startTimestamp;
    final elapsedSec = elapsed / 1000000;
    final speed = elapsedSec > 0 ? p.transferredBytes / elapsedSec : 0.0;
    final remaining = speed > 0
        ? ((p.totalBytes - p.transferredBytes) / speed).round()
        : 0;

    _progressController.add(TransferProgress(
      progress: p.progress,
      currentFileName: p.currentFileName,
      currentFileIndex: p.currentFileIndex,
      totalFiles: p.totalFiles,
      transferredBytes: p.transferredBytes,
      totalBytes: p.totalBytes,
      speedBytesPerSec: speed,
      remainingSeconds: remaining,
      status: p.status,
      error: p.error,
      currentChunk: p.currentChunk,
      totalChunks: p.totalChunks,
    ));
  }

  void _emitProgress({
    double? progress,
    String currentFileName = '',
    int currentFileIndex = 0,
    int totalFiles = 1,
    int? transferredBytes,
    int? totalBytes,
    String status = 'transferring',
    String? error,
  }) {
    final elapsed = DateTime.now().microsecondsSinceEpoch - _startTimestamp;
    final elapsedSec = elapsed / 1000000;
    final tb = transferredBytes ?? 0;
    final tt = totalBytes ?? 0;
    final speed = elapsedSec > 0 ? tb / elapsedSec : 0.0;
    final remaining = speed > 0 ? ((tt - tb) / speed).round() : 0;
    final prog = progress ?? (tt > 0 ? tb / tt : 0.0);

    _progressController.add(TransferProgress(
      progress: prog.clamp(0.0, 1.0),
      currentFileName: currentFileName,
      currentFileIndex: currentFileIndex,
      totalFiles: totalFiles,
      transferredBytes: tb,
      totalBytes: tt,
      speedBytesPerSec: speed,
      remainingSeconds: remaining,
      status: status,
      error: error,
    ));
  }
}
