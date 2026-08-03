import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestureos_desktop/shared/models/device_model.dart';
import 'package:gestureos_desktop/core/services/device_info_service.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';
import 'package:gestureos_desktop/shared/services/discovery_service.dart';
import 'package:gestureos_desktop/shared/services/settings_service.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';
import 'package:gestureos_desktop/shared/services/history_store.dart';
import 'package:gestureos_desktop/shared/services/transfer_service.dart';
import 'package:gestureos_desktop/shared/services/trusted_device_manager.dart';

final desktopInfoProvider = FutureProvider<DesktopInfo>((ref) async {
  final info = await DeviceInfoService.instance.getInfo();
  return DesktopInfo(
    name: info.name,
    connectionStatus: DeviceConnectionStatus.disconnected,
  );
});

final discoveredDevicesProvider = StreamProvider<List<Device>>((ref) {
  return DiscoveryService.instance.events.map((event) {
    return DiscoveryService.instance.discoveredDevices;
  });
});

final connectionSnapshotProvider =
    StreamProvider<ConnectionSnapshot>((ref) {
  return ConnectionManager.instance.stateStream;
});

class DesktopSettings {
  final String desktopName;
  final String downloadFolder;
  final bool darkMode;
  final bool autoAccept;
  final bool autoOpenFiles;
  final bool startOnBoot;
  final bool minimizeToTray;
  final bool autoDiscover;
  final bool enableQr;
  final int connectionTimeout;
  final bool transferNotification;
  final bool transferSound;

  const DesktopSettings({
    this.desktopName = 'My Desktop',
    this.downloadFolder = '',
    this.darkMode = true,
    this.autoAccept = false,
    this.autoOpenFiles = true,
    this.startOnBoot = false,
    this.minimizeToTray = true,
    this.autoDiscover = true,
    this.enableQr = true,
    this.connectionTimeout = 30,
    this.transferNotification = true,
    this.transferSound = true,
  });

  DesktopSettings copyWith({
    String? desktopName,
    String? downloadFolder,
    bool? darkMode,
    bool? autoAccept,
    bool? autoOpenFiles,
    bool? startOnBoot,
    bool? minimizeToTray,
    bool? autoDiscover,
    bool? enableQr,
    int? connectionTimeout,
    bool? transferNotification,
    bool? transferSound,
  }) {
    return DesktopSettings(
      desktopName: desktopName ?? this.desktopName,
      downloadFolder: downloadFolder ?? this.downloadFolder,
      darkMode: darkMode ?? this.darkMode,
      autoAccept: autoAccept ?? this.autoAccept,
      autoOpenFiles: autoOpenFiles ?? this.autoOpenFiles,
      startOnBoot: startOnBoot ?? this.startOnBoot,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      autoDiscover: autoDiscover ?? this.autoDiscover,
      enableQr: enableQr ?? this.enableQr,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      transferNotification:
          transferNotification ?? this.transferNotification,
      transferSound: transferSound ?? this.transferSound,
    );
  }

  static DesktopSettings fromService() {
    final s = SettingsService.instance;
    return DesktopSettings(
      desktopName: s.desktopName.isNotEmpty ? s.desktopName : 'My Desktop',
      downloadFolder: s.transferFolder,
      darkMode: s.theme != 'light',
      autoAccept: s.autoAcceptTrusted,
      autoOpenFiles: s.autoOpenFiles,
      autoDiscover: s.autoDiscover,
      enableQr: s.enableQr,
      connectionTimeout: s.connectionTimeout,
      transferNotification: s.transferNotification,
      transferSound: s.transferSound,
    );
  }
}

class SettingsNotifier extends StateNotifier<DesktopSettings> {
  SettingsNotifier() : super(DesktopSettings.fromService());

  void setDesktopName(String v) {
    DeviceInfoService.instance.setDeviceName(v);
    DiscoveryService.instance.notifyNameChange(v);
    SettingsService.instance.setDesktopName(v);
    state = state.copyWith(desktopName: v);
  }

  void setDownloadFolder(String v) {
    SettingsService.instance.setTransferFolder(v);
    state = state.copyWith(downloadFolder: v);
  }

  void setDarkMode(bool v) {
    SettingsService.instance.setTheme(v ? 'dark' : 'light');
    state = state.copyWith(darkMode: v);
  }

  void setAutoAccept(bool v) {
    SettingsService.instance.setAutoAcceptTrusted(v);
    state = state.copyWith(autoAccept: v);
  }

  void setAutoOpenFiles(bool v) {
    SettingsService.instance.setAutoOpenFiles(v);
    state = state.copyWith(autoOpenFiles: v);
  }

  void setStartOnBoot(bool v) {
    state = state.copyWith(startOnBoot: v);
  }

  void setMinimizeToTray(bool v) {
    state = state.copyWith(minimizeToTray: v);
  }

  void setAutoDiscover(bool v) async {
    SettingsService.instance.setAutoDiscover(v);
    if (v) {
      await DiscoveryService.instance.start();
      ConnectionManager.instance.onDiscoveryPreferenceChanged(true);
    } else {
      await DiscoveryService.instance.stop();
      ConnectionManager.instance.onDiscoveryPreferenceChanged(false);
    }
    state = state.copyWith(autoDiscover: v);
  }

  void setEnableQr(bool v) {
    SettingsService.instance.setEnableQr(v);
    state = state.copyWith(enableQr: v);
  }

  void setConnectionTimeout(int seconds) {
    SettingsService.instance.setConnectionTimeout(seconds);
    state = state.copyWith(connectionTimeout: seconds);
  }

  void setTransferNotification(bool v) {
    SettingsService.instance.setTransferNotification(v);
    state = state.copyWith(transferNotification: v);
  }

