import 'package:flutter/services.dart';

import 'package:logger/logger.dart';

abstract class AudioService {
  AudioService._();

  static final _logger = Logger();

  static void playPickupStart() {
    _logger.i('Audio: pickup start (placeholder)');
  }

  static void playPackingComplete() {
    _logger.i('Audio: packing complete (placeholder)');
    HapticFeedback.heavyImpact();
  }

  static void playHandDetected() {
    _logger.i('Audio: hand detected (placeholder)');
    HapticFeedback.lightImpact();
  }

  static void playFistConfirmed() {
    _logger.i('Audio: fist confirmed (placeholder)');
    HapticFeedback.mediumImpact();
  }

  static void playStateTransition() {
    _logger.i('Audio: state transition (placeholder)');
    HapticFeedback.selectionClick();
  }
}
