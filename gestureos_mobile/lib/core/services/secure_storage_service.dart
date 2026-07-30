import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const String _keyTrustedDevices = 'gestureos_trusted_devices';
  static const String _keyDeviceId = 'gestureos_device_id';

  Future<List<Map<String, dynamic>>> getTrustedDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTrustedDevices);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = utf8.decode(base64.decode(raw));
      final list = json.decode(decoded) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTrustedDevices(List<Map<String, dynamic>> devices) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(devices);
    final raw = base64.encode(utf8.encode(encoded));
    await prefs.setString(_keyTrustedDevices, raw);
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

  String _generateId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final r = DateTime.now().millisecond % 99999;
    return 'gos-${r.toString().padLeft(5, '0')}-$now';
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTrustedDevices);
  }
}
