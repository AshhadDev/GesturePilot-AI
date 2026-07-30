enum DevicePlatform { android, iOS, windows, macOS, linux, web, unknown }

enum DeviceConnection { wifi, hotspot, ethernet, bluetooth, unknown }

enum DeviceStatus { offline, online, connecting, pairing, trusted, rejected }

class Device {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DevicePlatform platform;
  final DeviceConnection connection;
  final DeviceStatus status;
  final DateTime lastSeen;
  final bool isTrusted;
  final int signalStrength;
  final String version;

  const Device({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 48771,
    this.platform = DevicePlatform.unknown,
    this.connection = DeviceConnection.wifi,
    this.status = DeviceStatus.online,
    required this.lastSeen,
    this.isTrusted = false,
    this.signalStrength = 0,
    this.version = '1.0.0',
  });

  Device copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    DevicePlatform? platform,
    DeviceConnection? connection,
    DeviceStatus? status,
    DateTime? lastSeen,
    bool? isTrusted,
    int? signalStrength,
    String? version,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      platform: platform ?? this.platform,
      connection: connection ?? this.connection,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isTrusted: isTrusted ?? this.isTrusted,
      signalStrength: signalStrength ?? this.signalStrength,
      version: version ?? this.version,
    );
  }

  bool get isOnline => status == DeviceStatus.online || status == DeviceStatus.trusted;

  String get platformLabel {
    switch (platform) {
      case DevicePlatform.android: return 'Android';
      case DevicePlatform.iOS: return 'iPhone';
      case DevicePlatform.windows: return 'Windows';
      case DevicePlatform.macOS: return 'macOS';
      case DevicePlatform.linux: return 'Linux';
      case DevicePlatform.web: return 'Web';
      case DevicePlatform.unknown: return 'Device';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ip': ip,
    'port': port,
    'platform': platform.index,
    'connection': connection.index,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
    'isTrusted': isTrusted,
    'version': version,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as String,
    name: json['name'] as String,
    ip: json['ip'] as String,
    port: json['port'] as int? ?? 48771,
    platform: DevicePlatform.values[json['platform'] as int? ?? 6],
    connection: DeviceConnection.values[json['connection'] as int? ?? 0],
    lastSeen: DateTime.fromMillisecondsSinceEpoch(json['lastSeen'] as int),
    isTrusted: json['isTrusted'] as bool? ?? false,
    version: json['version'] as String? ?? '1.0.0',
  );
}
