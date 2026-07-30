import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/device_model.dart';

class DeviceDiscoveryCard extends StatefulWidget {
  final Device device;
  final bool isSelected;
  final bool isNearest;
  final double distance;
  final VoidCallback? onTap;

  const DeviceDiscoveryCard({
    super.key,
    required this.device,
    this.isSelected = false,
    this.isNearest = false,
    this.distance = 0,
    this.onTap,
  });

  @override
  State<DeviceDiscoveryCard> createState() => _DeviceDiscoveryCardState();
}

class _DeviceDiscoveryCardState extends State<DeviceDiscoveryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final AnimationController _enterController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _enterController]),
      builder: (context, _) {
        final glow = _glowController.value;
        final enterScale = 0.8 + _enterController.value * 0.2;
        final enterOpacity = _enterController.value;

        return Opacity(
          opacity: enterOpacity,
          child: Transform.scale(
            scale: enterScale,
            child: Semantics(
              label: '${widget.device.name} ${widget.device.platform.name} device${widget.isNearest ? ', nearest' : ''}${widget.isSelected ? ', selected' : ''}',
              hint: 'Tap to select this device for transfer',
              selected: widget.isSelected,
              onTapHint: 'Select device',
              child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.accent
                        : AppColors.border.withValues(alpha: 0.5),
                    width: widget.isSelected ? 2 : 1,
                  ),
                  color: widget.isSelected
                      ? AppColors.card.withValues(alpha: 0.95)
                      : AppColors.card,
                  boxShadow: widget.isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2 + glow * 0.15),
                            blurRadius: 16 + glow * 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    // Device icon with animated border
                    _buildDeviceIcon(glow),
                    const SizedBox(width: 14),
                    // Device info
                    Expanded(child: _buildDeviceInfo()),
                    const SizedBox(width: 8),
                    // Connection quality
                    _buildConnectionQuality(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildDeviceIcon(double glow) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: widget.isSelected
              ? [AppColors.accent, AppColors.primary]
              : [AppColors.card, AppColors.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: widget.isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _platformIcon(),
            color: widget.isSelected ? Colors.white : AppColors.textPrimary,
            size: 24,
          ),
          // Online indicator
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.device.isOnline
                    ? AppColors.success
                    : AppColors.textSecondary,
                boxShadow: widget.device.isOnline
                    ? [
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.4 + glow * 0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.device.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (widget.device.isTrusted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Trusted',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
            if (widget.isNearest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Nearest',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _infoChip(Icons.lan_rounded, widget.device.platform.name),
            if (widget.device.signalStrength > 0) ...[
              const SizedBox(width: 8),
              _infoChip(Icons.signal_wifi_4_bar_rounded,
                  '${widget.device.signalStrength}%'),
            ],
            if (widget.distance > 0) ...[
              const SizedBox(width: 8),
              _infoChip(Icons.near_me_rounded,
                  widget.distance < 1 ? '<1m' : '${widget.distance.toStringAsFixed(0)}m'),
            ],
          ],
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionQuality() {
    if (!widget.device.isOnline) {
      return const Icon(Icons.cloud_off_rounded, color: AppColors.textSecondary, size: 20);
    }

    final bars = (widget.device.signalStrength / 25).ceil().clamp(1, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        return Container(
          width: 4,
          height: 6 + i * 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: i < bars
                ? (widget.isSelected ? AppColors.accent : AppColors.primary)
                : AppColors.border,
          ),
        );
      }),
    );
  }

  IconData _platformIcon() {
    switch (widget.device.platform) {
      case DevicePlatform.android:
        return Icons.android_rounded;
      case DevicePlatform.windows:
        return Icons.computer_rounded;
      case DevicePlatform.macOS:
        return Icons.laptop_mac_rounded;
      case DevicePlatform.iOS:
        return Icons.phone_iphone_rounded;
      case DevicePlatform.linux:
        return Icons.terminal_rounded;
      case DevicePlatform.web:
        return Icons.language_rounded;
      case DevicePlatform.unknown:
        return Icons.devices_rounded;
    }
  }
}
