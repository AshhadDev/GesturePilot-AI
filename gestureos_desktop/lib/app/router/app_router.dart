import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:gestureos_desktop/app/router/route_names.dart';
import 'package:gestureos_desktop/app/shell/app_shell.dart';
import 'package:gestureos_desktop/features/home/presentation/page/home_screen.dart';
import 'package:gestureos_desktop/features/pair_device/presentation/page/pair_device_screen.dart';
import 'package:gestureos_desktop/features/waiting/presentation/page/waiting_screen.dart';
import 'package:gestureos_desktop/features/transfer_progress/presentation/page/transfer_progress_screen.dart';
import 'package:gestureos_desktop/features/transfer_success/presentation/page/transfer_success_screen.dart';
import 'package:gestureos_desktop/features/transfer_history/presentation/page/transfer_history_screen.dart';
import 'package:gestureos_desktop/features/settings/presentation/page/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.homePath,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.homePath,
          name: RouteNames.home,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: RouteNames.historyPath,
          name: RouteNames.history,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: TransferHistoryScreen()),
        ),
        GoRoute(
          path: RouteNames.settingsPath,
          name: RouteNames.settings,
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.pairDevicePath,
      name: RouteNames.pairDevice,
      builder: (context, state) => const PairDeviceScreen(),
    ),
    GoRoute(
      path: RouteNames.waitingPath,
      name: RouteNames.waiting,
      builder: (context, state) => const WaitingScreen(),
    ),
    GoRoute(
      path: RouteNames.transferProgressPath,
      name: RouteNames.transferProgress,
      builder: (context, state) => const TransferProgressScreen(),
    ),
    GoRoute(
      path: RouteNames.transferSuccessPath,
      name: RouteNames.transferSuccess,
      builder: (context, state) => const TransferSuccessScreen(),
    ),
  ],
);
