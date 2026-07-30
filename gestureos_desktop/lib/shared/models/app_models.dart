enum DeviceConnectionStatus { disconnected, searching, connecting, connected }

enum TransferStatus { pending, inProgress, completed, failed, cancelled }

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
  });

  final String id;
  final String fileName;
  final FileType fileType;
  final int sizeBytes;
  final String senderDevice;
  final DateTime timestamp;
  final TransferStatus status;

  String get sizeFormatted => _formatBytes(sizeBytes);

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
  });

  final int filesReceived;
  final int devicesConnected;
  final String totalTransferred;
  final String lastTransferAgo;
}
