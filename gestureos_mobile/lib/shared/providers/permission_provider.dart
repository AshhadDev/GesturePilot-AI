import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gesture_os/core/utils/logger.dart';

enum PermissionStatusState {
  initial,
  granted,
  denied,
  permanentlyDenied,
}

class PermissionStateData {
  const PermissionStateData({
    this.status = PermissionStatusState.initial,
    this.isRequesting = false,
  });

  final PermissionStatusState status;
  final bool isRequesting;

  bool get canAccessFiles =>
      status == PermissionStatusState.granted;

  PermissionStateData copyWith({
    PermissionStatusState? status,
    bool? isRequesting,
  }) {
    return PermissionStateData(
      status: status ?? this.status,
      isRequesting: isRequesting ?? this.isRequesting,
    );
  }
}

class PermissionNotifier extends StateNotifier<PermissionStateData> {
  PermissionNotifier() : super(const PermissionStateData()) {
    checkInitialPermission();
  }

  Future<void> checkInitialPermission() async {
    final granted = await _checkPermission();
    if (granted) {
      state = state.copyWith(status: PermissionStatusState.granted);
    }
  }

  Future<bool> _checkPermission() async {
    if (await Permission.photos.status.isGranted) return true;
    if (await Permission.videos.status.isGranted) return true;
    if (await Permission.audio.status.isGranted) return true;
    if (await Permission.storage.status.isGranted) return true;
    return false;
  }

  Future<void> requestPermission() async {
    state = state.copyWith(isRequesting: true);

    try {
      final results = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.storage,
      ].request();

      final anyGranted = results.values.any((s) => s.isGranted);

      if (anyGranted) {
        state = state.copyWith(
          status: PermissionStatusState.granted,
          isRequesting: false,
        );
      } else {
        final anyPermanentlyDenied =
            results.values.any((s) => s.isPermanentlyDenied);
        state = state.copyWith(
          status: anyPermanentlyDenied
              ? PermissionStatusState.permanentlyDenied
              : PermissionStatusState.denied,
          isRequesting: false,
        );
      }
    } catch (e, st) {
      AppLogger.error('Permission request failed', e, st);
      state = state.copyWith(
        status: PermissionStatusState.denied,
        isRequesting: false,
      );
    }
  }

  void openAppSettings() {
    openAppSettings();
  }
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionStateData>((ref) {
  return PermissionNotifier();
});
