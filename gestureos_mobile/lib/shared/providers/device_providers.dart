import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/device_service.dart';
import 'package:gesture_os/shared/services/discovery_service.dart';

final localDeviceInfoProvider = FutureProvider<LocalDeviceInfo>((ref) async {
  return DeviceInfoService.instance.getInfo();
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  return DiscoveryService.instance;
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService.instance;
});

final discoveredDevicesStreamProvider = StreamProvider<List<Device>>((ref) {
  final discovery = ref.watch(discoveryServiceProvider);
  return discovery.events.map((_) => discovery.discoveredDevices);
});

final trustedDevicesProvider =
    StateNotifierProvider<TrustedDevicesNotifier, List<Device>>((ref) {
  return TrustedDevicesNotifier();
});

class TrustedDevicesNotifier extends StateNotifier<List<Device>> {
  TrustedDevicesNotifier() : super([]);

  Future<void> load() async {
    await DeviceService.instance.loadTrustedDevices();
    state = DeviceService.instance.trustedDevices;
  }

  Future<void> add(Device device) async {
    await DeviceService.instance.addTrusted(device);
    state = DeviceService.instance.trustedDevices;
  }

  Future<void> remove(String deviceId) async {
    await DeviceService.instance.removeTrusted(deviceId);
    state = DeviceService.instance.trustedDevices;
  }

  bool isTrusted(String deviceId) {
    return state.any((d) => d.id == deviceId);
  }
}

final discoveryActiveProvider = StateProvider<bool>((ref) => false);

class DiscoveryController {
  final DiscoveryService _discovery;
  final Ref _ref;

  DiscoveryController(this._discovery, this._ref);

  bool get isRunning => _discovery.isRunning;

  Future<void> start() async {
    await _discovery.start();
    _ref.read(discoveryActiveProvider.notifier).state = true;
  }

  Future<void> stop() async {
    await _discovery.stop();
    _ref.read(discoveryActiveProvider.notifier).state = false;
  }
}

final discoveryControllerProvider = Provider<DiscoveryController>((ref) {
  final discovery = ref.watch(discoveryServiceProvider);
  return DiscoveryController(discovery, ref);
});
