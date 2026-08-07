import 'dart:convert';

import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/protocol/protocol.dart';

/// Payload encoded in the desktop's pairing QR code. Mirrors the desktop
/// [QrPairingPayload] so LAN pairing works fully offline.
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

/// Handles a scanned desktop QR payload: validates it, stores the desktop as
/// a trusted device, and remembers the active session token for the
/// handshake so the desktop reciprocates trust on its side.
class QrPairingService {
  QrPairingService._();
  static final QrPairingService instance = QrPairingService._();

  QrPairingPayload? _lastPayload;

  QrPairingPayload? get lastPayload => _lastPayload;

  /// Validates the payload is well-formed enough to initiate pairing.
  bool isPayloadValid(QrPairingPayload payload) {
    if (payload.desktopId.isEmpty) return false;
    if (payload.ip.isEmpty) return false;
    if (payload.sessionToken.isEmpty) return false;
    return payload.port > 0;
  }

  void rememberPayload(QrPairingPayload payload) {
    _lastPayload = payload;
  }

  void clearSession() {
    _lastPayload = null;
  }
}
