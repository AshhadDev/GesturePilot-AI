import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/providers/magic_pickup_provider.dart';

class DebugSimulationButton extends ConsumerWidget {
  const DebugSimulationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickup = ref.watch(magicPickupProvider);
    if (!pickup.isDebugMode) return const SizedBox.shrink();
    if (pickup.isComplete) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () =>
              ref.read(magicPickupProvider.notifier).simulateAdvance(),
          icon: const Icon(Icons.skip_next_rounded, size: 18),
          label: Text(
            _buttonLabel(pickup.step),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.card,
            foregroundColor: AppColors.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(
                color: AppColors.border,
                width: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

String _buttonLabel(MagicPickupStep step) {
  switch (step) {
    case MagicPickupStep.idle:
      return 'Simulate: Open Hand';

    case MagicPickupStep.openHandDetected:
      return 'Simulate: Close Fist';

    case MagicPickupStep.fistConfirmed:
      return 'Simulate: Start Packing';

    case MagicPickupStep.packing:
      return 'Simulate: Finish Packing';

    case MagicPickupStep.packed:
      return 'Completed';
  }
}
}
