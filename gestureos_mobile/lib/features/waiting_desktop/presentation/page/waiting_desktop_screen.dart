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
  late final AnimationController _discoveryController;

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

    _discoveryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

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
    _discoveryController.dispose();
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
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildOrbitSection(active, devices.valueOrNull ?? []),
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

  Widget _buildHeader(BuildContext context) {
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

  Widget _buildOrbitSection(bool active, List<Device> devices) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_radarController, _pulseController, _discoveryController]),
      builder: (context, _) {
        final radarAngle = _radarController.value * math.pi * 2;
        final pulse = _pulseController.value;
        final discT = _discoveryController.value;

        return SizedBox(
          width: double.infinity,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cinematic orbit visualization
              if (devices.isNotEmpty)
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _OrbitPainter(
                    angle: radarAngle,
                    pulse: pulse,
                    active: active,
                    deviceCount: devices.length,
                    selectedIndex: _selectedDevice != null
                        ? devices.indexWhere((d) => d.id == _selectedDevice!.id)
                        : -1,
                    discT: discT,
                  ),
                ),
              // Orb in center
              IgnorePointer(
                child: EnhancedOrb(
                  size: 50,
                  state: _selectedDevice != null
                      ? OrbState.launching
                      : (active ? OrbState.active : OrbState.idle),
                  intensity: 0.4 + pulse * 0.3,
                  progress: pulse,
                ),
              ),
              // Device orbit dots
              if (devices.isNotEmpty)
                ..._buildOrbitDots(devices, discT),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitDots(List<Device> devices, double discT) {
    final count = devices.length;
    final dotList = <Widget>[];
    final nearestIdx = 0;

    for (int i = 0; i < count; i++) {
      final isSelected = _selectedDevice?.id == devices[i].id;
      final isNearest = i == nearestIdx && count > 1;
      // Orbit position
      final orbitAngle = (i / count) * math.pi * 2 + discT * math.pi * 0.15;
      final orbitRadius = 60.0 + math.sin(discT * math.pi * 2 + i) * 5;
      final dx = math.cos(orbitAngle) * orbitRadius;
      final dy = math.sin(orbitAngle) * orbitRadius;
      // Float bob
      final floatOffset = math.sin(discT * math.pi * 4 + i * 1.5) * 3;

      // Auto-front nearest
      final scale = isNearest ? 1.3 : (isSelected ? 1.1 : 0.8);
      final alpha = isNearest || isSelected ? 1.0 : 0.6;

      dotList.add(
        Positioned(
          left: 100 + dx - 8 * scale,
          top: 100 + dy + floatOffset - 8 * scale,
          child: Opacity(
            opacity: alpha,
            child: Material(
              type: MaterialType.transparency,
              child: GestureDetector(
                onTap: () => setState(() => _selectedDevice = devices[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                width: 16 * scale,
                height: 16 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? AppColors.accent
                      : (isNearest
                          ? AppColors.success
                          : AppColors.primary),
                  boxShadow: [
                    if (isSelected || isNearest)
                      BoxShadow(
                        color: (isSelected
                                ? AppColors.accent
                                : AppColors.success)
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      // Connection beam from center to device
      if (isSelected) {
        dotList.add(
          Positioned(
            left: 100,
            top: 100,
            child: IgnorePointer(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _BeamPainter(
                  angle: orbitAngle,
                  distance: orbitRadius,
                  intensity: 0.6 + (math.sin(discT * math.pi * 3) + 1) * 0.2,
                ),
              ),
            ),
          ),
        );
      }
    }
    return dotList;
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

class _OrbitPainter extends CustomPainter {
  final double angle;
  final double pulse;
  final bool active;
  final int deviceCount;
  final int selectedIndex;
  final double discT;

  _OrbitPainter({
    required this.angle,
    required this.pulse,
    required this.active,
    required this.deviceCount,
    required this.selectedIndex,
    required this.discT,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Orbital rings
    final ringCount = 3;
    for (int i = 0; i < ringCount; i++) {
      final ringR = 40.0 + i * 25.0;
      final ringAlpha = (0.08 + (1 - i / ringCount) * 0.08).clamp(0.0, 0.15);
      final dashPhase = (angle + i * 0.5) % (math.pi * 2);

      canvas.drawCircle(
        center,
        ringR,
        Paint()
          ..color = AppColors.border.withValues(alpha: ringAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );

      // Animated dash on outer ring
      if (i == ringCount - 1 && active) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: ringR),
          dashPhase - 0.2,
          0.4,
          false,
          Paint()
            ..color = AppColors.accent.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Materialization particles (cinematic discovery)
    if (active && deviceCount > 0) {
      final particleCount = 12;
      for (int i = 0; i < particleCount; i++) {
        final pAngle = (i / particleCount) * math.pi * 2 +
            discT * math.pi * 0.5 +
            math.sin(discT * math.pi * 2 + i) * 0.3;
        final pDist = 30 + math.sin(discT * math.pi * 3 + i * 1.7) * 20;
        final px = center.dx + math.cos(pAngle) * pDist;
        final py = center.dy + math.sin(pAngle) * pDist;
        final particleLife = (math.sin(discT * math.pi * 2 + i * 0.7) + 1) / 2;
        final particleSize = 1 + particleLife * 2;

        canvas.drawCircle(
          Offset(px, py),
          particleSize,
          Paint()
            ..color = AppColors.primary.withValues(
              alpha: 0.1 + particleLife * 0.2,
            ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      angle != old.angle ||
      pulse != old.pulse ||
      active != old.active ||
      deviceCount != old.deviceCount ||
      discT != old.discT;
}

class _BeamPainter extends CustomPainter {
  final double angle;
  final double distance;
  final double intensity;

  _BeamPainter({
    required this.angle,
    required this.distance,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final endX = center.dx + math.cos(angle) * distance;
    final endY = center.dy + math.sin(angle) * distance;

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          AppColors.accent.withValues(alpha: 0.4 * intensity),
          AppColors.accent.withValues(alpha: 0.1 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromPoints(
          center,
          Offset(endX, endY),
        ),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * intensity;

    canvas.drawLine(center, Offset(endX, endY), beamPaint);
  }

  @override
  bool shouldRepaint(_BeamPainter old) =>
      angle != old.angle || intensity != old.intensity;
}
