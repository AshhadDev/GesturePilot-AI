import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/bottom_nav_bar.dart';
import 'package:gesture_os/core/widgets/enhanced_orb.dart';
import 'package:gesture_os/core/widgets/statistic_card.dart';
import 'package:gesture_os/core/widgets/connection_badge.dart';
import 'package:gesture_os/features/home/presentation/widgets/magic_transfer_button.dart';
import 'package:gesture_os/features/devices/presentation/page/devices_screen.dart';
import 'package:gesture_os/features/settings/presentation/page/settings_screen.dart';
import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/shared/services/clipboard_service.dart';
import 'package:gesture_os/shared/providers/connection_providers.dart';
import 'package:gesture_os/shared/services/connection_manager.dart';

/// Main dashboard screen after onboarding.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _localDeviceName;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _loadDeviceName();
    ClipboardSyncService.instance.startWatching();
  }

  Future<void> _loadDeviceName() async {
    final info = await DeviceInfoService.instance.getInfo();
    if (mounted) setState(() => _localDeviceName = info.name);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildDashboard(),
          _buildTransfers(),
          const DevicesScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildDashboard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildHeader(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildConnectionOrb(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildDesktopCard(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              sliver: SliverToBoxAdapter(
                child: const MagicTransferButton(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildStatsRow(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              sliver: SliverToBoxAdapter(
                child: _buildRecentHeader(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
              sliver: SliverToBoxAdapter(
                child: _buildNoTransfers(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransfers() {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Transfers',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            sliver: SliverToBoxAdapter(
              child: _buildNoTransfers(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'GestureOS',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopCard() {
    final snapshot = ref.watch(connectionStateProvider).value ??
        ConnectionManager.instance.currentState;
    final (label, connected, pending) = _badgeForPhase(snapshot.phase);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localDeviceName ?? 'GestureOS',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready to transfer',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ConnectionBadge(label: label, isConnected: connected, isPending: pending),
        ],
      ),
    );
  }

  Widget _buildConnectionOrb() {
    final snapshot = ref.watch(connectionStateProvider).value ??
        ConnectionManager.instance.currentState;
    final (orbState, progress) = _orbForPhase(snapshot);
    return Center(
      child: EnhancedOrb(
        size: 176,
        state: orbState,
        progress: progress,
        intensity: 0.85,
      ),
    );
  }

  (OrbState, double) _orbForPhase(ConnectionSnapshot snapshot) {
    switch (snapshot.phase) {
      case ConnectionPhase.offline:
        return (OrbState.idle, 0.0);
      case ConnectionPhase.searching:
        return (OrbState.searching, 0.0);
      case ConnectionPhase.connecting:
        return (OrbState.pairing, 0.0);
      case ConnectionPhase.connected:
        return (OrbState.connected, 0.0);
      case ConnectionPhase.receiving:
        return (OrbState.transferring, snapshot.transferProgress);
      case ConnectionPhase.completed:
        return (OrbState.completed, 1.0);
    }
  }

  (String, bool, bool) _badgeForPhase(ConnectionPhase phase) {
    switch (phase) {
      case ConnectionPhase.offline:
        return ('Standby', false, false);
      case ConnectionPhase.searching:
        return ('Searching', false, true);
      case ConnectionPhase.connecting:
        return ('Connecting', false, true);
      case ConnectionPhase.connected:
        return ('Connected', true, false);
      case ConnectionPhase.receiving:
        return ('Receiving', true, false);
      case ConnectionPhase.completed:
        return ('Completed', true, false);
    }
  }

  Widget _buildStatsRow() {
    return const Row(
      children: [
        StatisticCard(
          label: 'Files Sent',
          value: '0',
          icon: Icons.file_copy_rounded,
        ),
        SizedBox(width: 12),
        StatisticCard(
          label: 'Devices',
          value: '0',
          icon: Icons.devices_rounded,
        ),
        SizedBox(width: 12),
        StatisticCard(
          label: 'Last Transfer',
          value: '--',
          icon: Icons.schedule_rounded,
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Text(
      'Recent Transfers',
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildNoTransfers() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              'No transfers yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
