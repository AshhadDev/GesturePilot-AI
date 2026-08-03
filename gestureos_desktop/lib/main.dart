import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestureos_desktop/app/router/app_router.dart';
import 'package:gestureos_desktop/core/theme/app_theme.dart';
import 'package:gestureos_desktop/core/utils/logger.dart';
import 'package:gestureos_desktop/shared/services/connection_manager.dart';
import 'package:gestureos_desktop/shared/services/network_service.dart';
import 'package:gestureos_desktop/shared/services/settings_service.dart';
import 'package:gestureos_desktop/shared/services/transfer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initServices();
  runApp(const ProviderScope(child: GestureOSApp()));
}

Future<void> _initServices() async {
  await SettingsService.instance.load();
  final network = NetworkService.instance;
  await network.startServer();
  network.onIncomingConnection.listen((conn) {
    TransferService.instance.handleIncomingTransfer(conn);
  });
  await ConnectionManager.instance.start();
  AppLogger.info('Network service initialized on port 48772');
}

class GestureOSApp extends StatelessWidget {
  const GestureOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GestureOS Desktop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
