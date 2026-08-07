import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/protocol/frame_parser.dart';
import 'package:gesture_os/shared/protocol/protocol.dart';
import 'package:gesture_os/shared/services/network_service.dart';
import 'package:gesture_os/shared/services/qr_pairing_service.dart';

/// Shown after a successful QR scan. Confirms the desktop is trusted and
/// completes the reciprocal handshake so the desktop also trusts this phone.
class QrPairingResultScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceIp;
  final int devicePlatform;

  const QrPairingResultScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceIp,
    required this.devicePlatform,
  });

  @override
  ConsumerState<QrPairingResultScreen> createState() =>
      _QrPairingResultScreenState();
}

class _QrPairingResultScreenState extends ConsumerState<QrPairingResultScreen> {
  bool _handshaking = true;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    // Defer network work out of initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _completePairing();
    });
  }

  Future<void> _completePairing() async {
    final payload = QrPairingService.instance.lastPayload;
    final port = payload?.port ?? 48772;
    final conn =
        await NetworkService.instance.connect(widget.deviceIp, port: port);
    if (conn == null) {
      setState(() {
        _handshaking = false;
        _connected = false;
      });
      return;
    }

    try {
      final parser = FrameParser(conn);
      parser.start();
      final info = await DeviceInfoService.instance.getInfo();
      parser.sendJson(MessageType.hello, DateTime.now().microsecondsSinceEpoch, {
        'device_name': info.name,
        'protocol_version': ProtocolConstants.version,
        if (payload != null) 'device_id': info.id,
        if (payload != null) 'session_token': payload.sessionToken,
      });
      final reply = await parser.waitForFrame(
        MessageType.hello,
        timeout: const Duration(seconds: 8),
      );
      parser.close();
      NetworkService.instance.disconnect(conn.id);
      if (mounted) {
        setState(() {
          _handshaking = false;
          _connected = reply != null;
        });
      }
    } catch (_) {
      NetworkService.instance.disconnect(conn.id);
      if (mounted) {
        setState(() {
          _handshaking = false;
          _connected = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: _handshaking
                    ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        _connected
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
              ),
              const SizedBox(height: 28),
              Text(
                _handshaking
                    ? 'Pairing with ${widget.deviceName}...'
                    : (_connected
                        ? 'Connected!'
                        : 'Saved to trusted devices'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _handshaking
                    ? 'Establishing a secure channel on your local network'
                    : (_connected
                        ? 'Your phone and desktop are now paired and can '
                            'transfer files automatically'
                        : 'The desktop was added to your trusted devices. '
                            'Reconnect when it is online.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 2),
              if (!_handshaking)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      QrPairingService.instance.clearSession();
                      context.goNamed('home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _connected ? 'Start Transferring' : 'Back to Home',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
