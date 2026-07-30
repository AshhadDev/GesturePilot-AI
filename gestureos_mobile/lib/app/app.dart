import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/app/router/app_router.dart';
import 'package:gesture_os/core/theme/app_theme.dart';

/// Root application widget for GestureOS.
/// Wraps the app in [ProviderScope] for Riverpod and configures
/// Material 3 dark theme with GoRouter navigation.
class GestureOSApp extends StatelessWidget {
  const GestureOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GestureOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
