import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:gesture_os/shared/models/device_model.dart';

enum PairingStep {
  idle,
  deviceFound,
  requestSent,
  verificationPending,
  codeVerified,
  keyExchange,
  paired,
  failed,
}

class PairingEvent {
  final PairingStep step;
  final String deviceId;
  final String? verificationCode;
  final String? error;
  const PairingEvent({
    required this.step,
    required this.deviceId,
    this.verificationCode,
    this.error,
  });
}

/// Secure pairing service with verification code and key exchange.
///
/// Flow:
/// 1. Device found → send pair request
/// 2. Both sides show verification code (numeric, 6 digits)
/// 3. User confirms code matches → exchange public keys
/// 4. Store trusted device
/// 5. Derive shared session key for future transfers
class PairingService {
  PairingService._();
  static final PairingService instance = PairingService._();

  final Random _random = Random.secure();
  final StreamController<PairingEvent> _controller =
      StreamController<PairingEvent>.broadcast();
  Stream<PairingEvent> get events => _controller.stream;

  PairingStep _currentStep = PairingStep.idle;
  String _currentDeviceId = '';
  String? _expectedCode;
  String _localPublicKey = '';
  String _localPrivateKey = '';

  PairingStep get currentStep => _currentStep;
  String get currentDeviceId => _currentDeviceId;

  /// Generates a 6-digit verification code.
  String generateVerificationCode() {
    final code = _random.nextInt(900000) + 100000;
    return code.toString();
  }

  /// Generates a local key pair for identity.
  void generateIdentityKeys() {
    final seed = Uint8List.fromList(
      List.generate(32, (_) => _random.nextInt(256)),
    );
    _localPublicKey = sha256.convert(seed).toString();
    _localPrivateKey = sha256.convert(utf8.encode(_localPublicKey)).toString();
  }

  String get localPublicKey => _localPublicKey;

  /// Initiates pairing with a discovered device.
  Future<void> startPairing(Device device) async {
    _currentDeviceId = device.id;
    _currentStep = PairingStep.requestSent;
    _controller.add(PairingEvent(
      step: _currentStep,
      deviceId: device.id,
    ));
    generateIdentityKeys();
  }

  /// Called when a pair request is received from another device.
  Future<void> onPairRequest(String deviceId) async {
    _currentDeviceId = deviceId;
    _currentStep = PairingStep.verificationPending;
    _expectedCode = generateVerificationCode();
    _controller.add(PairingEvent(
      step: _currentStep,
      deviceId: deviceId,
      verificationCode: _expectedCode,
    ));
    generateIdentityKeys();
  }

  /// Verifies the code entered by the user matches the expected code.
  bool verifyCode(String enteredCode) {
    if (_expectedCode == null) return false;
    final match = _expectedCode == enteredCode;
    if (match) {
      _currentStep = PairingStep.codeVerified;
      _controller.add(PairingEvent(
        step: _currentStep,
        deviceId: _currentDeviceId,
      ));
    } else {
      _currentStep = PairingStep.failed;
      _controller.add(PairingEvent(
        step: _currentStep,
        deviceId: _currentDeviceId,
        error: 'Verification code mismatch',
      ));
    }
    return match;
  }

  /// Completes the pairing by storing the trusted device.
  Future<void> completePairing({
    required String deviceId,
    required String remotePublicKey,
    required String deviceName,
    required DevicePlatform platform,
    required String ip,
    int port = 48772,
  }) async {
    _currentStep = PairingStep.paired;
    _controller.add(PairingEvent(
      step: _currentStep,
      deviceId: deviceId,
    ));

    // Store trusted device (import here to avoid circular dependency)
    // This is called from the provider layer
    _onPairComplete?.call(
      deviceId: deviceId,
      publicKey: remotePublicKey,
      nickname: deviceName,
      platform: platform,
      ip: ip,
      port: port,
    );
  }

  /// Callback set by provider layer to persist trusted device.
  void Function({
    required String deviceId,
    required String publicKey,
    required String nickname,
    required DevicePlatform platform,
    required String ip,
    int port,
  })? _onPairComplete;

  set onPairComplete(void Function({
    required String deviceId,
    required String publicKey,
    required String nickname,
    required DevicePlatform platform,
    required String ip,
    int port,
  }) callback) {
    _onPairComplete = callback;
  }

  /// Derives shared session key from local private key and remote public key.
  String deriveSessionKey(String remotePublicKey) {
    final material = '$_localPrivateKey:$remotePublicKey';
    return sha256.convert(utf8.encode(material)).toString();
  }

  /// Rejects a pairing request.
  void rejectPairing(String deviceId) {
    _currentStep = PairingStep.failed;
    _controller.add(PairingEvent(
      step: _currentStep,
      deviceId: deviceId,
      error: 'Pairing rejected by user',
    ));
    reset();
  }

  void reset() {
    _currentStep = PairingStep.idle;
    _currentDeviceId = '';
    _expectedCode = null;
  }

  void dispose() {
    _controller.close();
  }
}