  void setTransferSound(bool v) {
    SettingsService.instance.setTransferSound(v);
    state = state.copyWith(transferSound: v);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, DesktopSettings>((ref) {
  return SettingsNotifier();
});

final transferStateProvider = StateProvider<TransferStatus?>((ref) => null);

class TransferHistoryNotifier extends StateNotifier<List<TransferHistoryItem>> {
  TransferHistoryNotifier() : super(const []) {
    _init();
  }

  bool _listening = false;

  Future<void> _init() async {
    final persisted = await HistoryStore.instance.load();
    state = persisted;
    _listenToTransfers();
  }

  void _listenToTransfers() {
    if (_listening) return;
    _listening = true;
    TransferService.instance.completionEvents.listen(_onTransferCompleted);
  }

  void _onTransferCompleted(TransferCompletionEvent event) {
    final now = DateTime.now();
    final items = event.files.map((file) {
      final type = _fileTypeFromName(file.fileName);
      return TransferHistoryItem(
        id: '${event.transferId}-${file.relativePath}',
        fileName: file.fileName,
        fileType: type,
        sizeBytes: file.fileSize,
        senderDevice: event.remoteName,
        timestamp: now,
        status: TransferStatus.completed,
        duration: event.duration,
        speedBytesPerSec: event.totalBytes > 0
            ? event.transferredBytes / event.duration.inMilliseconds * 1000
            : 0,
        filePath: event.filePathFor(file),
        transferId: event.transferId,
      );
    }).toList();

    final updated = [...items, ...state];
    state = updated.take(200).toList();
    HistoryStore.instance.save(state);
  }

  FileType _fileTypeFromName(String name) {
    final ext = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    const audioExts = {'mp3', 'wav', 'aac', 'flac', 'ogg'};
    const docExts = {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'txt', 'csv', 'json', 'xml', 'zip', 'rar', '7z',
    };
    if (imageExts.contains(ext)) return FileType.image;
    if (videoExts.contains(ext)) return FileType.video;
    if (audioExts.contains(ext)) return FileType.audio;
    if (docExts.contains(ext)) return FileType.document;
    return FileType.other;
  }

  void removeItem(String id) {
    state = state.where((i) => i.id != id).toList();
    HistoryStore.instance.save(state);
  }

  void clearAll() {
    state = const [];
    HistoryStore.instance.save(state);
  }
}

final transferHistoryProvider = StateNotifierProvider<
    TransferHistoryNotifier, List<TransferHistoryItem>>((ref) {
  return TransferHistoryNotifier();
});

final recentTransfersProvider = Provider<List<TransferHistoryItem>>((ref) {
  final history = ref.watch(transferHistoryProvider);
  return history
      .where((h) => h.status == TransferStatus.completed)
      .take(5)
      .toList();
});

final trustedDevicesProvider = StreamProvider<List<Device>>((ref) async* {
  await TrustedDeviceManager.instance.load();
  yield TrustedDeviceManager.instance.trustedDevices;
  await for (final _ in TrustedDeviceManager.instance.changes) {
    yield TrustedDeviceManager.instance.trustedDevices;
  }
});

final transferSearchProvider = StateProvider<String>((ref) => '');

final transferSortProvider =
    StateProvider<TransferSort>((ref) => TransferSort.newest);

final transferStatusFilterProvider =
    StateProvider<TransferStatus?>((ref) => null);

final filteredHistoryProvider = Provider<List<TransferHistoryItem>>((ref) {
  final query = ref.watch(transferSearchProvider).toLowerCase();
  final sort = ref.watch(transferSortProvider);
  final statusFilter = ref.watch(transferStatusFilterProvider);
  final history = ref.watch(transferHistoryProvider);

  var items = history;
  if (statusFilter != null) {
    items = items.where((h) => h.status == statusFilter).toList();
  }
  if (query.isNotEmpty) {
    items = items
        .where((h) =>
            h.fileName.toLowerCase().contains(query) ||
            h.senderDevice.toLowerCase().contains(query))
        .toList();
  }

  switch (sort) {
    case TransferSort.newest:
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    case TransferSort.oldest:
      items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    case TransferSort.largest:
      items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    case TransferSort.smallest:
      items.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
    case TransferSort.fastest:
      items.sort((a, b) =>
          (b.speedBytesPerSec ?? 0).compareTo(a.speedBytesPerSec ?? 0));
  }

  return items;
});

final appStatsProvider = Provider<AppStats>((ref) {
  final history = ref.watch(transferHistoryProvider);
  final trusted = ref.watch(trustedDevicesProvider).valueOrNull ?? [];

  final completed =
      history.where((h) => h.status == TransferStatus.completed).toList();

  var totalBytes = 0;
  var speedSum = 0.0;
  var speedCount = 0;
  for (final h in completed) {
    totalBytes += h.sizeBytes;
    if (h.speedBytesPerSec != null && h.speedBytesPerSec! > 0) {
      speedSum += h.speedBytesPerSec!;
      speedCount++;
    }
  }

  final avgSpeed = speedCount > 0 ? speedSum / speedCount : 0.0;
  final last = completed.isNotEmpty
      ? completed.reduce(
          (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b)
      : null;

  return AppStats(
    filesReceived: completed.length,
    devicesConnected: trusted.length,
    totalTransferred: _formatBytes(totalBytes),
    totalBytes: totalBytes,
    averageSpeed: _formatSpeed(avgSpeed),
    lastTransferAgo: last != null ? _formatAgo(last.timestamp) : 'Never',
    lastTransferName: last?.fileName,
  );
});

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1073741824) {
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
}

String _formatSpeed(double speed) {
  if (speed <= 0) return '0 B/s';
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

String _formatAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
