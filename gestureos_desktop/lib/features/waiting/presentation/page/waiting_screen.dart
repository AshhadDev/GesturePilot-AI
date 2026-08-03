import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/live_receiver_orb.dart';
import 'package:gestureos_desktop/core/widgets/waiting_banner.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';

class WaitingScreen extends ConsumerStatefulWidget {
  const WaitingScreen({super.key});

  @override
  ConsumerState<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends ConsumerState<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);

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
    _bgController.dispose();
    _fadeController.dispose();
    super.dispose();
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
        child: AnimatedBuilder(
          animation: _bgController,
          builder: (context, _) {
            final t = _bgController.value;
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.3 + t * 0.2),
                  radius: 1.3,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.06 + t * 0.04),
                    AppColors.background,
                  ],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.spacingXxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LiveReceiverOrb(
                        size: 240,
                        phase: snapshot.phase,
                        progress: snapshot.transferProgress,
                      ),
                      const SizedBox(height: AppDimensions.spacingXxl),
                      Text(
                        snapshot.statusText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingSm),
                      const Text(
                        'Make a gesture on your phone to start the transfer',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXl),
                      SizedBox(
                        width: 480,
                        child: WaitingBanner(
                          phase: snapshot.phase,
                          progress: snapshot.transferProgress,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXxl * 2),
                      _buildCancelButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.goNamed(RouteNames.home),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingXl,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
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
