import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/services/device_info_service.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/connection_badge.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';
import 'package:gestureos_desktop/shared/services/qr_pairing_service.dart';

class PairDeviceScreen extends ConsumerStatefulWidget {
  const PairDeviceScreen({super.key});

  @override
  ConsumerState<PairDeviceScreen> createState() => _PairDeviceScreenState();
}

class _PairDeviceScreenState extends ConsumerState<PairDeviceScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isRefreshHovered = false;
  String? _qrData;
  String _desktopName = 'Desktop';
  String _desktopId = '';
  bool _building = true;

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
    _buildQr();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _buildQr() async {
    setState(() => _building = true);
    final info = await DeviceInfoService.instance.getInfo();
    final payload = await QrPairingService.instance.buildPayload();
    if (!mounted) return;
    setState(() {
      _qrData = payload.encode();
      _desktopName = info.name;
      _desktopId = info.id;
      _building = false;
    });
  }

  Future<void> _onRefreshQR() async {
    QrPairingService.instance.rotateSessionToken();
    QrPairingService.instance.rotateKeyPair();
    await _buildQr();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot =
        ref.watch(connectionSnapshotProvider).valueOrNull ??
            const ConnectionSnapshot(phase: ConnectionPhase.searching);

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
                Row(
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
                    const SizedBox(width: AppDimensions.spacingMd),
                    ConnectionBadge(status: snapshot.badgeStatus),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingSm),
                const Text(
                  'Scan the QR code with your phone to pair',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXxl),
                _buildQrBox(),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildDeviceInfo(),
                const SizedBox(height: AppDimensions.spacingXl),
                _buildRefreshButton(),
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

  Widget _buildQrBox() {
    return AnimatedContainer(
      duration: AppDimensions.animNormal,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      child: _building
          ? const SizedBox(
              width: 240,
              height: 240,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            )
          : QrImageView(
              data: _qrData ?? '',
              version: QrVersions.auto,
              size: 240,
              gapless: false,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: const Color(0xFF0A0A0A),
              ),
            ),
    );
  }

  Widget _buildDeviceInfo() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingLg,
        vertical: AppDimensions.spacingMd,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Icon(
              Icons.computer_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _desktopName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: $_desktopId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Secure session',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isRefreshHovered = true),
      onExit: (_) => setState(() => _isRefreshHovered = false),
      child: GestureDetector(
        onTap: _onRefreshQR,
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXl,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _isRefreshHovered
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(
              color: _isRefreshHovered
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: _isRefreshHovered
                    ? AppColors.accent
                    : AppColors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                'Refresh QR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _isRefreshHovered
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
            ],
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
          _buildInstructionStep(1, 'Open GestureOS Mobile'),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildInstructionStep(2, 'Tap "Scan Desktop"'),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildInstructionStep(3, 'Scan the QR code above'),
          const SizedBox(height: AppDimensions.spacingSm),
          _buildInstructionStep(4, 'Connection starts automatically'),
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
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
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
