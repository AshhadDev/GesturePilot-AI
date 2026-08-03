import 'dart:io';

import 'package:gestureos_desktop/core/utils/logger.dart';

Future<void> openFileWithDefaultApp(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else {
      await Process.run('xdg-open', [path]);
    }
  } catch (e) {
    AppLogger.warning('[Files] Failed to open file: $e');
  }
}

Future<void> revealInFolder(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  } catch (e) {
    AppLogger.warning('[Files] Failed to reveal in folder: $e');
  }
}
