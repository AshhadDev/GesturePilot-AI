import 'dart:convert';
import 'dart:math';

import 'package:gestureos_desktop/core/services/device_info_service.dart';
import 'package:gestureos_desktop/core/utils/logger.dart';
import 'package:gestureos_desktop/shared/protocol/protocol.dart';
import 'package:gestureos_desktop/shared/services/encryption_service.dart';
import 'package:gestureos_desktop/shared/services/network_service.dart';

class QrPairingPayload {
  final int version;
  final String desktopId;
  final String desktopName;
  final String ip;
  final int port;
  final String sessionToken;
  final String publicKey;

  const QrPairingPayload({
    required this.version,
    required this.desktopId,
    required this.desktopName,
    required this.ip,
    required this.port,
    required this.sessionToken,
    required this.publicKey,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'desktopId': desktopId,
    'desktopName': desktopName,
    'ip': ip,
    'port': port,
    'sessionToken': sessionToken,
    'publicKey': publicKey,
  };

  String encode() => base64Url
      .encode(utf8.encode(json.encode(toJson())))
      .replaceAll('=', '')
      .replaceAll('+', '-')
      .replaceAll('/', '_');

  static QrPairingPayload? decode(String raw) {
    try {
      final normalized =
          raw.replaceAll('-', '+').replaceAll('_', '/');
      final padded = normalized +
          ('=' * ((4 - normalized.length % 4) % 4));
      final jsonStr = utf8.decode(base64Url.decode(padded));
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return QrPairingPayload(
        version: map['version'] as int? ?? ProtocolConstants.version,
        desktopId: map['desktopId'] as String,
        desktopName: map['desktopName'] as String? ?? '',
        ip: map['ip'] as String? ?? '',
        port: map['port'] as int? ?? 48772,
        sessionToken: map['sessionToken'] as String? ?? '',
        publicKey: map['publicKey'] as String? ?? '',
      );
    } catch (e) {
      AppLogger.warning('[QR] Decode failed: $e');
      return null;
    }
  }
}

class QrPairingService {
  QrPairingService._();
  static final QrPairingService instance = QrPairingService._();

  final Random _random = Random.secure();
  String _activeSessionToken = '';
  String _activePublicKey = '';
  String _activePrivateKey = '';
  DateTime _tokenCreatedAt = DateTime.now();

  String get activeSessionToken => _activeSessionToken;

  bool isSessionTokenValid(String token) {
    if (token.isEmpty || _activeSessionToken.isEmpty) return false;
    final age = DateTime.now().difference(_tokenCreatedAt);
    const maxAge = Duration(hours: 12);
    return token == _activeSessionToken && age < maxAge;
  }

  String rotateSessionToken() {
    _activeSessionToken =
        List.generate(32, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    _tokenCreatedAt = DateTime.now();
    AppLogger.info('[QR] New session token generated');
    return _activeSessionToken;
  }

  String rotateKeyPair() {
    final pair = EncryptionService.instance.generateKeyPair();
    _activePublicKey = pair.$1;
    _activePrivateKey = pair.$2;
    return _activePublicKey;
  }

  Future<QrPairingPayload> buildPayload() async {
    final info = await DeviceInfoService.instance.getInfo();
    if (_activeSessionToken.isEmpty) rotateSessionToken();
    if (_activePublicKey.isEmpty) rotateKeyPair();
    final port = NetworkService.instance.dataPort;
    return QrPairingPayload(
      version: ProtocolConstants.version,
      desktopId: info.id,
      desktopName: info.name,
      ip: info.ip,
      port: port,
      sessionToken: _activeSessionToken,
      publicKey: _activePublicKey,
    );
  }

  String? get activePrivateKey => _activePrivateKey;

  void clearSession() {
    _activeSessionToken = '';
    _activePublicKey = '';
    _activePrivateKey = '';
  }
}
