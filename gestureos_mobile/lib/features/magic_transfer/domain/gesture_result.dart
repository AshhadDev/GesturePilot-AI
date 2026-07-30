import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

// ---------------------------------------------------------------------------
//  Per-check breakdown for debugging
// ---------------------------------------------------------------------------

class VerificationDetail {
  final double solidityScore;   // 0.00 – 0.20
  final double circularityScore; // 0.00 – 0.15
  final double aspectRatioScore; // 0.00 – 0.15
  final double fillRatioScore;   // 0.00 – 0.15
  final double defectsScore;     // 0.00 – 0.15
  final double fingerCountScore; // 0.00 – 0.20
  final double totalScore;       // 0.00 – 1.00

  const VerificationDetail({
    required this.solidityScore,
    required this.circularityScore,
    required this.aspectRatioScore,
    required this.fillRatioScore,
    required this.defectsScore,
    required this.fingerCountScore,
    required this.totalScore,
  });

  bool get isSolidityPass => solidityScore >= 0.10;
  bool get isCircularityPass => circularityScore >= 0.075;
  bool get isAspectRatioPass => aspectRatioScore >= 0.075;
  bool get isFillRatioPass => fillRatioScore >= 0.075;
  bool get isDefectsPass => defectsScore >= 0.075;
  bool get isFingerCountPass => fingerCountScore >= 0.10;
}

class GestureResult {
  final bool isHandDetected;
  final bool isFist;
  final double confidence;
  final List<HandLandmark>? landmarks;
  final double fistScore;
  final double rawConfidence;
  final double normalizedHandSize;
  final double bboxLeft;
  final double bboxTop;
  final double bboxRight;
  final double bboxBottom;

  // ---- Multi-stage pipeline fields ----
  final bool isHandVerified;
  final bool isOpenPalm;
  final int fingerCount;
  final double verificationScore;
  final int trackingId;
  final double fistConfidence;

  // ---- Per-check verification detail (debug) ----
  final VerificationDetail? verificationDetail;

  const GestureResult({
    required this.isHandDetected,
    this.isFist = false,
    this.confidence = 0.0,
    this.landmarks,
    this.fistScore = 0.0,
    this.rawConfidence = 0.0,
    this.normalizedHandSize = 0.0,
    this.bboxLeft = 0.0,
    this.bboxTop = 0.0,
    this.bboxRight = 0.0,
    this.bboxBottom = 0.0,
    this.isHandVerified = false,
    this.isOpenPalm = false,
    this.fingerCount = 0,
    this.verificationScore = 0.0,
    this.trackingId = 0,
    this.fistConfidence = 0.0,
    this.verificationDetail,
  });
}
