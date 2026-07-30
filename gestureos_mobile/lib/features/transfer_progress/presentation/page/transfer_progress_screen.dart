import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/transfer_progress_ring.dart';
import 'package:gesture_os/shared/providers/transfer_provider.dart';

/// Transfer progress screen with real data from TransferNotifier.
class TransferProgressScreen extends ConsumerStatefulWidget {
  const TransferProgressScreen({super.key});

  @override
  ConsumerState<TransferProgressScreen> createState() =>
      _TransferProgressScreenState();
}

class _TransferProgressScreenState
    extends ConsumerState<TransferProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final transfer = ref.watch(transferProvider);
    final progress = transfer.transferProgress;
    final speed = transfer.transferSpeed.isNotEmpty
        ? transfer.transferSpeed
        : 'Connecting...';
    final remaining = transfer.remainingTime;
    final currentFile = transfer.currentFile;
    const targetName = 'Desktop';
    final isFailed = transfer.status == TransferState.failed;
    final errMsg = transfer.transferError;

    if (transfer.status == TransferState.success) {
      Future.microtask(() {
        if (mounted) context.goNamed(RouteNames.transferSuccess);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildHeader(isFailed, errMsg),
              const Spacer(flex: 2),
              _buildProgressRing(progress, isFailed),
              const Spacer(flex: 1),
              _buildFileInfo(currentFile, targetName),
              const SizedBox(height: 24),
              _buildSpeedInfo(speed, remaining),
              const Spacer(flex: 2),
              _buildControls(isFailed),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isFailed, String errMsg) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.goNamed(RouteNames.home),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        const Spacer(),
        Text(
          isFailed ? 'Transfer Failed' : 'Transferring',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isFailed ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildProgressRing(double progress, bool isFailed) {
    final percent = (progress * 100).toInt();
    return TransferProgressRing(
      progress: progress,
      size: 200,
      strokeWidth: 14,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isFailed ? '!' : '$percent%',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: isFailed ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          Text(
            isFailed ? 'Failed' : 'Complete',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfo(String currentFile, String targetName) {
    final transfer = ref.read(transferProvider);
    return Column(
      children: [
        Text(
          currentFile.isNotEmpty ? currentFile : 'Preparing...',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '${transfer.transferredSize} to $targetName',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedInfo(String speed, String remaining) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _infoChip(Icons.speed_rounded, speed),
        const SizedBox(width: 16),
        _infoChip(Icons.timer_outlined, remaining),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isFailed) {
    final notifier = ref.read(transferProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => context.goNamed(RouteNames.home),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Center(
                child: Text(
                  isFailed ? 'Dismiss' : 'Minimize',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isFailed) ...[
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                notifier.retryTransfer();
                context.goNamed(RouteNames.waitingDesktop);
              },
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
