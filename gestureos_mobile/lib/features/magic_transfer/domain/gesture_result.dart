import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

// ---------------------------------------------------------------------------
//  Stage-2 binary rejection reason
// ---------------------------------------------------------------------------

enum RejectionReason {
  none,
  noComponent,
  tooSmall,
  badAspectRatio,
  lowExtent,
  lowSolidity,
  tooSmooth,
}

// ---------------------------------------------------------------------------
//  Per-frame contour metrics
// ---------------------------------------------------------------------------

class DetectionMetrics {
  final double contourArea;
  final double bboxWidth;
  final double bboxHeight;
  final double extent;
  final double solidity;
  final double aspectRatio;
  final double smoothness;
  final int fingerCount;

  const DetectionMetrics({
    required this.contourArea,
    required this.bboxWidth,
    required this.bboxHeight,
    required this.extent,
    required this.solidity,
    required this.aspectRatio,
    required this.smoothness,
    required this.fingerCount,
  });
}

// ---------------------------------------------------------------------------
//  Per-check breakdown for stage 3 debug
// ---------------------------------------------------------------------------

class VerificationDetail {
  final double solidityScore;
  final double circularityScore;
  final double aspectRatioScore;
  final double fillRatioScore;
  final double defectsScore;
  final double fingerCountScore;
  final double totalScore;

  const VerificationDetail({
    required this.solidityScore,
    required this.circularityScore,
    required this.aspectRatioScore,
    required this.fillRatioScore,
    required this.defectsScore,
    required this.fingerCountScore,
    required this.totalScore,
  });
}

// ---------------------------------------------------------------------------
//  Unified frame result (no state machine — pure analysis)
// ---------------------------------------------------------------------------

class GestureResult {
  final bool isHandDetected;
  final double confidence;
  final double rawConfidence;
  final double openHandScore;
  final bool stage2Passed;
  final bool stage3Passed;
  final RejectionReason rejectionReason;
  final DetectionMetrics? metrics;
  final VerificationDetail? verificationDetail;
  final int consecutiveOpenHandFrames;
  final int handLostFrames;
  final double bboxLeft;
  final double bboxTop;
  final double bboxRight;
  final double bboxBottom;
  final double normalizedHandSize;
  final int trackingId;
  final int fingerCount;
  final List<HandLandmark>? landmarks;

  const GestureResult({
    required this.isHandDetected,
    this.confidence = 0.0,
    this.rawConfidence = 0.0,
    this.openHandScore = 0.0,
    this.stage2Passed = false,
    this.stage3Passed = false,
    this.rejectionReason = RejectionReason.none,
    this.metrics,
    this.verificationDetail,
    this.consecutiveOpenHandFrames = 0,
    this.handLostFrames = 0,
    this.bboxLeft = 0.0,
    this.bboxTop = 0.0,
    this.bboxRight = 0.0,
    this.bboxBottom = 0.0,
    this.normalizedHandSize = 0.0,
    this.trackingId = 0,
    this.fingerCount = 0,
    this.landmarks,
  });
}
