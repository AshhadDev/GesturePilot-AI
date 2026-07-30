import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gesture_os/shared/models/device_model.dart';

class _TrustedDeviceRecord {
  final String uuid;
  String publicKey;
  String nickname;
  final DevicePlatform platform;
  String ip;
  int port;
  DateTime lastConnected;
  bool isTrusted;
  final DateTime firstSeen;

  _TrustedDeviceRecord({
    required this.uuid,
    required this.publicKey,
    required this.nickname,
    required this.platform,
    required this.ip,
    this.port = 48772,
    DateTime? lastConnected,
    this.isTrusted = true,
    DateTime? firstSeen,
  })  : lastConnected = lastConnected ?? DateTime.now(),
        firstSeen = firstSeen ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'publicKey': publicKey,
        'nickname': nickname,
        'platform': platform.index,
        'ip': ip,
        'port': port,
        'lastConnected': lastConnected.toIso8601String(),
        'isTrusted': isTrusted,
        'firstSeen': firstSeen.toIso8601String(),
      };

  factory _TrustedDeviceRecord.fromJson(Map<String, dynamic> json) =>
      _TrustedDeviceRecord(
        uuid: json['uuid'] as String,
        publicKey: json['publicKey'] as String,
        nickname: json['nickname'] as String,
        platform: DevicePlatform.values[
            (json['platform'] as int?) ?? DevicePlatform.unknown.index],
        ip: json['ip'] as String? ?? '',
        port: (json['port'] as int?) ?? 48772,
        lastConnected: DateTime.tryParse(json['lastConnected'] as String? ?? ''),
        isTrusted: (json['isTrusted'] as bool?) ?? true,
        firstSeen: DateTime.tryParse(json['firstSeen'] as String? ?? ''),
      );

  Device toDevice() => Device(
        id: uuid,
        name: nickname,
        ip: ip,
        port: port,
        platform: platform,
        lastSeen: lastConnected,
        isTrusted: isTrusted,
        status: isTrusted ? DeviceStatus.trusted : DeviceStatus.online,
      );
}

class TrustedDeviceManager {
  TrustedDeviceManager._();
  static final TrustedDeviceManager instance = TrustedDeviceManager._();

  static const String _storageKey = 'gestureos_trusted_v2';
  List<_TrustedDeviceRecord> _records = [];
  bool _loaded = false;

  List<Device> get trustedDevices =>
      _records.where((r) => r.isTrusted).map((r) => r.toDevice()).toList();

  List<Device> getAllDevices() =>
      _records.map((r) => r.toDevice()).toList();

  bool isTrusted(String uuid) =>
      _records.any((r) => r.uuid == uuid && r.isTrusted);

  _TrustedDeviceRecord? _find(String uuid) {
    try {
      return _records.firstWhere((r) => r.uuid == uuid);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = json.decode(utf8.decode(base64.decode(raw)))
          as List<dynamic>;
      _records = list
          .map((e) =>
              _TrustedDeviceRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _records = [];
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, base64.encode(utf8.encode(encoded)));
  }

  Future<void> addOrUpdate({
    required String uuid,
    String publicKey = '',
    String? nickname,
    required DevicePlatform platform,
    required String ip,
    int port = 48772,
    bool trusted = true,
  }) async {
    await load();
    final existing = _find(uuid);
    if (existing != null) {
      existing.ip = ip;
      existing.port = port;
      existing.lastConnected = DateTime.now();
      existing.isTrusted = trusted;
      if (nickname != null) existing.nickname = nickname;
    } else {
      _records.add(_TrustedDeviceRecord(
        uuid: uuid,
        publicKey: publicKey,
        nickname: nickname ?? 'Device-$uuid'.substring(0, 12),
        platform: platform,
        ip: ip,
        port: port,
        isTrusted: trusted,
      ));
    }
    await _persist();
  }

  Future<void> remove(String uuid) async {
    await load();
    _records.removeWhere((r) => r.uuid == uuid);
    await _persist();
  }

  Future<void> setTrusted(String uuid, bool trusted) async {
    final record = _find(uuid);
    if (record != null) {
      record.isTrusted = trusted;
      await _persist();
    }
  }

  Future<void> rename(String uuid, String newName) async {
    final record = _find(uuid);
    if (record != null) {
      record.nickname = newName;
      await _persist();
    }
  }

  Future<void> updateLastConnected(String uuid) async {
    final record = _find(uuid);
    if (record != null) {
      record.lastConnected = DateTime.now();
      await _persist();
    }
  }

  String? getPublicKey(String uuid) => _find(uuid)?.publicKey;

  Future<void> setPublicKey(String uuid, String key) async {
    final record = _find(uuid);
    if (record != null) {
      record.publicKey = key;
      await _persist();
    }
  }

  String? getNickname(String uuid) => _find(uuid)?.nickname;
}
