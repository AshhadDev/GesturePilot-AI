import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/network_service.dart';

class DiscoveryEvent {
  final Device device;
  final String type;
  const DiscoveryEvent({required this.device, required this.type});
}

class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  static const int _discoveryPort = 48771;
  static const Duration _broadcastInterval = Duration(seconds: 2);
  static const Duration _heartbeatInterval = Duration(seconds: 3);
  static const Duration _deviceTimeout = Duration(seconds: 10);

  RawDatagramSocket? _socket;
  bool _isRunning = false;
  Timer? _broadcastTimer;
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  final Map<String, Device> _discoveredDevices = {};
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, double> _signalStrengths = {};
  final Map<String, int> _batteryLevels = {};
  final StreamController<DiscoveryEvent> _eventController =
      StreamController<DiscoveryEvent>.broadcast();
  String? _localDeviceId;
  int _batteryLevel = -1;

  Stream<DiscoveryEvent> get events => _eventController.stream;
  List<Device> get discoveredDevices {
    final sorted = _discoveredDevices.values.toList()
      ..sort((a, b) {
        // Trusted first, then by signal strength
        if (a.isTrusted && !b.isTrusted) return -1;
        if (!a.isTrusted && b.isTrusted) return 1;
        return b.signalStrength.compareTo(a.signalStrength);
      });
    return sorted;
  }
  bool get isRunning => _isRunning;

  void updateBatteryLevel(int level) {
    _batteryLevel = level;
  }

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      final info = await DeviceInfoService.instance.getInfo();
      _localDeviceId = info.id;

      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );
      _socket!.broadcastEnabled = true;
      _socket!.listen(_onPacket);

      _broadcastTimer = Timer.periodic(_broadcastInterval, (_) => _broadcastDiscovery());
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _sendHeartbeat());
      _cleanupTimer = Timer.periodic(_heartbeatInterval, (_) => _cleanupStaleDevices());

      _broadcastDiscovery();
      AppLogger.info('DiscoveryService started on port $_discoveryPort');
    } catch (e) {
      AppLogger.warning('DiscoveryService failed to start: $e');
      _isRunning = false;
    }
  }

  Future<void> stop() async {
    _isRunning = false;
    _broadcastTimer?.cancel();
    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;
    _discoveredDevices.clear();
    _lastSeen.clear();
    _signalStrengths.clear();
    _batteryLevels.clear();
    AppLogger.info('DiscoveryService stopped');
  }

  void _onPacket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    final msg = utf8.decode(datagram.data);
    final parts = msg.split('|');
    if (parts.length < 3) return;

    final cmd = parts[0];
    final deviceId = parts[1];
    final deviceName = parts[2];

    if (deviceId == _localDeviceId) return;

    DevicePlatform platform = DevicePlatform.unknown;
    String deviceIp = datagram.address.address;
    int port = _discoveryPort;
    int batteryLevel = -1;

    if (parts.length >= 4) {
      platform = _parsePlatform(int.tryParse(parts[3]) ?? 6);
    }
    if (parts.length >= 5) {
      deviceIp = parts[4];
    }
    if (parts.length >= 6) {
      port = int.tryParse(parts[5]) ?? _discoveryPort;
    }
    if (parts.length >= 7) {
      batteryLevel = int.tryParse(parts[6]) ?? -1;
    }

    _lastSeen[deviceId] = DateTime.now();

    // Estimate signal strength from round-trip timing
    final signalStrength = _estimateSignalStrength(datagram);

    switch (cmd) {
      case 'GESTUREOS_DISCOVERY_REQ':
        _respondDiscovery(datagram.address, datagram.port);
        _updateOrAddDevice(
          deviceId, deviceName, deviceIp, port, platform,
          signalStrength, batteryLevel,
        );
        break;
      case 'GESTUREOS_DISCOVERY_RESP':
        _updateOrAddDevice(
          deviceId, deviceName, deviceIp, port, platform,
          signalStrength, batteryLevel,
        );
        break;
      case 'GESTUREOS_HEARTBEAT':
        _updateOrAddDevice(
          deviceId, deviceName, deviceIp, port, platform,
          signalStrength, batteryLevel,
        );
        break;
    }
  }

  int _estimateSignalStrength(Datagram datagram) {
    // Estimate based on time since last packet from this device
    final key = datagram.address.address;
    final last = _lastSeen[key];
    if (last == null) return 80;

    final msSince = DateTime.now().difference(last).inMilliseconds;
    if (msSince < 500) return 95;
    if (msSince < 1000) return 85;
    if (msSince < 2000) return 70;
    if (msSince < 3000) return 55;
    return 40;
  }

  void _updateOrAddDevice(
    String id, String name, String ip, int port,
    DevicePlatform platform, int signalStrength, int batteryLevel,
  ) {
    final now = DateTime.now();

    // Blend signal strength with moving average
    final prevSignal = _signalStrengths[id] ?? 50.0;
    final blended = (prevSignal * 0.4 + signalStrength * 0.6).round();
    _signalStrengths[id] = blended.toDouble();

    if (batteryLevel >= 0) {
      _batteryLevels[id] = batteryLevel;
    }

    final existing = _discoveredDevices[id];
    if (existing != null) {
      final updated = existing.copyWith(
        name: name,
        ip: ip,
        port: port,
        platform: platform,
        lastSeen: now,
        signalStrength: blended.clamp(0, 100),
        status: DeviceStatus.online,
      );
      _discoveredDevices[id] = updated;
      _eventController.add(DiscoveryEvent(device: updated, type: 'updated'));
    } else {
      final device = Device(
        id: id,
        name: name,
        ip: ip,
        port: port,
        platform: platform,
        lastSeen: now,
        signalStrength: blended.clamp(0, 100),
        status: DeviceStatus.online,
      );
      _discoveredDevices[id] = device;
      _eventController.add(DiscoveryEvent(device: device, type: 'found'));
    }
  }

  /// Called after device name change to immediately re-broadcast.
  Future<void> notifyNameChange(String newName) async {
    try {
      final info = await DeviceInfoService.instance.getInfo();
      _localDeviceId = info.id;
    } catch (_) {}
    _broadcastDiscovery();
  }

  /// Returns the latest battery level for a discovered device.
  int getBatteryLevel(String deviceId) => _batteryLevels[deviceId] ?? -1;

  void _respondDiscovery(InternetAddress addr, int port) async {
    if (_socket == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final msg = 'GESTUREOS_DISCOVERY_RESP|${info.id}|${info.name}|'
          '${info.platform.index}|${info.ip}|${NetworkService.instance.dataPort}|$_batteryLevel';
      _socket!.send(utf8.encode(msg), addr, port);
    } catch (_) {}
  }

  void _broadcastDiscovery() async {
    if (_socket == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final msg = 'GESTUREOS_DISCOVERY_REQ|${info.id}|${info.name}|'
          '${info.platform.index}|${info.ip}|${NetworkService.instance.dataPort}|$_batteryLevel';
      _socket!.send(
        utf8.encode(msg),
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );
    } catch (_) {}
  }

  void _sendHeartbeat() async {
    if (_socket == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final msg = 'GESTUREOS_HEARTBEAT|${info.id}|${info.name}|'
          '${info.platform.index}|${info.ip}|${NetworkService.instance.dataPort}|$_batteryLevel';
      _socket!.send(
        utf8.encode(msg),
        InternetAddress('255.255.255.255'),
        _discoveryPort,
      );
    } catch (_) {}
  }

  void _cleanupStaleDevices() {
    final now = DateTime.now();
    final toRemove = <String>[];
    for (final entry in _discoveredDevices.entries) {
      if (now.difference(entry.value.lastSeen) > _deviceTimeout) {
        toRemove.add(entry.key);
        final lost = entry.value.copyWith(
          status: DeviceStatus.offline,
          lastSeen: now,
        );
        _eventController.add(DiscoveryEvent(device: lost, type: 'lost'));
      }
    }
    for (final id in toRemove) {
      _discoveredDevices.remove(id);
      _lastSeen.remove(id);
      _signalStrengths.remove(id);
      _batteryLevels.remove(id);
    }
  }

  DevicePlatform _parsePlatform(int index) {
    if (index >= 0 && index < DevicePlatform.values.length) {
      return DevicePlatform.values[index];
    }
    return DevicePlatform.unknown;
  }
}
