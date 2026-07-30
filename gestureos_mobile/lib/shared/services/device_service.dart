import 'package:gesture_os/core/services/secure_storage_service.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/discovery_service.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  final List<Device> _trustedDevices = [];
  bool _loaded = false;

  List<Device> get trustedDevices => List.unmodifiable(_trustedDevices);

  List<Device> get discoveredDevices =>
      DiscoveryService.instance.discoveredDevices;

  int get trustedCount => _trustedDevices.length;
  bool get hasTrustedDevices => _trustedDevices.isNotEmpty;

  Future<void> loadTrustedDevices() async {
    if (_loaded) return;
    final storage = SecureStorageService.instance;
    final rawList = await storage.getTrustedDevices();
    _trustedDevices.clear();
    for (final json in rawList) {
      _trustedDevices.add(Device.fromJson(json));
    }
    _loaded = true;
  }

  Future<void> _persistTrusted() async {
    final storage = SecureStorageService.instance;
    final jsonList = _trustedDevices.map((d) => d.toJson()).toList();
    await storage.saveTrustedDevices(jsonList);
  }

  bool isTrusted(String deviceId) {
    return _trustedDevices.any((d) => d.id == deviceId);
  }

  Device? getTrusted(String deviceId) {
    try {
      return _trustedDevices.firstWhere((d) => d.id == deviceId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTrusted(Device device) async {
    final existing = _trustedDevices.indexWhere((d) => d.id == device.id);
    if (existing >= 0) {
      _trustedDevices[existing] = device.copyWith(
        isTrusted: true,
        status: DeviceStatus.trusted,
      );
    } else {
      _trustedDevices.add(device.copyWith(
        isTrusted: true,
        status: DeviceStatus.trusted,
      ));
    }
    await _persistTrusted();
  }

  Future<void> removeTrusted(String deviceId) async {
    _trustedDevices.removeWhere((d) => d.id == deviceId);
    await _persistTrusted();
  }

  Future<void> updateTrustedDevice(Device device) async {
    final idx = _trustedDevices.indexWhere((d) => d.id == device.id);
    if (idx >= 0) {
      _trustedDevices[idx] = device;
      await _persistTrusted();
    }
  }

  Device? findDevice(String deviceId) {
    final trusted = getTrusted(deviceId);
    if (trusted != null) return trusted;
    try {
      return discoveredDevices.firstWhere((d) => d.id == deviceId);
    } catch (_) {
      return null;
    }
  }
}
