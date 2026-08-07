import 'dart:async';
import 'dart:io';

import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/protocol/frame_parser.dart';
import 'package:gesture_os/shared/protocol/protocol.dart';
import 'package:gesture_os/shared/services/discovery_service.dart';
import 'package:gesture_os/shared/services/network_service.dart';
import 'package:gesture_os/shared/services/settings_service.dart';
import 'package:gesture_os/shared/services/transfer_service.dart';
import 'package:gesture_os/shared/services/trusted_device_manager.dart';

/// Mirrors the desktop [ConnectionPhase] so both apps expose the same
/// synchronized connection lifecycle.
enum ConnectionPhase {
  offline,
  searching,
  connecting,
  connected,
  receiving,
  completed,
}

class ConnectionSnapshot {
  final ConnectionPhase phase;
  final String? deviceName;
  final double transferProgress;
  final int receivedFiles;
  final int transferredBytes;
  final int totalBytes;

  const ConnectionSnapshot({
    this.phase = ConnectionPhase.offline,
    this.deviceName,
    this.transferProgress = 0.0,
    this.receivedFiles = 0,
    this.transferredBytes = 0,
    this.totalBytes = 0,
  });

  ConnectionSnapshot copyWith({
    ConnectionPhase? phase,
    String? deviceName,
    double? transferProgress,
    int? receivedFiles,
    int? transferredBytes,
    int? totalBytes,
  }) {
    return ConnectionSnapshot(
      phase: phase ?? this.phase,
      deviceName: deviceName ?? this.deviceName,
      transferProgress: transferProgress ?? this.transferProgress,
      receivedFiles: receivedFiles ?? this.receivedFiles,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }

  Map<String, dynamic> toJson() => {
        'phase': phase.name,
        'deviceName': deviceName,
        'transferProgress': transferProgress,
        'receivedFiles': receivedFiles,
        'transferredBytes': transferredBytes,
        'totalBytes': totalBytes,
      };

  String get statusText {
    switch (phase) {
      case ConnectionPhase.offline:
        return 'Standby';
      case ConnectionPhase.searching:
        return 'Searching network...';
      case ConnectionPhase.connecting:
        return 'Desktop detected';
      case ConnectionPhase.connected:
        return 'Secure channel established';
      case ConnectionPhase.receiving:
        return 'Receiving files...';
      case ConnectionPhase.completed:
        return 'Transfer complete';
    }
  }
}

class ConnectionManager {
  ConnectionManager._();
  static final ConnectionManager instance = ConnectionManager._();

  final StreamController<ConnectionSnapshot> _stateController =
      StreamController<ConnectionSnapshot>.broadcast();
  StreamSubscription<DiscoveryEvent>? _discoverySub;
  StreamSubscription<TcpConnection>? _incomingSub;
  StreamSubscription<TransferProgress>? _transferSub;
  bool _started = false;
  ConnectionSnapshot _state = const ConnectionSnapshot();
  Timer? _completedTimer;

  Stream<ConnectionSnapshot> get stateStream => _stateController.stream;
  ConnectionSnapshot get currentState => _state;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _discoverySub = DiscoveryService.instance.events.listen(_onDiscoveryEvent);
    _incomingSub = NetworkService.instance.onIncomingConnection.listen(
      _onIncomingConnection,
    );
    _transferSub = TransferService.instance.progressStream.listen(
      _onTransferProgress,
    );

    if (SettingsService.instance.autoDiscover) {
      await DiscoveryService.instance.start();
      _setState(const ConnectionSnapshot(phase: ConnectionPhase.searching));
    } else {
      _setState(const ConnectionSnapshot(phase: ConnectionPhase.offline));
    }

    unawaited(attemptTrustedReconnect());
  }

  void _onDiscoveryEvent(DiscoveryEvent event) {
    if (event.type == 'found') {
      _setState(_state.copyWith(
        phase: ConnectionPhase.connecting,
        deviceName: event.device.name,
      ));
    } else if (event.type == 'lost') {
      if (_state.phase != ConnectionPhase.connected &&
          _state.phase != ConnectionPhase.receiving &&
          _state.phase != ConnectionPhase.completed) {
        _setState(_state.copyWith(
          phase: SettingsService.instance.autoDiscover
              ? ConnectionPhase.searching
              : ConnectionPhase.offline,
          deviceName: null,
        ));
      }
    }
  }

  void _onIncomingConnection(TcpConnection conn) {
    _setState(_state.copyWith(
      phase: ConnectionPhase.connected,
      deviceName: conn.remoteHost,
    ));
    AppLogger.info('[Connection] Incoming connection from ${conn.remoteHost}');

    // Trusted senders are accepted automatically; the receiver UI (open-hand
    // detection) remains the gate for anything else.
    final isTrusted =
        TrustedDeviceManager.instance.isTrustedByAddress(conn.remoteHost);
    if (isTrusted || SettingsService.instance.autoAcceptTrusted) {
      unawaited(TransferService.instance.handleIncomingTransfer(conn));
    }
  }

