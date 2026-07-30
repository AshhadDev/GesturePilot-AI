import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gesture_os/app/app.dart';
import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/services/network_service.dart';
import 'package:gesture_os/shared/services/transfer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF09090B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppLogger.info('GestureOS starting...');

  _initServices();

  runApp(
    const ProviderScope(
      child: GestureOSApp(),
    ),
  );
}

Future<void> _initServices() async {
  final network = NetworkService.instance;
  await network.startServer();
  network.onIncomingConnection.listen((conn) {
    TransferService.instance.handleIncomingTransfer(conn);
  });
  AppLogger.info('Network service initialized on port 48772');
}
