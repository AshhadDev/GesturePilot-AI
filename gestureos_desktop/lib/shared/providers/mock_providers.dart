import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_models.dart';

const _mockDesktop = DesktopInfo(
  name: 'GestureOS Desktop',
  connectionStatus: DeviceConnectionStatus.connected,
  pairedDeviceName: 'Galaxy S24 Ultra',
);

final _mockHistory = [
  TransferHistoryItem(
    id: '1',
    fileName: 'Design_System_v3.fig',
    fileType: FileType.document,
    sizeBytes: 25728000,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 27, 14, 30),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '2',
    fileName: 'Vacation_Photo.jpg',
    fileType: FileType.image,
    sizeBytes: 3355443,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 27, 12, 15),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '3',
    fileName: 'Quarterly_Report.pdf',
    fileType: FileType.document,
    sizeBytes: 8493465,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 26, 18, 45),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '4',
    fileName: 'Product_Demo.mp4',
    fileType: FileType.video,
    sizeBytes: 163577856,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 26, 10, 0),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '5',
    fileName: 'Meeting_Notes.docx',
    fileType: FileType.document,
    sizeBytes: 250880,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 25, 16, 20),
    status: TransferStatus.failed,
  ),
  TransferHistoryItem(
    id: '6',
    fileName: 'Wallpaper_4K.png',
    fileType: FileType.image,
    sizeBytes: 12582912,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 25, 9, 10),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '7',
    fileName: 'Budget_2026.xlsx',
    fileType: FileType.document,
    sizeBytes: 573440,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 24, 14, 0),
    status: TransferStatus.completed,
  ),
  TransferHistoryItem(
    id: '8',
    fileName: 'Podcast_Ep12.mp3',
    fileType: FileType.audio,
    sizeBytes: 48234496,
    senderDevice: 'Galaxy S24 Ultra',
    timestamp: DateTime(2026, 7, 24, 8, 30),
    status: TransferStatus.completed,
  ),
];

const _mockStats = AppStats(
  filesReceived: 128,
  devicesConnected: 3,
  totalTransferred: '2.4 GB',
  lastTransferAgo: '2m ago',
);

final desktopInfoProvider = Provider<DesktopInfo>((ref) => _mockDesktop);
final transferHistoryProvider = Provider<List<TransferHistoryItem>>(
  (ref) => _mockHistory,
);
final appStatsProvider = Provider<AppStats>((ref) => _mockStats);

final transferSearchProvider = StateProvider<String>((ref) => '');

final filteredHistoryProvider = Provider<List<TransferHistoryItem>>((ref) {
  final query = ref.watch(transferSearchProvider).toLowerCase();
  final history = ref.watch(transferHistoryProvider);
  if (query.isEmpty) return history;
  return history
      .where((item) => item.fileName.toLowerCase().contains(query))
      .toList();
});

class SettingsState {
  const SettingsState({
    this.downloadFolder = 'C:\\Users\\User\\Downloads\\GestureOS',
    this.desktopName = 'GestureOS Desktop',
    this.autoStart = true,
    this.darkMode = true,
  });

  final String downloadFolder;
  final String desktopName;
  final bool autoStart;
  final bool darkMode;

  SettingsState copyWith({
    String? downloadFolder,
    String? desktopName,
    bool? autoStart,
    bool? darkMode,
  }) {
    return SettingsState(
      downloadFolder: downloadFolder ?? this.downloadFolder,
      desktopName: desktopName ?? this.desktopName,
      autoStart: autoStart ?? this.autoStart,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setDownloadFolder(String folder) {
    state = state.copyWith(downloadFolder: folder);
  }

  void setDesktopName(String name) {
    state = state.copyWith(desktopName: name);
  }

  void toggleAutoStart() {
    state = state.copyWith(autoStart: !state.autoStart);
  }

  void toggleDarkMode() {
    state = state.copyWith(darkMode: !state.darkMode);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
