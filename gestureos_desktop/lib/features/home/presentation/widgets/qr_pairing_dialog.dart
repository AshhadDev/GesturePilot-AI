import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:gestureos_desktop/core/services/device_info_service.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/connection_badge.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';
import 'package:gestureos_desktop/shared/services/qr_pairing_service.dart';

class QrPairingDialog extends ConsumerStatefulWidget {
  const QrPairingDialog({super.key});

  @override
  ConsumerState<QrPairingDialog> createState() => _QrPairingDialogState();
}

class _QrPairingDialogState extends ConsumerState<QrPairingDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  String? _qrData;
  String _desktopName = 'Desktop';
  String _desktopId = '';
  bool _building = true;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _buildQr();
  }

  @override
  void dispose() {
    _entranceController.dispose();
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

  Future<void> _refreshQr() async {
    QrPairingService.instance.rotateSessionToken();
    QrPairingService.instance.rotateKeyPair();
    await _buildQr();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot =
        ref.watch(connectionSnapshotProvider).valueOrNull ??
            const ConnectionSnapshot(phase: ConnectionPhase.searching);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOutBack,
        ),
        child: FadeTransition(
          opacity: _entranceController,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Connect Device',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ConnectionBadge(
                      status: snapshot.badgeStatus,
                      label: _badgeLabel(snapshot.phase),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildQrBox(),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildDeviceInfo(),
                const SizedBox(height: AppDimensions.spacingLg),
                _buildInstructions(),
                const SizedBox(height: AppDimensions.spacingLg),
                Row(
                  children: [
                    Expanded(
                      child: _buildGhostButton(
                        label: 'Refresh QR',
                        icon: Icons.refresh_rounded,
                        onTap: _refreshQr,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: _buildGhostButton(
                        label: 'Close',
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _badgeLabel(ConnectionPhase phase) {
    switch (phase) {
      case ConnectionPhase.offline:
        return 'Offline';
      case ConnectionPhase.searching:
        return 'Searching';
      case ConnectionPhase.connecting:
        return 'Connecting';
      case ConnectionPhase.connected:
      case ConnectionPhase.receiving:
      case ConnectionPhase.completed:
        return 'Connected';
    }
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
          ? SizedBox(
              width: 220,
              height: 220,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            )
          : QrImageView(
              data: _qrData ?? '',
              version: QrVersions.auto,
              size: 220,
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
          Text(
            'Secure session',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'How to connect',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: AppDimensions.spacingSm),
          _InstructionRow(step: '1', text: 'Open GestureOS Mobile'),
          SizedBox(height: AppDimensions.spacingXs),
          _InstructionRow(step: '2', text: 'Tap Scan Desktop'),
          SizedBox(height: AppDimensions.spacingXs),
          _InstructionRow(step: '3', text: 'Scan the QR code'),
          SizedBox(height: AppDimensions.spacingXs),
          _InstructionRow(
            step: '4',
            text: 'Connection starts automatically',
            last: true,
          ),
        ],
      ),
    );
  }

  Widget _buildGhostButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 17),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({
    required this.step,
    required this.text,
    this.last = false,
  });

  final String step;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: last ? AppColors.textSecondary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
