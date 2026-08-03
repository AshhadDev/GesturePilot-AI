import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/utils/file_utils.dart';
import 'package:gestureos_desktop/core/widgets/connect_device_button.dart';
import 'package:gestureos_desktop/core/widgets/connection_badge.dart';
import 'package:gestureos_desktop/core/widgets/desktop_app_bar.dart';
import 'package:gestureos_desktop/core/widgets/empty_state.dart';
import 'package:gestureos_desktop/core/widgets/live_receiver_orb.dart';
import 'package:gestureos_desktop/core/widgets/statistic_card.dart';
import 'package:gestureos_desktop/core/widgets/transfer_timeline_tile.dart';
import 'package:gestureos_desktop/core/widgets/waiting_banner.dart';
import 'package:gestureos_desktop/features/home/presentation/widgets/qr_pairing_dialog.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

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

  void _showQrDialog() {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.overlay,
      builder: (_) => const QrPairingDialog(),
    );
  }

  void _openTransfer(TransferHistoryItem item) {
    final path = item.filePath;
    if (path != null && path.isNotEmpty) openFileWithDefaultApp(path);
  }

  void _revealTransfer(TransferHistoryItem item) {
    final path = item.filePath;
    if (path != null && path.isNotEmpty) revealInFolder(path);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot =
        ref.watch(connectionSnapshotProvider).valueOrNull ??
            const ConnectionSnapshot(phase: ConnectionPhase.searching);
    final desktopAsync = ref.watch(desktopInfoProvider);
    final stats = ref.watch(appStatsProvider);
    final recent = ref.watch(recentTransfersProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          Column(
            children: [
              const DesktopAppBar(title: 'Home'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spacingXl,
                    AppDimensions.spacingXl,
                    AppDimensions.spacingXl,
                    120,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(snapshot, desktopAsync.valueOrNull),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      _buildOrbSection(snapshot),
                      const SizedBox(height: AppDimensions.spacingLg),
                      WaitingBanner(
                        phase: snapshot.phase,
                        progress: snapshot.transferProgress,
                      ),
                      const SizedBox(height: AppDimensions.spacingXl),
                      _buildStatsRow(stats),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      _buildRecentHeader(),
                      const SizedBox(height: AppDimensions.spacingMd),
                      if (recent.isEmpty)
                        EmptyState(
                          title: 'No transfers yet',
                          subtitle: 'Files you receive will appear here.',
                          icon: Icons.file_download_outlined,
                        )
                      else
                        ...recent.asMap().entries.map((entry) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDimensions.spacingXs,
                              ),
                              child: TransferTimelineTile(
                                item: entry.value,
                                isLast: entry.key == recent.length - 1,
                                onOpenFile: () => _openTransfer(entry.value),
                                onOpenFolder: () =>
                                    _revealTransfer(entry.value),
                              ),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: AppDimensions.spacingXl,
            bottom: AppDimensions.spacingXl,
            child: ConnectDeviceButton(onPressed: _showQrDialog),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    ConnectionSnapshot snapshot,
    DesktopInfo? info,
  ) {
    final name = info?.name ?? 'Desktop';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: snapshot.phase == ConnectionPhase.connected ||
                  snapshot.phase == ConnectionPhase.receiving ||
                  snapshot.phase == ConnectionPhase.completed
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1,
        ),
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
                const Text(
                  'Live Receiver',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ConnectionBadge(
            status: snapshot.badgeStatus,
            label: _badgeLabel(snapshot.phase),
          ),
        ],
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
        return 'Connected';
      case ConnectionPhase.receiving:
        return 'Receiving';
      case ConnectionPhase.completed:
        return 'Transfer done';
    }
  }

  Widget _buildOrbSection(ConnectionSnapshot snapshot) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
            alignment: Alignment.center,
            child: LiveReceiverOrb(
              size: 220,
              phase: snapshot.phase,
              progress: snapshot.transferProgress,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),
          AnimatedSwitcher(
            duration: AppDimensions.animNormal,
            child: Text(
              snapshot.statusText,
              key: ValueKey(snapshot.phase),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          if (snapshot.deviceName != null)
            Text(
              snapshot.deviceName!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppStats stats) {
    return Row(
      children: [
        StatisticCard(
          label: 'Files Received',
          icon: Icons.file_copy_rounded,
          animatedValue: stats.filesReceived.toDouble(),
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        StatisticCard(
          label: 'Total Data',
          icon: Icons.cloud_download_rounded,
          animatedValue: stats.totalBytes / (1024 * 1024),
          decimals: 1,
          suffix: ' MB',
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        StatisticCard(
          label: 'Avg Speed',
          icon: Icons.speed_rounded,
          value: stats.averageSpeed,
          accentColor: AppColors.accentLight,
        ),
        const SizedBox(width: AppDimensions.spacingMd),
        StatisticCard(
          label: 'Last Transfer',
          icon: Icons.schedule_rounded,
          value: stats.lastTransferAgo,
          accentColor: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Recent Transfers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.goNamed(RouteNames.history),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingSm,
                vertical: AppDimensions.spacingXs,
              ),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
