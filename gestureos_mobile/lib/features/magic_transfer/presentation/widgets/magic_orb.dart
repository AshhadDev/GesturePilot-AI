import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/energy_wave.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/hand_energy_effect.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/orb_particles.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/orb_shader.dart';
import 'package:gesture_os/features/magic_transfer/providers/magic_pickup_provider.dart';

class MagicOrb extends ConsumerStatefulWidget {
  const MagicOrb({
    super.key,
    this.size = 160,
    this.handPosition,
  });

  final double size;
  final Offset? handPosition;

  @override
  ConsumerState<MagicOrb> createState() => _MagicOrbState();
}

class _MagicOrbState extends ConsumerState<MagicOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ref.watch(magicPickupProvider);
    final intensity = _computeIntensity(pickup.step);
    final colors = _computeColors(pickup.step);
    final frameSize = widget.size * 1.8;
    final orbCenter = Offset(frameSize / 2, frameSize / 2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: frameSize,
          height: frameSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (intensity > 0.3)
                SizedBox(
                  width: frameSize,
                  height: frameSize,
                  child: EnergyWave(
                    time: t,
                    intensity: intensity,
                    color: colors.primary,
                    size: frameSize,
                  ),
                ),
              SizedBox(
                width: frameSize,
                height: frameSize,
                child: OrbParticles(
                  time: t,
                  intensity: intensity,
                  color: colors.accent,
                  size: frameSize,
                ),
              ),
              SizedBox(
                width: frameSize,
                height: frameSize,
                child: OrbShader(
                  time: t,
                  intensity: intensity,
                  size: frameSize,
                  primaryColor: colors.primary,
                  accentColor: colors.accent,
                ),
              ),
              HandEnergyEffect(
                handPosition: widget.handPosition,
                orbCenter: orbCenter,
                time: t,
                intensity: intensity,
              ),
            ],
          ),
        );
      },
    );
  }

  _OrbColors _computeColors(MagicPickupStep step) {
    switch (step) {
      case MagicPickupStep.idle:
        return _OrbColors(AppColors.primary, AppColors.accent);
      case MagicPickupStep.openHandDetected:
      case MagicPickupStep.handConfirmed:
        return _OrbColors(AppColors.secondary, const Color(0xFFD946EF));
      case MagicPickupStep.packing:
        return _OrbColors(const Color(0xFF22C55E), const Color(0xFF10B981));
      case MagicPickupStep.packed:
      case MagicPickupStep.carrying:
        return _OrbColors(const Color(0xFF22C55E), AppColors.accent);
    }
  }

  double _computeIntensity(MagicPickupStep step) {
    switch (step) {
      case MagicPickupStep.idle:
        return 0.5;
      case MagicPickupStep.openHandDetected:
      case MagicPickupStep.handConfirmed:
        return 0.8;
      case MagicPickupStep.packing:
        return 1.0;
      case MagicPickupStep.packed:
      case MagicPickupStep.carrying:
        return 0.9;
    }
  }
}

class _OrbColors {
  final Color primary;
  final Color accent;
  const _OrbColors(this.primary, this.accent);
}
