import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/device_model.dart';

class DiscoveryEvent {
  final Device device;
  final String type;
  const DiscoveryEvent({required this.device, required this.type});
}

class DiscoveryService {
  DiscoveryService._();
  static final DiscoveryService instance = DiscoveryService._();

  static const int _discoveryPort = 48771;
  static const Duration _broadcastInterval = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 10);
  static const Duration _deviceTimeout = Duration(seconds: 30);

  RawDatagramSocket? _socket;
  bool _isRunning = false;
  Timer? _broadcastTimer;
  Timer? _cleanupTimer;
  final Map<String, Device> _discoveredDevices = {};
  final Map<String, DateTime> _lastHeartbeat = {};
  final StreamController<DiscoveryEvent> _eventController =
      StreamController<DiscoveryEvent>.broadcast();
  String? _localDeviceId;

  Stream<DiscoveryEvent> get events => _eventController.stream;
  List<Device> get discoveredDevices => _discoveredDevices.values.toList();
  bool get isRunning => _isRunning;

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
    _cleanupTimer?.cancel();
    _socket?.close();
    _socket = null;
    _discoveredDevices.clear();
    _lastHeartbeat.clear();
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

    if (parts.length >= 4) {
      platform = _parsePlatform(int.tryParse(parts[3]) ?? 6);
    }
    if (parts.length >= 5) {
      deviceIp = parts[4];
    }
    if (parts.length >= 6) {
      port = int.tryParse(parts[5]) ?? _discoveryPort;
    }

    switch (cmd) {
      case 'GESTUREOS_DISCOVERY_REQ':
        _respondDiscovery(datagram.address, datagram.port);
        _updateOrAddDevice(deviceId, deviceName, deviceIp, port, platform);
        break;
      case 'GESTUREOS_DISCOVERY_RESP':
        _updateOrAddDevice(deviceId, deviceName, deviceIp, port, platform);
        break;
      case 'GESTUREOS_HEARTBEAT':
        _lastHeartbeat[deviceId] = DateTime.now();
        _updateOrAddDevice(deviceId, deviceName, deviceIp, port, platform);
        break;
    }
  }

  void _updateOrAddDevice(
      String id, String name, String ip, int port, DevicePlatform platform) {
    final now = DateTime.now();
    final existing = _discoveredDevices[id];
    if (existing != null) {
      final updated = existing.copyWith(
        name: name,
        ip: ip,
        port: port,
        platform: platform,
        lastSeen: now,
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
        status: DeviceStatus.online,
      );
      _discoveredDevices[id] = device;
      _eventController.add(DiscoveryEvent(device: device, type: 'found'));
    }
  }

  void _respondDiscovery(InternetAddress addr, int port) async {
    if (_socket == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final msg = 'GESTUREOS_DISCOVERY_RESP|${info.id}|${info.name}|'
          '${info.platform.index}|${info.ip}|$_discoveryPort';
      _socket!.send(utf8.encode(msg), addr, port);
    } catch (_) {}
  }

  void _broadcastDiscovery() async {
    if (_socket == null) return;
    try {
      final info = await DeviceInfoService.instance.getInfo();
      final msg = 'GESTUREOS_DISCOVERY_REQ|${info.id}|${info.name}|'
          '${info.platform.index}';
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
      _lastHeartbeat.remove(id);
    }
  }

  DevicePlatform _parsePlatform(int index) {
    if (index >= 0 && index < DevicePlatform.values.length) {
      return DevicePlatform.values[index];
    }
    return DevicePlatform.unknown;
  }
}
