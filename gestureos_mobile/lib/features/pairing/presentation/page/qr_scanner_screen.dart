import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/qr_pairing_service.dart';
import 'package:gesture_os/shared/services/trusted_device_manager.dart';

/// Scans the desktop's pairing QR code and automatically pairs this phone
/// with the desktop over LAN. Works fully offline.
class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final raw = capture.barcodes
        .where((b) => b.rawValue != null && b.rawValue!.isNotEmpty)
        .map((b) => b.rawValue!)
        .firstOrNull;
    if (raw == null) return;

    final payload = QrPairingPayload.decode(raw);
    if (payload == null || !QrPairingService.instance.isPayloadValid(payload)) {
      setState(() => _error = 'Invalid GestureOS QR code');
      return;
    }

    _handled = true;
    QrPairingService.instance.rememberPayload(payload);

    // Store the desktop as trusted on this phone.
    await TrustedDeviceManager.instance.addOrUpdate(
      uuid: payload.desktopId,
      publicKey: payload.publicKey,
      nickname: payload.desktopName,
      platform: DevicePlatform.unknown,
      ip: payload.ip,
      port: payload.port,
      trusted: true,
    );

    if (!mounted) return;
    context.pushReplacementNamed(
      'pairing_success',
      pathParameters: {
        'deviceId': payload.desktopId,
        'deviceName': base64Url.encode(utf8.encode(payload.desktopName)),
        'deviceIp': payload.ip,
        'devicePlatform': DevicePlatform.unknown.index.toString(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                    fit: BoxFit.cover,
                  ),
                  _buildOverlay(),
                  if (_error != null) _buildErrorCard(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Scan Desktop QR',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.accent, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.25),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error!,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Point your camera at the QR code on the desktop app',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your phone and desktop will pair automatically over your local network',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
