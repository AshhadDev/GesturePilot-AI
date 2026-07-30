import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/connection_badge.dart';
import 'package:gestureos_desktop/core/widgets/statistic_card.dart';
import 'package:gestureos_desktop/core/widgets/transfer_card.dart';
import 'package:gestureos_desktop/core/widgets/desktop_app_bar.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';
import 'package:gestureos_desktop/shared/providers/mock_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  bool _isTransferHovered = false;

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

  @override
  Widget build(BuildContext context) {
    final desktop = ref.watch(desktopInfoProvider);
    final stats = ref.watch(appStatsProvider);
    final history = ref.watch(transferHistoryProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          const DesktopAppBar(title: 'Home'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDesktopCard(desktop),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _buildTransferButton(),
                  const SizedBox(height: AppDimensions.spacingXl),
                  _buildStatsRow(stats),
                  const SizedBox(height: AppDimensions.spacingXxl),
                  const Text(
                    'Recent Transfers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  ...history.take(4).map((t) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppDimensions.spacingSm,
                        ),
                        child: TransferCard(
                          fileName: t.fileName,
                          senderDevice: t.senderDevice,
                          time: _formatTime(t.timestamp),
                          size: t.sizeFormatted,
                          isSuccess: t.status == TransferStatus.completed,
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCard(DesktopInfo desktop) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.computer_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desktop.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (desktop.isConnected)
                  Text(
                    'Connected to ${desktop.pairedDeviceName}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  const Text(
                    'No device connected',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          ConnectionBadge(
            label: desktop.isConnected ? 'Connected' : 'Disconnected',
            isConnected: desktop.isConnected,
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isTransferHovered = true),
      onExit: (_) => setState(() => _isTransferHovered = false),
      child: GestureDetector(
        onTap: () => context.goNamed(RouteNames.pairDevice),
        child: AnimatedContainer(
          duration: AppDimensions.animFast,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: _isTransferHovered
                ? AppColors.primaryGradient
                : null,
            color: _isTransferHovered ? null : AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(
              color: _isTransferHovered
                  ? AppColors.primary
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: _isTransferHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.phonelink_rounded,
                color:
                    _isTransferHovered ? Colors.white : AppColors.accent,
                size: 22,
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Text(
                'Waiting for Transfer...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      _isTransferHovered ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppStats stats) {
    return Row(
      children: [
        StatisticCard(
          label: 'Files Received',
          value: '${stats.filesReceived}',
          icon: Icons.file_copy_rounded,
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        StatisticCard(
          label: 'Devices',
          value: '${stats.devicesConnected}',
          icon: Icons.devices_rounded,
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        StatisticCard(
          label: 'Total',
          value: stats.totalTransferred,
          icon: Icons.cloud_upload_rounded,
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
