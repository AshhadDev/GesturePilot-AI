enum DeviceConnectionStatus { disconnected, searching, connecting, connected }

enum DesktopConnectionPhase {
  offline,
  searching,
  connecting,
  connected,
  receiving,
  completed,
}

enum TransferStatus { pending, inProgress, completed, failed, cancelled }

enum TransferSort { newest, oldest, largest, smallest, fastest }

enum FileType { image, video, document, audio, other }

class DesktopInfo {
  const DesktopInfo({
    required this.name,
    this.connectionStatus = DeviceConnectionStatus.disconnected,
    this.pairedDeviceName,
  });

  final String name;
  final DeviceConnectionStatus connectionStatus;
  final String? pairedDeviceName;

  bool get isConnected => connectionStatus == DeviceConnectionStatus.connected;
}

class TransferHistoryItem {
  const TransferHistoryItem({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.sizeBytes,
    required this.senderDevice,
    required this.timestamp,
    required this.status,
    this.duration,
    this.speedBytesPerSec,
    this.filePath,
    this.transferId,
  });

  final String id;
  final String fileName;
  final FileType fileType;
  final int sizeBytes;
  final String senderDevice;
  final DateTime timestamp;
  final TransferStatus status;
  final Duration? duration;
  final double? speedBytesPerSec;
  final String? filePath;
  final String? transferId;

  String get sizeFormatted => _formatBytes(sizeBytes);

  String get speedFormatted {
    final speed = speedBytesPerSec;
    if (speed == null || speed <= 0) return '—';
    if (speed >= 1073741824) {
      return '${(speed / 1073741824).toStringAsFixed(1)} GB/s';
    }
    if (speed >= 1048576) {
      return '${(speed / 1048576).toStringAsFixed(1)} MB/s';
    }
    if (speed >= 1024) {
      return '${(speed / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${speed.toStringAsFixed(0)} B/s';
  }

  String get durationFormatted {
    final d = duration;
    if (d == null) return '—';
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'fileType': fileType.index,
    'sizeBytes': sizeBytes,
    'senderDevice': senderDevice,
    'timestamp': timestamp.toIso8601String(),
    'status': status.index,
    'durationMs': duration?.inMilliseconds,
    'speedBytesPerSec': speedBytesPerSec,
    'filePath': filePath,
    'transferId': transferId,
  };

  factory TransferHistoryItem.fromJson(Map<String, dynamic> json) =>
      TransferHistoryItem(
        id: json['id'] as String,
        fileName: json['fileName'] as String,
        fileType: FileType.values[json['fileType'] as int? ?? 4],
        sizeBytes: json['sizeBytes'] as int,
        senderDevice: json['senderDevice'] as String,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        status: TransferStatus.values[json['status'] as int? ?? 0],
        duration: json['durationMs'] != null
            ? Duration(milliseconds: json['durationMs'] as int)
            : null,
        speedBytesPerSec: (json['speedBytesPerSec'] as num?)?.toDouble(),
        filePath: json['filePath'] as String?,
        transferId: json['transferId'] as String?,
      );

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
}

class AppStats {
  const AppStats({
    required this.filesReceived,
    required this.devicesConnected,
    required this.totalTransferred,
    required this.lastTransferAgo,
    this.averageSpeed = '0 B/s',
    this.lastTransferName,
    this.totalBytes = 0,
  });

  final int filesReceived;
  final int devicesConnected;
  final String totalTransferred;
  final String lastTransferAgo;
  final String averageSpeed;
  final String? lastTransferName;
  final int totalBytes;

  AppStats copyWith({
    int? filesReceived,
    int? devicesConnected,
    String? totalTransferred,
    String? lastTransferAgo,
    String? averageSpeed,
    String? lastTransferName,
    int? totalBytes,
  }) {
    return AppStats(
      filesReceived: filesReceived ?? this.filesReceived,
      devicesConnected: devicesConnected ?? this.devicesConnected,
      totalTransferred: totalTransferred ?? this.totalTransferred,
      lastTransferAgo: lastTransferAgo ?? this.lastTransferAgo,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      lastTransferName: lastTransferName ?? this.lastTransferName,
      totalBytes: totalBytes ?? this.totalBytes,
    );
  }
}