  void _onTransferProgress(TransferProgress p) {
    switch (p.status) {
      case 'connecting':
        _setState(_state.copyWith(
          phase: ConnectionPhase.connecting,
          transferProgress: p.progress,
          transferredBytes: p.transferredBytes,
          totalBytes: p.totalBytes,
          receivedFiles: p.currentFileIndex,
        ));
      case 'transferring':
        _setState(_state.copyWith(
          phase: ConnectionPhase.receiving,
          transferProgress: p.progress,
          transferredBytes: p.transferredBytes,
          totalBytes: p.totalBytes,
          receivedFiles: p.currentFileIndex,
        ));
      case 'completed':
        _completedTimer?.cancel();
        _setState(_state.copyWith(
          phase: ConnectionPhase.completed,
          transferProgress: 1.0,
          transferredBytes: p.transferredBytes,
          totalBytes: p.totalBytes,
        ));
        _completedTimer = Timer(const Duration(seconds: 6), () {
          _setState(_state.copyWith(
            phase: ConnectionPhase.connected,
            transferProgress: 0.0,
            transferredBytes: 0,
            totalBytes: 0,
            receivedFiles: 0,
          ));
        });
      case 'failed':
      default:
        _setState(_state.copyWith(
          phase: ConnectionPhase.connected,
          transferProgress: 0.0,
        ));
    }
  }

  Future<void> attemptTrustedReconnect() async {
    try {
      await TrustedDeviceManager.instance.load();
      final devices = TrustedDeviceManager.instance.trustedDevices;
      if (devices.isEmpty) return;

      for (final device in devices) {
        if (!_isReconnectable(device)) continue;
        AppLogger.info(
            '[Connection] Trying trusted reconnect: ${device.name} (${device.ip}:${device.port})');
        final ok = await _tryHandshake(device.ip, device.port);
        if (ok) {
          await TrustedDeviceManager.instance.updateLastConnected(device.id);
          _setState(_state.copyWith(
            phase: ConnectionPhase.connected,
            deviceName: device.name,
          ));
          return;
        }
      }
    } catch (e) {
      AppLogger.warning('[Connection] Trusted reconnect failed: $e');
    }
  }

  bool _isReconnectable(Device device) =>
      device.ip.isNotEmpty &&
      device.ip != '0.0.0.0' &&
      device.status == DeviceStatus.trusted;

  Future<bool> _tryHandshake(String host, int port) async {
    final conn = await NetworkService.instance.connect(host, port: port);
    if (conn == null) return false;
    try {
      final parser = FrameParser(conn);
      parser.start();
      parser.sendJson(
          MessageType.hello, DateTime.now().microsecondsSinceEpoch, {
        'device_name': Platform.localHostname,
        'protocol_version': ProtocolConstants.version,
      });
      final reply = await parser.waitForFrame(
        MessageType.hello,
        timeout: const Duration(seconds: 5),
      );
      parser.close();
      if (reply != null) {
        NetworkService.instance.disconnect(conn.id);
        return true;
      }
    } catch (e) {
      AppLogger.warning('[Connection] Handshake error with $host: $e');
    }
    NetworkService.instance.disconnect(conn.id);
    return false;
  }

  void _setState(ConnectionSnapshot snapshot) {
    _state = snapshot;
    if (!_stateController.isClosed) _stateController.add(snapshot);
  }

  /// Applies a `STATE_SYNC` frame received over an active TCP session so both
  /// peers converge on the same visual connection phase.
  void applyRemoteState(Map<String, dynamic>? json) {
    if (json == null) return;
    final remotePhase = _phaseFromName(json['phase'] as String?);
    final remoteName = json['deviceName'] as String?;
    if (remotePhase == null) return;
    final local = _state.phase;
    // An active local session always wins; only mirror peer presence.
    if (local == ConnectionPhase.connecting ||
        local == ConnectionPhase.connected ||
        local == ConnectionPhase.receiving ||
        local == ConnectionPhase.completed) {
      return;
    }
    _setState(_state.copyWith(
      phase: remotePhase,
      deviceName: remoteName ?? _state.deviceName,
    ));
  }

  ConnectionPhase? _phaseFromName(String? name) {
    for (final phase in ConnectionPhase.values) {
      if (phase.name == name) return phase;
    }
    return null;
  }

  void onDiscoveryPreferenceChanged(bool enabled) {
    if (_state.phase == ConnectionPhase.offline ||
        _state.phase == ConnectionPhase.searching) {
      _setState(_state.copyWith(
        phase: enabled ? ConnectionPhase.searching : ConnectionPhase.offline,
        deviceName: null,
      ));
    }
  }

  Future<void> dispose() async {
    await _discoverySub?.cancel();
    await _incomingSub?.cancel();
    await _transferSub?.cancel();
    _completedTimer?.cancel();
    await _stateController.close();
    _started = false;
  }
}
