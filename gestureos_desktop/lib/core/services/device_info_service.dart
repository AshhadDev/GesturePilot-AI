import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestureos_desktop/shared/models/device_model.dart';

class LocalDeviceInfo {
  final String id;
  final String name;
  final String ip;
  final DevicePlatform platform;

  const LocalDeviceInfo({
    required this.id,
    required this.name,
    required this.ip,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ip': ip,
    'platform': platform.index,
  };
}

DevicePlatform _detectPlatform() {
  return DevicePlatform.windows;
}

class DeviceInfoService {
  DeviceInfoService._();
  static final DeviceInfoService instance = DeviceInfoService._();

  LocalDeviceInfo? _cached;

  static const String _keyDeviceId = 'gestureos_device_id';
  static const String _keyDeviceName = 'gestureos_device_name';

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = (now % 99999).toString().padLeft(5, '0');
    return 'gos-${_detectPlatform().name[0]}-$r';
  }

  String _defaultName() {
    try {
      return Platform.localHostname;
    } catch (_) {
      return 'GestureOS ${_detectPlatform().name}';
    }
  }

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = _generateId();
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    var name = prefs.getString(_keyDeviceName);
    if (name == null || name.isEmpty) {
      name = _defaultName();
      await prefs.setString(_keyDeviceName, name);
    }
    return name;
  }

  Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceName, name);
    _cached = null;
  }

  Future<LocalDeviceInfo> getInfo() async {
    if (_cached != null) return _cached!;
    final id = await getDeviceId();
    final name = await getDeviceName();
    final ip = await _resolveIp();
    final platform = _detectPlatform();
    _cached = LocalDeviceInfo(id: id, name: name, ip: ip, platform: platform);
    return _cached!;
  }

  Future<String> _resolveIp() async {
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && addr.address.startsWith('192.') || addr.address.startsWith('10.') || addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }
}
