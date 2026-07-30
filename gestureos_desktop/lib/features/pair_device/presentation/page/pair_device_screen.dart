import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/qr_card.dart';
import 'package:gestureos_desktop/core/widgets/status_card.dart';
import 'package:gestureos_desktop/shared/providers/mock_providers.dart';

class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isPairing = false;
  bool _isRefreshHovered = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDimensions.animExtraSlow,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onRefreshQR() {
    setState(() => _isPairing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPairing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final desktop = ref.watch(desktopInfoProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingXxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pair Your Device',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                Text(
                  'Scan the QR code with your phone to pair',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                QRCard(onRefresh: _onRefreshQR),
                const SizedBox(height: AppDimensions.spacingXl),
                StatusCard(
                  message: _isPairing
                      ? 'Waiting for device...'
                      : desktop.name,
                  icon: _isPairing
                      ? Icons.radar_rounded
                      : Icons.computer_rounded,
                  isLoading: _isPairing,
                ),
                const SizedBox(height: AppDimensions.spacingXl),
                _buildInstructions(),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildBackButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to Pair',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          _buildInstructionStep(1, 'Open GestureOS on your phone'),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildInstructionStep(2, 'Tap "Pair with Desktop"'),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildInstructionStep(3, 'Scan the QR code above'),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isRefreshHovered = true),
      onExit: (_) => setState(() => _isRefreshHovered = false),
      child: GestureDetector(
        onTap: () => context.goNamed(RouteNames.home),
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXl,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: _isRefreshHovered
                ? AppColors.cardHover
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: const Text(
            'Back to Home',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
