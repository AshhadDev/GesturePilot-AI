import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/adaptive_network_engine.dart';
import 'package:gesture_os/shared/services/clipboard_service.dart';
import 'package:gesture_os/shared/services/compression_service.dart';
import 'package:gesture_os/shared/services/encryption_service.dart';
import 'package:gesture_os/shared/services/error_recovery_service.dart';
import 'package:gesture_os/shared/services/pairing_service.dart';
import 'package:gesture_os/shared/services/transfer_history.dart';
import 'package:gesture_os/shared/services/transfer_queue.dart';
import 'package:gesture_os/shared/services/trusted_device_manager.dart';

// ── Singleton Service Providers ──

final adaptiveNetworkProvider = Provider<AdaptiveNetworkEngine>((ref) {
  return AdaptiveNetworkEngine.instance;
});

final encryptionServiceProvider = Provider<EncryptionService>((ref) {
  return EncryptionService.instance;
});

final compressionServiceProvider = Provider<CompressionService>((ref) {
  return CompressionService.instance;
});

final errorRecoveryProvider = Provider<ErrorRecoveryService>((ref) {
  return ErrorRecoveryService.instance;
});

final clipboardSyncProvider = Provider<ClipboardSyncService>((ref) {
  return ClipboardSyncService.instance;
});

final pairingServiceProvider = Provider<PairingService>((ref) {
  return PairingService.instance;
});

final transferHistoryProvider = Provider<TransferHistoryService>((ref) {
  return TransferHistoryService.instance;
});

// ── Trusted Device Manager ──

final trustedDeviceManagerProvider =
    FutureProvider<List<Device>>((ref) async {
  final mgr = TrustedDeviceManager.instance;
  await mgr.load();
  return mgr.trustedDevices;
});

final isDeviceTrustedProvider = Provider.family<bool, String>((ref, uuid) {
  return TrustedDeviceManager.instance.isTrusted(uuid);
});

// ── Transfer Queue Provider ──

final transferQueueProvider = Provider<TransferQueueManager>((ref) {
  return TransferQueueManager.instance;
});

// ── Pairing State Provider ──

final pairingStepProvider = StateProvider<PairingStep>((ref) {
  return PairingStep.idle;
});

final pairingVerificationCodeProvider = StateProvider<String?>((ref) {
  return null;
});

// ── Performance Metrics Provider ──

class PerformanceMetrics {
  final double fps;
  final double memoryMb;
  final double cpuUsage;
  final double bandwidthMbps;
  final double latencyMs;
  final double chunkRate;
  final double packetLoss;
  final int discoveryTimeMs;
  final double gestureConfidence;

  const PerformanceMetrics({
    this.fps = 0,
    this.memoryMb = 0,
    this.cpuUsage = 0,
    this.bandwidthMbps = 0,
    this.latencyMs = 0,
    this.chunkRate = 0,
    this.packetLoss = 0,
    this.discoveryTimeMs = 0,
    this.gestureConfidence = 0,
  });

  PerformanceMetrics copyWith({
    double? fps,
    double? memoryMb,
    double? cpuUsage,
    double? bandwidthMbps,
    double? latencyMs,
    double? chunkRate,
    double? packetLoss,
    int? discoveryTimeMs,
    double? gestureConfidence,
  }) =>
      PerformanceMetrics(
        fps: fps ?? this.fps,
        memoryMb: memoryMb ?? this.memoryMb,
        cpuUsage: cpuUsage ?? this.cpuUsage,
        bandwidthMbps: bandwidthMbps ?? this.bandwidthMbps,
        latencyMs: latencyMs ?? this.latencyMs,
        chunkRate: chunkRate ?? this.chunkRate,
        packetLoss: packetLoss ?? this.packetLoss,
        discoveryTimeMs: discoveryTimeMs ?? this.discoveryTimeMs,
        gestureConfidence: gestureConfidence ?? this.gestureConfidence,
      );
}

final performanceMetricsProvider =
    StateNotifierProvider<PerformanceNotifier, PerformanceMetrics>((ref) {
  return PerformanceNotifier();
});

class PerformanceNotifier extends StateNotifier<PerformanceMetrics> {
  PerformanceNotifier() : super(const PerformanceMetrics());

  void updateFps(double fps) => state = state.copyWith(fps: fps);
  void updateMemory(double mb) => state = state.copyWith(memoryMb: mb);
  void updateCpu(double cpu) => state = state.copyWith(cpuUsage: cpu);
  void updateBandwidth(double mbps) =>
      state = state.copyWith(bandwidthMbps: mbps);
  void updateLatency(double ms) => state = state.copyWith(latencyMs: ms);
  void updateChunkRate(double rate) =>
      state = state.copyWith(chunkRate: rate);
  void updatePacketLoss(double loss) =>
      state = state.copyWith(packetLoss: loss);
  void updateDiscoveryTime(int ms) =>
      state = state.copyWith(discoveryTimeMs: ms);
  void updateGestureConfidence(double c) =>
      state = state.copyWith(gestureConfidence: c);

  void reset() => state = const PerformanceMetrics();
}
