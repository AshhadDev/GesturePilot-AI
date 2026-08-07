import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/providers/production_providers.dart';
import 'package:gesture_os/shared/services/pairing_service.dart';
import 'package:gesture_os/shared/services/trusted_device_manager.dart';

class PairingScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;
  final String deviceIp;
  final int devicePlatform;

  const PairingScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.deviceIp,
    required this.devicePlatform,
  });

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  StreamSubscription<PairingEvent>? _sub;
  final _codeController = TextEditingController();
  bool _codeEntered = false;
  bool _pairingComplete = false;
  String _localCode = '';

  @override
  void initState() {
    super.initState();
    _localCode = PairingService.instance.generateVerificationCode();
    // Defer provider mutation out of initState to avoid modifying a provider
    // while the widget tree is building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pairingVerificationCodeProvider.notifier).state = _localCode;
      }
    });

    PairingService.instance.startPairing(
      Device(
        id: widget.deviceId,
        name: widget.deviceName,
        ip: widget.deviceIp,
        platform: DevicePlatform.values[widget.devicePlatform],
        lastSeen: DateTime.now(),
      ),
    );

    _sub = PairingService.instance.events.listen((event) {
      if (event.step == PairingStep.paired && mounted) {
        setState(() => _pairingComplete = true);
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.pop(true);
        });
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = ref.watch(pairingVerificationCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pair with ${widget.deviceName}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verify the code matches on both devices',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (code != null && !_pairingComplete)
                Column(
                  children: [
                    Text(
                      'Your Code',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter this code on ${widget.deviceName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              if (_pairingComplete)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 64,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Paired Successfully!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              const Spacer(flex: 2),
              if (!_pairingComplete)
                Column(
                  children: [
                    Text(
                      'Enter code shown on ${widget.deviceName}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: AppColors.textPrimary,
                          letterSpacing: 6,
                          fontWeight: FontWeight.w700,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary.withValues(alpha: 0.3),
                            fontSize: 24,
                            letterSpacing: 6,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (v) {
                          setState(() => _codeEntered = v.length == 6);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _codeEntered ? _verifyCode : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _codeEntered
                              ? AppColors.primaryGradient
                              : LinearGradient(
                                  colors: [AppColors.card, AppColors.card]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _codeEntered
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Verify & Pair',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _codeEntered
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        PairingService.instance.rejectPairing(
                            widget.deviceId);
                        context.pop();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyCode() {
    final entered = _codeController.text.trim();
    if (entered == _localCode) {
      PairingService.instance.verifyCode(entered);
      PairingService.instance.completePairing(
        deviceId: widget.deviceId,
        remotePublicKey: PairingService.instance.localPublicKey,
        deviceName: widget.deviceName,
        platform: DevicePlatform.values[widget.devicePlatform],
        ip: widget.deviceIp,
      );
      TrustedDeviceManager.instance.addOrUpdate(
        uuid: widget.deviceId,
        publicKey: PairingService.instance.localPublicKey,
        nickname: widget.deviceName,
        platform: DevicePlatform.values[widget.devicePlatform],
        ip: widget.deviceIp,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Code mismatch. Try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
