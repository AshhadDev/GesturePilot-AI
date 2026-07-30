import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'package:gesture_os/core/utils/logger.dart';

/// Shared clipboard service for synchronizing clipboard content
/// between connected GestureOS devices.
///
/// Supported content types: text, URLs, code.
/// Transfers instantly when devices are connected and trusted.
class ClipboardSyncService {
  ClipboardSyncService._();
  static final ClipboardSyncService instance = ClipboardSyncService._();

  bool _enabled = true;
  String _lastSyncedHash = '';
  Timer? _watchTimer;
  final StreamController<ClipboardEvent> _eventController =
      StreamController<ClipboardEvent>.broadcast();

  Stream<ClipboardEvent> get events => _eventController.stream;
  bool get enabled => _enabled;

  void setEnabled(bool val) => _enabled = val;

  /// Starts watching the local clipboard for changes.
  void startWatching({Duration interval = const Duration(seconds: 2)}) {
    _watchTimer?.cancel();
    _watchTimer = Timer.periodic(interval, (_) => _checkClipboard());
    AppLogger.info('ClipboardSyncService started watching');
  }

  void stopWatching() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  Future<void> _checkClipboard() async {
    if (!_enabled) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final hash = _hashContent(text);
    if (hash == _lastSyncedHash) return;
    _lastSyncedHash = hash;
    final type = _detectType(text);
    _eventController.add(ClipboardEvent(
      type: type,
      content: text,
    ));
  }

  /// Called when clipboard content is received from a remote device.
  Future<void> onRemoteClipboard(String content) async {
    if (!_enabled) return;
    final hash = _hashContent(content);
    if (hash == _lastSyncedHash) return;
    _lastSyncedHash = hash;
    await Clipboard.setData(ClipboardData(text: content));
    AppLogger.info('Clipboard synced from remote device');
  }

  ClipboardContentType _detectType(String text) {
    if (text.startsWith('http://') || text.startsWith('https://')) {
      if (text.contains(RegExp(r'^https?://[^\s/$.?#].[^\s]*$'))) {
        return ClipboardContentType.url;
      }
    }
    if (text.contains(RegExp(r'[{}();]')) &&
        text.length > 20 &&
        text.contains(RegExp(r'(function|class|import|def|const|var|let)'))) {
      return ClipboardContentType.code;
    }
    return ClipboardContentType.text;
  }

  String _hashContent(String content) {
    return sha256.convert(utf8.encode(content)).toString();
  }

  void dispose() {
    stopWatching();
    _eventController.close();
  }
}

enum ClipboardContentType { text, url, code }

class ClipboardEvent {
  final ClipboardContentType type;
  final String content;
  const ClipboardEvent({required this.type, required this.content});
}
