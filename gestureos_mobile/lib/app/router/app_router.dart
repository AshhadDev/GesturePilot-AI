import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/features/onboarding/presentation/page/onboarding_screen.dart';
import 'package:gesture_os/features/splash/presentation/page/splash_screen.dart';
import 'package:gesture_os/features/home/presentation/page/home_screen.dart';
import 'package:gesture_os/features/file_selection/presentation/page/file_selection_screen.dart';
import 'package:gesture_os/features/magic_transfer/presentation/page/magic_transfer_screen.dart';
import 'package:gesture_os/features/carrying/presentation/page/carrying_screen.dart';
import 'package:gesture_os/features/waiting_desktop/presentation/page/waiting_desktop_screen.dart';
import 'package:gesture_os/features/transfer_progress/presentation/page/transfer_progress_screen.dart';
import 'package:gesture_os/features/receiver/presentation/page/receiver_screen.dart';
import 'package:gesture_os/features/transfer_success/presentation/page/transfer_success_screen.dart';
import 'package:gesture_os/features/devices/presentation/page/devices_screen.dart';
import 'package:gesture_os/features/devices/presentation/page/devices_detail_screen.dart';
import 'package:gesture_os/features/settings/presentation/page/settings_screen.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/features/performance/presentation/page/performance_dashboard_screen.dart';
import 'package:gesture_os/features/history/presentation/page/transfer_history_screen.dart';
import 'package:gesture_os/features/pairing/presentation/page/pairing_screen.dart';

/// Centralized GoRouter configuration for GestureOS.
/// Handles all app navigation with smooth page transitions.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: RoutePaths.splash,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.onboarding,
        path: RoutePaths.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.home,
        path: RoutePaths.home,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.fileSelection,
        path: RoutePaths.fileSelection,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const FileSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.3, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.magicTransfer,
        path: RoutePaths.magicTransfer,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const MagicTransferScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.carrying,
        path: RoutePaths.carrying,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CarryingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.waitingDesktop,
        path: RoutePaths.waitingDesktop,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const WaitingDesktopScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.transferProgress,
        path: RoutePaths.transferProgress,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransferProgressScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(opacity: curved, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.receiver,
        path: RoutePaths.receiver,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ReceiverScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.transferSuccess,
        path: RoutePaths.transferSuccess,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransferSuccessScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.devices,
        path: RoutePaths.devices,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const DevicesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.settings,
        path: RoutePaths.settings,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
      GoRoute(
        name: RouteNames.performanceDashboard,
        path: RoutePaths.performanceDashboard,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PerformanceDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.transferHistory,
        path: RoutePaths.transferHistory,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TransferHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        name: RouteNames.deviceDetail,
        path: RoutePaths.deviceDetail,
        pageBuilder: (context, state) {
          final deviceId = state.pathParameters['deviceId'] ?? '';
          final deviceName = utf8.decode(base64.decode(state.pathParameters['deviceName'] ?? ''));
          final deviceIp = state.pathParameters['deviceIp'] ?? '';
          final devicePlatform = int.tryParse(state.pathParameters['devicePlatform'] ?? '0') ?? 0;
          final devicePort = int.tryParse(state.pathParameters['devicePort'] ?? '48771') ?? 48771;
          final isTrusted = state.pathParameters['isTrusted'] == 'true';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: DevicesDetailScreen(
              device: Device(
                id: deviceId,
                name: deviceName,
                ip: deviceIp,
                port: devicePort,
                platform: DevicePlatform.values[devicePlatform],
                lastSeen: DateTime.now(),
                isTrusted: isTrusted,
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        name: RouteNames.pairing,
        path: RoutePaths.pairing,
        pageBuilder: (context, state) {
          final deviceId = state.pathParameters['deviceId'] ?? '';
          final deviceName = utf8.decode(base64.decode(state.pathParameters['deviceName'] ?? ''));
          final deviceIp = state.pathParameters['deviceIp'] ?? '';
          final devicePlatform = int.tryParse(state.pathParameters['devicePlatform'] ?? '0') ?? 0;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: PairingScreen(
              deviceId: deviceId,
              deviceName: deviceName,
              deviceIp: deviceIp,
              devicePlatform: devicePlatform,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
    ],
  );
}
