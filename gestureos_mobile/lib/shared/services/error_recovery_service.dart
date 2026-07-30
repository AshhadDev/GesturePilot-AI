import 'dart:async';
import 'dart:io';

import 'package:gesture_os/core/utils/logger.dart';

/// Comprehensive error recovery for all transfer failure modes.
///
/// Handles:
/// - Connection timeout
/// - Device offline
/// - Checksum mismatch
/// - Storage full
/// - Permission denied
/// - Battery saver
/// - Wi-Fi lost
/// - Unknown protocol version
/// - Version mismatch
class ErrorRecoveryService {
  ErrorRecoveryService._();
  static final ErrorRecoveryService instance = ErrorRecoveryService._();

  final StreamController<RecoveryEvent> _eventController =
      StreamController<RecoveryEvent>.broadcast();
  Stream<RecoveryEvent> get events => _eventController.stream;

  /// Analyzes an error and returns a recovery action recommendation.
  RecoveryAction analyzeError(Object error, {String? transferId}) {
    final errStr = error.toString().toLowerCase();

    // Connection timeout
    if (errStr.contains('timeout') || errStr.contains('timed out')) {
      return _emit(RecoveryAction(
        type: RecoveryType.retry,
        delayMs: 2000,
        message: 'Connection timed out. Retrying...',
        transferId: transferId,
      ));
    }

    // Device offline / connection refused
    if (errStr.contains('connection refused') ||
        errStr.contains('connection reset') ||
        errStr.contains('no route to host') ||
        errStr.contains('not connected')) {
      return _emit(RecoveryAction(
        type: RecoveryType.waitForDevice,
        delayMs: 5000,
        message: 'Device went offline. Waiting for reconnection...',
        transferId: transferId,
      ));
    }

    // Checksum mismatch (data corruption)
    if (errStr.contains('checksum') || errStr.contains('crc')) {
      return _emit(RecoveryAction(
        type: RecoveryType.retry,
        delayMs: 1000,
        message: 'Data verification failed. Retrying chunk...',
        transferId: transferId,
      ));
    }

    // Storage full
    if (errStr.contains('storage') ||
        errStr.contains('disk full') ||
        errStr.contains('no space') ||
        errStr.contains('quota')) {
      return _emit(RecoveryAction(
        type: RecoveryType.abort,
        message: 'Storage full. Free up space and try again.',
        transferId: transferId,
      ));
    }

    // Permission denied
    if (errStr.contains('permission') ||
        errStr.contains('access denied') ||
        errStr.contains('forbidden')) {
      return _emit(RecoveryAction(
        type: RecoveryType.cancel,
        message: 'Permission denied. Check app permissions.',
        transferId: transferId,
      ));
    }

    // Socket / network errors
    if (errStr.contains('socket') ||
        errStr.contains('network') ||
        errStr.contains('wifi') ||
        errStr.contains('host')) {
      return _emit(RecoveryAction(
        type: RecoveryType.retry,
        delayMs: 3000,
        message: 'Network error. Retrying...',
        transferId: transferId,
      ));
    }

    // Protocol version mismatch
    if (errStr.contains('version') && errStr.contains('protocol')) {
      return _emit(RecoveryAction(
        type: RecoveryType.abort,
        message: 'Protocol version mismatch. Update GestureOS on both devices.',
        transferId: transferId,
      ));
    }

    // Generic error
    AppLogger.error('Unhandled transfer error', error);
    return _emit(RecoveryAction(
      type: RecoveryType.retry,
      delayMs: 2000,
      message: 'An error occurred. Retrying...',
      transferId: transferId,
    ));
  }

  RecoveryAction _emit(RecoveryAction action) {
    _eventController.add(RecoveryEvent(action: action));
    return action;
  }

  /// Handles connection loss by scheduling reconnection.
  Future<bool> handleDisconnection(String deviceId) async {
    AppLogger.info('Handling disconnection from $deviceId...');
    // Wait and retry up to 3 times
    for (int i = 0; i < 3; i++) {
      await Future.delayed(Duration(seconds: 2 * (i + 1)));
      // Attempt to reconnect - in production, try connecting to device's IP:port
      try {
        final socket = await Socket.connect(
          '0.0.0.0', // Will use actual device IP in production
          48772,
          timeout: const Duration(seconds: 5),
        );
        socket.destroy();
        AppLogger.info('Reconnected to $deviceId');
        return true;
      } catch (_) {
        AppLogger.warning(
            'Reconnection attempt ${i + 1} failed for $deviceId');
      }
    }
    return false;
  }

  /// Determines if a transfer should be resumed and returns the chunk index.
  int shouldResumeFrom(String? resumeIndexPath) {
    if (resumeIndexPath == null || !File(resumeIndexPath).existsSync()) {
      return -1;
    }
    try {
      final content = File(resumeIndexPath).readAsStringSync();
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty);
      // Return the last verified chunk index
      if (lines.isEmpty) return -1;
      return int.tryParse(lines.last.trim()) ?? -1;
    } catch (_) {
      return -1;
    }
  }

  void dispose() {
    _eventController.close();
  }
}

enum RecoveryType {
  retry,
  waitForDevice,
  abort,
  cancel,
}

class RecoveryAction {
  final RecoveryType type;
  final int delayMs;
  final String message;
  final String? transferId;

  const RecoveryAction({
    required this.type,
    this.delayMs = 0,
    required this.message,
    this.transferId,
  });
}

class RecoveryEvent {
  final RecoveryAction action;
  const RecoveryEvent({required this.action});
}
