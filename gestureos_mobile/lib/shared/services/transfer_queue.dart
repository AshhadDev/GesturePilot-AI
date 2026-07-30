import 'dart:async';

import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/models/device_model.dart';

enum TransferQueueItemStatus {
  queued,
  transferring,
  paused,
  completed,
  failed,
  cancelled,
}

class TransferQueueItem {
  final String id;
  final List<AppFile> files;
  final Device targetDevice;
  final DateTime createdAt;
  TransferQueueItemStatus status;
  int progress; // 0-100
  double speed; // bytes/sec
  String? error;
  int retryCount;
  static const int maxRetries = 3;

  TransferQueueItem({
    required this.id,
    required this.files,
    required this.targetDevice,
    DateTime? createdAt,
    this.status = TransferQueueItemStatus.queued,
    this.progress = 0,
    this.speed = 0,
    this.error,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get canRetry =>
      (status == TransferQueueItemStatus.failed ||
          status == TransferQueueItemStatus.cancelled) &&
      retryCount < maxRetries;

  bool get isActive => status == TransferQueueItemStatus.transferring;

  String get label => files.length == 1
      ? files.first.name
      : '${files.length} files';
}

class TransferQueueEvent {
  final TransferQueueItem item;
  final String type;
  const TransferQueueEvent({required this.item, required this.type});
}

class TransferQueueManager {
  TransferQueueManager._();
  static final TransferQueueManager instance = TransferQueueManager._();

  final List<TransferQueueItem> _queue = [];
  TransferQueueItem? _currentTransfer;
  bool _parallelMode = false;
  int _maxParallel = 2;
  bool _isProcessing = false;

  final StreamController<TransferQueueEvent> _eventController =
      StreamController<TransferQueueEvent>.broadcast();

  Stream<TransferQueueEvent> get events => _eventController.stream;
  List<TransferQueueItem> get queue =>
      List.unmodifiable(_queue.where((i) => i.status != TransferQueueItemStatus.completed));
  List<TransferQueueItem> get history =>
      _queue.where((i) =>
          i.status == TransferQueueItemStatus.completed ||
          i.status == TransferQueueItemStatus.cancelled).toList();
  TransferQueueItem? get currentTransfer => _currentTransfer;

  bool get parallelMode => _parallelMode;
  int get maxParallel => _maxParallel;

  void setParallelMode(bool parallel, {int max = 2}) {
    _parallelMode = parallel;
    _maxParallel = max;
  }

  Future<String> enqueue({
    required List<AppFile> files,
    required Device targetDevice,
  }) async {
    final id = 'tx-${DateTime.now().microsecondsSinceEpoch}';
    final item = TransferQueueItem(
      id: id,
      files: files,
      targetDevice: targetDevice,
    );
    _queue.add(item);
    _emit(item, 'enqueued');
    _processQueue();
    return id;
  }

  void remove(String id) {
    _queue.removeWhere((i) => i.id == id);
    final item = _queue.firstWhere(
      (i) => i.id == id,
      orElse: () => TransferQueueItem(
        id: id, files: [], targetDevice: Device(id: '', name: '', ip: '', platform: DevicePlatform.unknown, lastSeen: DateTime.now()),
      ),
    );
    _emit(item, 'removed');
  }

  void pause(String id) {
    final item = _find(id);
    if (item != null && item.isActive) {
      item.status = TransferQueueItemStatus.paused;
      _emit(item, 'paused');
      if (_currentTransfer?.id == id) _currentTransfer = null;
      _processQueue();
    }
  }

  void resume(String id) {
    final item = _find(id);
    if (item != null && item.status == TransferQueueItemStatus.paused) {
      item.status = TransferQueueItemStatus.queued;
      _emit(item, 'resumed');
      _processQueue();
    }
  }

  void retry(String id) {
    final item = _find(id);
    if (item != null && item.canRetry) {
      item.status = TransferQueueItemStatus.queued;
      item.error = null;
      item.progress = 0;
      item.retryCount++;
      _emit(item, 'retrying');
      _processQueue();
    }
  }

  void cancel(String id) {
    final item = _find(id);
    if (item != null) {
      item.status = TransferQueueItemStatus.cancelled;
      _emit(item, 'cancelled');
      if (_currentTransfer?.id == id) _currentTransfer = null;
      _processQueue();
    }
  }

  void moveUp(String id) {
    final idx = _queue.indexWhere((i) => i.id == id);
    if (idx > 0) {
      final item = _queue.removeAt(idx);
      _queue.insert(idx - 1, item);
      _emit(item, 'reordered');
    }
  }

  void moveDown(String id) {
    final idx = _queue.indexWhere((i) => i.id == id);
    if (idx < _queue.length - 1) {
      final item = _queue.removeAt(idx);
      _queue.insert(idx + 1, item);
      _emit(item, 'reordered');
    }
  }

  void markProgress(String id, int progress, double speed) {
    final item = _find(id);
    if (item != null) {
      item.progress = progress;
      item.speed = speed;
    }
  }

  void markCompleted(String id) {
    final item = _find(id);
    if (item != null) {
      item.status = TransferQueueItemStatus.completed;
      item.progress = 100;
      _emit(item, 'completed');
      if (_currentTransfer?.id == id) _currentTransfer = null;
      _processQueue();
    }
  }

  void markFailed(String id, String error) {
    final item = _find(id);
    if (item != null) {
      item.status = TransferQueueItemStatus.failed;
      item.error = error;
      _emit(item, 'failed');
      if (_currentTransfer?.id == id) _currentTransfer = null;
      _processQueue();
    }
  }

  void _processQueue() {
    if (_isProcessing) return;
    _isProcessing = true;

    if (_parallelMode) {
      // Start up to maxParallel items
      final active = _queue.where((i) => i.isActive).length;
      final slots = _maxParallel - active;
      if (slots > 0) {
        final next = _queue
            .where((i) =>
                i.status == TransferQueueItemStatus.queued)
            .take(slots)
            .toList();
        for (final item in next) {
          _startTransfer(item);
        }
      }
    } else {
      // Sequential mode
      if (_currentTransfer != null && _currentTransfer!.isActive) {
        _isProcessing = false;
        return;
      }
      final next = _queue.where(
          (i) => i.status == TransferQueueItemStatus.queued);
      if (next.isNotEmpty) {
        _startTransfer(next.first);
      }
    }
    _isProcessing = false;
  }

  void _startTransfer(TransferQueueItem item) {
    item.status = TransferQueueItemStatus.transferring;
    _currentTransfer = item;
    _emit(item, 'started');
    AppLogger.info('Transfer started: ${item.label} -> ${item.targetDevice.name}');
  }

  TransferQueueItem? _find(String id) {
    try {
      return _queue.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  void _emit(TransferQueueItem item, String type) {
    _eventController.add(TransferQueueEvent(item: item, type: type));
  }

  void dispose() {
    _eventController.close();
  }
}
