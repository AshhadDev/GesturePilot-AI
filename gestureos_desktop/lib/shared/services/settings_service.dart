import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestureos_desktop/shared/services/transfer_receiver.dart';

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _keyAutoDiscover = 'gestureos_auto_discover';
  static const _keyAutoAccept = 'gestureos_auto_accept_trusted';
  static const _keyClipboardSync = 'gestureos_clipboard_sync';
  static const _keyTheme = 'gestureos_theme';
  static const _keyAnimationQuality = 'gestureos_animation_quality';
  static const _keyGestureSensitivity = 'gestureos_gesture_sensitivity';
  static const _keyDebugMode = 'gestureos_debug_mode';
  static const _keyTransferFolder = 'gestureos_transfer_folder';
  static const _keyDiscoveryVisible = 'gestureos_discovery_visible';
  static const _keyAutoOpenFiles = 'gestureos_auto_open_files';
  static const _keyEnableQr = 'gestureos_enable_qr';
  static const _keyConnectionTimeout = 'gestureos_connection_timeout';
  static const _keyTransferNotification = 'gestureos_transfer_notification';
  static const _keyTransferSound = 'gestureos_transfer_sound';
  static const _keyDesktopName = 'gestureos_desktop_name';

  bool _loaded = false;
  bool _autoDiscover = true;
  bool _autoAcceptTrusted = false;
  bool _clipboardSync = false;
  String _theme = 'dark';
  String _animationQuality = 'high';
  double _gestureSensitivity = 0.5;
  bool _debugMode = false;
  String _transferFolder = '';
  bool _discoveryVisible = true;
  bool _autoOpenFiles = false;
  bool _enableQr = true;
  int _connectionTimeout = 30;
  bool _transferNotification = true;
  bool _transferSound = true;
  String _desktopName = 'My Desktop';

  bool get autoDiscover => _autoDiscover;
  bool get autoAcceptTrusted => _autoAcceptTrusted;
  bool get clipboardSync => _clipboardSync;
  String get theme => _theme;
  String get animationQuality => _animationQuality;
  double get gestureSensitivity => _gestureSensitivity;
  bool get debugMode => _debugMode;
  String get transferFolder => _transferFolder;
  bool get discoveryVisible => _discoveryVisible;
  bool get autoOpenFiles => _autoOpenFiles;
  bool get enableQr => _enableQr;
  int get connectionTimeout => _connectionTimeout;
  bool get transferNotification => _transferNotification;
  bool get transferSound => _transferSound;
  String get desktopName => _desktopName;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _autoDiscover = prefs.getBool(_keyAutoDiscover) ?? true;
    _autoAcceptTrusted = prefs.getBool(_keyAutoAccept) ?? false;
    _clipboardSync = prefs.getBool(_keyClipboardSync) ?? false;
    _theme = prefs.getString(_keyTheme) ?? 'dark';
    _animationQuality = prefs.getString(_keyAnimationQuality) ?? 'high';
    _gestureSensitivity = prefs.getDouble(_keyGestureSensitivity) ?? 0.5;
    _debugMode = prefs.getBool(_keyDebugMode) ?? false;
    _transferFolder = prefs.getString(_keyTransferFolder) ?? '';
    _discoveryVisible = prefs.getBool(_keyDiscoveryVisible) ?? true;
    _autoOpenFiles = prefs.getBool(_keyAutoOpenFiles) ?? false;
    _enableQr = prefs.getBool(_keyEnableQr) ?? true;
    _connectionTimeout = prefs.getInt(_keyConnectionTimeout) ?? 30;
    _transferNotification = prefs.getBool(_keyTransferNotification) ?? true;
    _transferSound = prefs.getBool(_keyTransferSound) ?? true;
    _desktopName = prefs.getString(_keyDesktopName) ?? 'My Desktop';
    _loaded = true;

    TransferReceiver.autoAcceptTrusted = _autoAcceptTrusted;
  }

  Future<void> setAutoDiscover(bool v) async {
    _autoDiscover = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDiscover, v);
  }

  Future<void> setAutoAcceptTrusted(bool v) async {
    _autoAcceptTrusted = v;
    TransferReceiver.autoAcceptTrusted = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoAccept, v);
  }

  Future<void> setClipboardSync(bool v) async {
    _clipboardSync = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyClipboardSync, v);
  }

  Future<void> setTheme(String v) async {
    _theme = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, v);
  }

  Future<void> setAnimationQuality(String v) async {
    _animationQuality = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAnimationQuality, v);
  }

  Future<void> setGestureSensitivity(double v) async {
    _gestureSensitivity = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyGestureSensitivity, v);
  }

  Future<void> setDebugMode(bool v) async {
    _debugMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDebugMode, v);
  }

  Future<void> setTransferFolder(String v) async {
    _transferFolder = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTransferFolder, v);
  }

  Future<void> setDiscoveryVisible(bool v) async {
    _discoveryVisible = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDiscoveryVisible, v);
  }

  Future<void> setAutoOpenFiles(bool v) async {
    _autoOpenFiles = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoOpenFiles, v);
  }

  Future<void> setEnableQr(bool v) async {
    _enableQr = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnableQr, v);
  }

  Future<void> setConnectionTimeout(int seconds) async {
    _connectionTimeout = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyConnectionTimeout, seconds);
  }

  Future<void> setTransferNotification(bool v) async {
    _transferNotification = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTransferNotification, v);
  }

  Future<void> setTransferSound(bool v) async {
    _transferSound = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTransferSound, v);
  }

  Future<void> setDesktopName(String v) async {
    _desktopName = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDesktopName, v);
  }
}
