import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  static const int _nonceLength = 12;
  static const int _tagLength = 16;

  final Map<String, Uint8List> _sessionKeys = {};
  final Set<String> _usedNonces = {};
  final Random _random = Random.secure();

  (String, String) generateKeyPair() {
    final seed = Uint8List.fromList(
      List.generate(32, (_) => _random.nextInt(256)),
    );
    final publicKey = sha256.convert(seed).toString();
    final privateKey = sha256.convert(utf8.encode(publicKey)).toString();
    return (publicKey, privateKey);
  }

  Uint8List deriveSessionKey(String localPrivateKey, String remotePublicKey) {
    final material = '$localPrivateKey:$remotePublicKey';
    final hash = sha256.convert(utf8.encode(material));
    return Uint8List.fromList(hash.bytes);
  }

  Uint8List? getSessionKey(String transferId) => _sessionKeys[transferId];

  void setSessionKey(String transferId, Uint8List key) {
    _sessionKeys[transferId] = key;
  }

  (Uint8List, Uint8List) encrypt(String transferId, Uint8List plaintext) {
    final key = _sessionKeys[transferId];
    if (key == null) {
      throw StateError('No session key for transfer $transferId');
    }

    final nonce = Uint8List.fromList(
      List.generate(_nonceLength, (_) => _random.nextInt(256)),
    );
    _usedNonces.add(base64.encode(nonce));

    final streamKey = _deriveStreamKey(key, nonce);
    final ciphertext = Uint8List(plaintext.length);
    for (int i = 0; i < plaintext.length; i++) {
      ciphertext[i] = plaintext[i] ^ streamKey[i % streamKey.length];
    }

    final hmac = Hmac(sha256, key);
    final tag = hmac.convert(Uint8List.fromList([...nonce, ...ciphertext]));
    final authTag = Uint8List.fromList(tag.bytes.take(_tagLength).toList());

    return (Uint8List.fromList([...nonce, ...ciphertext, ...authTag]),
        authTag);
  }

  Uint8List decrypt(String transferId, Uint8List data) {
    final key = _sessionKeys[transferId];
    if (key == null) {
      throw StateError('No session key for transfer $transferId');
    }

    if (data.length < _nonceLength + _tagLength) {
      throw ArgumentError('Data too short for GCM structure');
    }

    final nonce = data.sublist(0, _nonceLength);
    final tag = data.sublist(data.length - _tagLength);
    final ciphertext = data.sublist(_nonceLength, data.length - _tagLength);

    final nonceB64 = base64.encode(nonce);
    if (_usedNonces.contains(nonceB64)) {
      throw StateError('Replay attack detected: nonce already used');
    }
    _usedNonces.add(nonceB64);

    final hmac = Hmac(sha256, key);
    final expectedTag =
        hmac.convert(Uint8List.fromList([...nonce, ...ciphertext]));
    final expectedBytes = Uint8List.fromList(expectedTag.bytes.take(_tagLength).toList());
    if (!_constantTimeEquals(tag, expectedBytes)) {
      throw StateError('Authentication tag mismatch - data tampered');
    }

    final streamKey = _deriveStreamKey(key, nonce);
    final plaintext = Uint8List(ciphertext.length);
    for (int i = 0; i < ciphertext.length; i++) {
      plaintext[i] = ciphertext[i] ^ streamKey[i % streamKey.length];
    }

    return plaintext;
  }

  Uint8List _deriveStreamKey(Uint8List key, Uint8List nonce) {
    final material = Uint8List.fromList([...key, ...nonce]);
    final hash = sha256.convert(material);
    return Uint8List.fromList(hash.bytes);
  }

  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  void clearSessionKey(String transferId) {
    _sessionKeys.remove(transferId);
  }

  void clearAllSessions() {
    _sessionKeys.clear();
  }
}
