import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/device_discovery_card.dart';
import 'package:gesture_os/core/widgets/enhanced_orb.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/providers/device_providers.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

class WaitingDesktopScreen extends ConsumerStatefulWidget {
  const WaitingDesktopScreen({super.key});

  @override
  ConsumerState<WaitingDesktopScreen> createState() =>
      _WaitingDesktopScreenState();
}

class _WaitingDesktopScreenState extends ConsumerState<WaitingDesktopScreen>
    with SingleTickerProviderStateMixin {
  Device? _selectedDevice;
  late final AnimationController _radarController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startDiscovery();
  }

  void _startDiscovery() {
    Future.microtask(() {
      ref.read(discoveryControllerProvider).start();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStartTransfer() {
    final device = _selectedDevice;
    if (device == null) return;
    final notifier = ref.read(transferProvider.notifier);
    notifier.setTargetDevice(device);
    notifier.startTransfer();
    context.goNamed(RouteNames.transferProgress);
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(discoveredDevicesStreamProvider);
    final trusted = ref.watch(trustedDevicesProvider);
    final active = ref.watch(discoveryActiveProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(),
              const SizedBox(height: 8),
              _buildRadarSection(active),
              const SizedBox(height: 8),
              Expanded(
                child: devices.when(
                  data: (discovered) {
                    final allDevices = _mergeDevices(discovered, trusted);
                    if (allDevices.isEmpty) {
                      return _buildEmptyState(active);
                    }
                    return _buildDeviceList(allDevices);
                  },
                  loading: () => _buildEmptyState(active),
                  error: (_, __) => _buildEmptyState(active),
                ),
              ),
              _buildStartButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Device> _mergeDevices(List<Device> discovered, List<Device> trusted) {
    final map = <String, Device>{};
    for (final d in discovered) {
      map[d.id] = d;
    }
    for (final d in trusted) {
      if (!map.containsKey(d.id)) {
        map[d.id] = d;
      }
    }
    return map.values.toList();
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.carrying),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'Select Desktop',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildRadarSection(bool active) {
    return AnimatedBuilder(
      animation: Listenable.merge([_radarController, _pulseController]),
      builder: (context, _) {
        final radarAngle = _radarController.value * math.pi * 2;
        final pulse = _pulseController.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Radar painting
            SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(
                painter: _RadarPainter(
                  angle: radarAngle,
                  pulse: pulse,
                  active: active,
                  hasDevices: ref.read(discoveredDevicesStreamProvider).valueOrNull?.isNotEmpty ?? false,
                ),
              ),
            ),
            // Orb in center
            IgnorePointer(
              child: EnhancedOrb(
                size: 40,
                state: _selectedDevice != null ? OrbState.launching : OrbState.carrying,
                intensity: 0.4 + pulse * 0.3,
                progress: pulse,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool active) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.radar_rounded : Icons.wifi_find_rounded,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            active ? 'Searching for devices...' : 'Discovery paused',
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Make sure your desktop is on the same network',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<Device> devices) {
    return ListView.separated(
      itemCount: devices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        final isSelected = _selectedDevice?.id == device.id;
        final isNearest = index == 0 && devices.length > 1;
        return DeviceDiscoveryCard(
          device: device,
          isSelected: isSelected,
          isNearest: isNearest,
          distance: index.toDouble(),
          onTap: () => setState(() => _selectedDevice = device),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _selectedDevice != null ? _onStartTransfer : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: _selectedDevice != null
              ? AppColors.primaryGradient
              : LinearGradient(colors: [AppColors.card, AppColors.card]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _selectedDevice != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            _selectedDevice != null
                ? 'Transfer to ${_selectedDevice!.name}'
                : 'Select a device',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _selectedDevice != null
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double angle;
  final double pulse;
  final bool active;
  final bool hasDevices;

  _RadarPainter({
    required this.angle,
    required this.pulse,
    required this.active,
    required this.hasDevices,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Background circle
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = AppColors.card.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    );

    // Radar rings
    for (int i = 1; i <= 3; i++) {
      final ringR = r * (i / 3.0);
      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = AppColors.border.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    if (!active) return;

    // Scanning beam
    final beamPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.3,
        endAngle: angle + 0.3,
        colors: [
          AppColors.accent.withValues(alpha: 0.15),
          AppColors.accent.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r, beamPaint);

    // Scanner dot
    final dotX = center.dx + math.cos(angle) * r * 0.85;
    final dotY = center.dy + math.sin(angle) * r * 0.85;
    canvas.drawCircle(
      Offset(dotX, dotY),
      3,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      Offset(dotX, dotY),
      6,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Pulse wave
    if (hasDevices) {
      final pulseR = r * (0.3 + pulse * 0.5);
      canvas.drawCircle(
        center,
        pulseR,
        Paint()
          ..color = AppColors.success.withValues(alpha: (1 - pulse) * 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * (1 - pulse),
      );
    }

    // Device signal dots
    if (hasDevices) {
      for (int i = 0; i < 3; i++) {
        final dotAngle = (i / 3.0) * math.pi * 2 + angle * 0.3;
        final dotDist = r * (0.4 + (i + 1) * 0.12);
        final dx = center.dx + math.cos(dotAngle) * dotDist;
        final dy = center.dy + math.sin(dotAngle) * dotDist;
        final dotPulse = (math.sin(angle + i) + 1) / 2;

        canvas.drawCircle(
          Offset(dx, dy),
          1.5 + dotPulse * 1.5,
          Paint()..color = AppColors.primary.withValues(alpha: 0.4 + dotPulse * 0.3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      angle != old.angle || pulse != old.pulse || active != old.active;
}
