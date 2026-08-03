import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

// ---------------------------------------------------------------------------
//  Configurable thresholds
// ---------------------------------------------------------------------------

const double kStage3Threshold = 0.70;
const double kOpenHandEntry = 0.70;
const double kOpenHandExit = 0.55;
const int kConsecutiveRequired = 5;
const int kHandLostThreshold = 10;
const double kTrackMaxDist = 0.3;
const int kFingerHistorySize = 5;

// Stage-2 binary validation gates
const double kMinArea = 300;
const double kMinAspect = 0.35;
const double kMaxAspect = 2.85;
const double kMinExtent = 0.25;
const double kMinSolidity = 0.15;
const double kMaxSolidity = 0.95;
const double kMaxSmoothness = 60;

const double _emaAlpha = 0.30;
const int _fpsWindow = 30;

// ---------------------------------------------------------------------------
//  Point helpers
// ---------------------------------------------------------------------------

class _Pt {
  final int x, y;
  const _Pt(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is _Pt && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

// ---------------------------------------------------------------------------
//  Binary grid – morphology ops
// ---------------------------------------------------------------------------

class _Grid {
  final int w;
  final int h;
  final Uint8List data;

  _Grid(this.w, this.h) : data = Uint8List(w * h);

  int get(int x, int y) =>
      (x >= 0 && x < w && y >= 0 && y < h) ? data[y * w + x] : 0;

  void set(int x, int y, int v) {
    data[y * w + x] = v;
  }

  _Grid dilate() {
    final out = _Grid(w, h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int v = 0;
        for (int dy = -1; dy <= 1 && v == 0; dy++) {
          for (int dx = -1; dx <= 1 && v == 0; dx++) {
            if (get(x + dx, y + dy) != 0) v = 1;
          }
        }
        out.set(x, y, v);
      }
    }
    return out;
  }

  _Grid erode() {
    final out = _Grid(w, h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (get(x, y) == 0) continue;
        int all = 1;
        for (int dy = -1; dy <= 1 && all == 1; dy++) {
          for (int dx = -1; dx <= 1 && all == 1; dx++) {
            if (get(x + dx, y + dy) == 0) all = 0;
          }
        }
        out.set(x, y, all);
      }
    }
    return out;
  }

  _Grid open() => erode().dilate();
  _Grid close() => dilate().erode();
}

// ---------------------------------------------------------------------------
//  Connected component
// ---------------------------------------------------------------------------

class _Component {
  final int pixelCount;
  final int boundaryCount;
  final int minX, minY, maxX, maxY;
  final int cx, cy;
  final List<_Pt> boundaryPixels;

  _Component({
    required this.pixelCount,
    required this.boundaryCount,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.cx,
    required this.cy,
    required this.boundaryPixels,
  });
}

// ---------------------------------------------------------------------------
//  Extracted hand features
// ---------------------------------------------------------------------------

class _HandFeatures {
  final int pixelCount;
  final int boundaryCount;
  final int minX, minY, maxX, maxY;
  final double cx, cy;
  final double bboxLeft, bboxTop, bboxRight, bboxBottom;
  final double area;
  final double bboxW, bboxH;
  final double perimeter;
  final List<_Pt> hull;
  final List<double> defects;
  final int fingerCount;
  final double solidity;
  final double circularity;
  final double aspectRatio;
  final double fillRatio;

  _HandFeatures({
    required this.pixelCount,
    required this.boundaryCount,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.cx,
    required this.cy,
    required this.bboxLeft,
    required this.bboxTop,
    required this.bboxRight,
    required this.bboxBottom,
    required this.area,
    required this.bboxW,
    required this.bboxH,
    required this.perimeter,
    required this.hull,
    required this.defects,
    required this.fingerCount,
    required this.solidity,
    required this.circularity,
    required this.aspectRatio,
    required this.fillRatio,
  });
}

// ========================================================================
//  Main service – singleton (pure analysis, no state machine)
// ========================================================================

class MediapipeService {
  MediapipeService._();
  static final MediapipeService _instance = MediapipeService._();
  static MediapipeService get instance => _instance;

  // ---- MediaPipe landmark constants (kept for compatibility) --------------
  static const List<List<int>> handConnections = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [0, 9], [9, 10], [10, 11], [11, 12],
    [0, 13], [13, 14], [14, 15], [15, 16],
    [0, 17], [17, 18], [18, 19], [19, 20],
    [5, 9], [9, 13], [13, 17],
  ];
  static const List<int> fingertips = [4, 8, 12, 16, 20];

  // ---- Adaptive skin thresholds ------------------------------------------
  double _yMin = 60, _yMax = 220;
  double _uMin = 80, _uMax = 130;
  double _vMin = 125, _vMax = 180;

  // ---- EMA smoothing -----------------------------------------------------
  double _smoothConf = 0.0;
  double _smoothOpen = 0.0;

  // ---- Frame counters ----------------------------------------------------
  int _consecutiveOpenHandFrames = 0;
  int _handLostFrames = 0;

  // ---- Tracking ----------------------------------------------------------
  int _nextTrackingId = 1;
  int _currentTrackingId = 0;
  double _trackedCx = 0, _trackedCy = 0;

  // ---- Finger-count history ----------------------------------------------
  final _fingerHistory = <int>[];

  // ---- FPS ---------------------------------------------------------------
  int _fpsCounter = 0;
  double _currentFps = 0.0;
  int _lastFpsTick = 0;

  // ---- Public accessors --------------------------------------------------
  double get fps => _currentFps;
  int get consecutiveOpenHandFrames => _consecutiveOpenHandFrames;
  int get handLostFrames => _handLostFrames;

  // ========================================================================
  //  Entry point
  // ========================================================================

  GestureResult processFrame(CameraImage image) {
    if (_fpsCounter == 0) _adaptThresholds(image);

    // ---- Stage 1: skin classification + morphology -----------------------
    final stride = math.max(3, image.width ~/ 160);
    final grid = _classifySkin(image, stride);
    final blurred = _boxBlur3(grid);
    final cleaned = blurred.open().close();

    // ---- Stage 2a: connected components -----------------------------------
    final comp = _findLargestComponent(cleaned, stride, image);

    // ---- Stage 3a: feature extraction ------------------------------------
    _HandFeatures? features;
    if (comp != null) {
      features = _extractFeatures(comp, cleaned, image, stride);
    }

    // ---- Stage 2b: binary validation (hard gates) ------------------------
    final rejection = features != null
        ? _validateBinaryStage2(features)
        : RejectionReason.noComponent;
    final stage2Passed = rejection == RejectionReason.none;

    // ---- Stage 3b: weighted confidence -----------------------------------
    VerificationDetail? vDetail;
    double stage3Confidence = 0.0;
    if (stage2Passed && features != null) {
      vDetail = _computeVerificationScore(features);
      stage3Confidence = vDetail.totalScore;
    }
    final stage3Passed = stage3Confidence >= kStage3Threshold;

    // ---- Open hand score (independent, no fist) --------------------------
    double openScore = 0.0;
    int fingerCount = 0;
    if (features != null) {
      fingerCount = _stableFingerCount(features.fingerCount);
      openScore = _openPalmScore(features, fingerCount);
    }

    // ---- Frame counters with hysteresis ----------------------------------
    final bool handPresent = stage2Passed && stage3Passed && openScore >= kOpenHandExit;
    if (handPresent) {
      _handLostFrames = 0;
      if (openScore >= kOpenHandEntry) {
        _consecutiveOpenHandFrames++;
      } else if (openScore < kOpenHandExit) {
        _consecutiveOpenHandFrames = 0;
      }
    } else {
      _handLostFrames++;
      _consecutiveOpenHandFrames = 0;
    }

    final bool reliableHand = handPresent && _consecutiveOpenHandFrames >= kConsecutiveRequired;

    // ---- EMA smoothing ---------------------------------------------------
    if (handPresent) {
      _smoothConf = _ema(_smoothConf, stage3Confidence);
      _smoothOpen = _ema(_smoothOpen, openScore);
    } else {
      _smoothConf = 0;
      _smoothOpen = 0;
    }

    // ---- Build result ----------------------------------------------------
    double bL = 0, bT = 0, bR = 0, bB = 0;
    double normSize = 0.0;
    List<HandLandmark>? lms;
    if (features != null) {
      bL = features.bboxLeft;
      bT = features.bboxTop;
      bR = features.bboxRight;
      bB = features.bboxBottom;
      normSize = (bR - bL) * (bB - bT);
      lms = _genLandmarks(
        cx: (features.cx) / image.width * stride,
        cy: (features.cy) / image.height * stride,
        bw: features.bboxW,
        bh: features.bboxH,
      );
      if (reliableHand) {
        _updateTracking(features, image, stride);
      }
    }

    // ---- FPS -------------------------------------------------------------
    _fpsCounter++;
    if (_fpsCounter >= _fpsWindow) {
      final now = _fpsCounter;
      _currentFps = _fpsWindow / ((now - _lastFpsTick) / 30.0);
      _lastFpsTick = now;
      _fpsCounter = 0;
    }

    return GestureResult(
      isHandDetected: reliableHand,
      confidence: _smoothConf,
      rawConfidence: stage3Confidence,
      openHandScore: _smoothOpen,
      stage2Passed: stage2Passed,
      stage3Passed: stage3Passed,
      rejectionReason: rejection,
      metrics: features != null
          ? DetectionMetrics(
              contourArea: features.area,
              bboxWidth: features.bboxW,
              bboxHeight: features.bboxH,
              extent: features.fillRatio,
              solidity: features.solidity,
              aspectRatio: features.aspectRatio,
              smoothness: features.perimeter > 0
                  ? (features.perimeter * features.perimeter) / features.area
                  : 0,
              fingerCount: fingerCount,
            )
          : null,
      verificationDetail: vDetail,
      consecutiveOpenHandFrames: _consecutiveOpenHandFrames,
      handLostFrames: _handLostFrames,
      bboxLeft: bL,
      bboxTop: bT,
      bboxRight: bR,
      bboxBottom: bB,
      normalizedHandSize: normSize,
      trackingId: _currentTrackingId,
      fingerCount: fingerCount,
      landmarks: lms,
    );
  }

  // ========================================================================
  //  Stage 2b – binary validation (hard gates)
  // ========================================================================

  RejectionReason _validateBinaryStage2(_HandFeatures f) {
    if (f.area < kMinArea) return RejectionReason.tooSmall;
    final asp = f.aspectRatio > 1.0 ? 1.0 / f.aspectRatio : f.aspectRatio;
    if (asp < kMinAspect || asp > kMaxAspect) return RejectionReason.badAspectRatio;
    if (f.fillRatio < kMinExtent) return RejectionReason.lowExtent;
    if (f.solidity < kMinSolidity || f.solidity > kMaxSolidity) return RejectionReason.lowSolidity;
    if (f.perimeter > 0) {
      final smoothness = (f.perimeter * f.perimeter) / f.area;
      if (smoothness > kMaxSmoothness) return RejectionReason.tooSmooth;
    }
    return RejectionReason.none;
  }

  // ========================================================================
  //  Skin classification (YUV)
  // ========================================================================

  _Grid _classifySkin(CameraImage img, int stride) {
    final gw = img.width ~/ stride + 1;
    final gh = img.height ~/ stride + 1;
    final g = _Grid(gw, gh);
    final yPlane = img.planes[0];
    final uvPlane = img.planes[1];
    final yB = yPlane.bytes;
    final uvB = uvPlane.bytes;
    final yRow = yPlane.bytesPerRow;
    final uvRow = uvPlane.bytesPerRow;

    for (int gy = 0; gy < gh; gy++) {
      for (int gx = 0; gx < gw; gx++) {
        final ix = gx * stride;
        final iy = gy * stride;
        if (ix >= img.width || iy >= img.height) continue;
        final yi = iy * yRow + ix;
        if (yi >= yB.length) continue;
        final yv = yB[yi];
        final uvi = (iy >> 1) * uvRow + (ix & ~1);
        if (uvi + 1 >= uvB.length) continue;
        final vv = uvB[uvi];
        final uv = uvB[uvi + 1];
        if (_isSkin(yv, uv, vv)) g.set(gx, gy, 1);
      }
    }
    return g;
  }

  bool _isSkin(int y, int u, int v) =>
      y >= _yMin && y <= _yMax &&
      u >= _uMin && u <= _uMax &&
      v >= _vMin && v <= _vMax;

  // ========================================================================
  //  3×3 box blur
  // ========================================================================

  _Grid _boxBlur3(_Grid g) {
    final out = _Grid(g.w, g.h);
    for (int y = 0; y < g.h; y++) {
      for (int x = 0; x < g.w; x++) {
        int sum = 0;
        int count = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            sum += g.get(x + dx, y + dy);
            count++;
          }
        }
        out.set(x, y, sum > count ~/ 2 ? 1 : 0);
      }
    }
    return out;
  }

  // ========================================================================
  //  Brightness adaptation
  // ========================================================================

  void _adaptThresholds(CameraImage img) {
    final yB = img.planes[0].bytes;
    final row = img.planes[0].bytesPerRow;
    final cx = img.width >> 1, cy = img.height >> 1;
    final hw = img.width ~/ 8, hh = img.height ~/ 8;

    double sumY = 0;
    int n = 0;
    for (int y = cy - hh; y <= cy + hh; y += 3) {
      for (int x = cx - hw; x <= cx + hw; x += 3) {
        final idx = y * row + x;
        if (idx < yB.length) { sumY += yB[idx]; n++; }
      }
    }
    if (n == 0) return;
    final avg = sumY / n;

    if (avg < 80) {
      _yMin = 40;  _yMax = 200;
      _uMin = 72;  _uMax = 138;
      _vMin = 118; _vMax = 188;
    } else if (avg > 170) {
      _yMin = 85;  _yMax = 240;
      _uMin = 78;  _uMax = 132;
      _vMin = 122; _vMax = 180;
    } else {
      _yMin = 60;  _yMax = 220;
      _uMin = 80;  _uMax = 130;
      _vMin = 125; _vMax = 180;
    }
  }

  // ========================================================================
  //  Connected components
  // ========================================================================

  _Component? _findLargestComponent(_Grid g, int stride, CameraImage image) {
    final visited = Uint8List(g.w * g.h);
    _Component? best;
    int nextLabel = 1;
    final minPx = math.max(5, (g.w * g.h * 0.0008).round());

    for (int y = 0; y < g.h; y++) {
      for (int x = 0; x < g.w; x++) {
        final idx = y * g.w + x;
        if (g.data[idx] == 0 || visited[idx] != 0) continue;

        final stack = <int>[idx];
        visited[idx] = nextLabel;
        int cnt = 0, bnd = 0;
        int mnX = x, mxX = x, mnY = y, mxY = y;
        final boundary = <_Pt>[];

        while (stack.isNotEmpty) {
          final cur = stack.removeLast();
          final py = cur ~/ g.w, px = cur % g.w;
          cnt++;
          if (px < mnX) mnX = px;
          if (px > mxX) mxX = px;
          if (py < mnY) mnY = py;
          if (py > mxY) mxY = py;

          final isBoundary =
              px == 0 || g.data[py * g.w + (px - 1)] == 0 ||
              px == g.w - 1 || g.data[py * g.w + (px + 1)] == 0 ||
              py == 0 || g.data[(py - 1) * g.w + px] == 0 ||
              py == g.h - 1 || g.data[(py + 1) * g.w + px] == 0;
          if (isBoundary) { bnd++; boundary.add(_Pt(px, py)); }

          void push(int nx, int ny) {
            final nIdx = ny * g.w + nx;
            if (nx >= 0 && nx < g.w && ny >= 0 && ny < g.h &&
                g.data[nIdx] != 0 && visited[nIdx] == 0) {
              visited[nIdx] = nextLabel;
              stack.add(nIdx);
            }
          }
          push(px - 1, py);
          push(px + 1, py);
          push(px, py - 1);
          push(px, py + 1);
        }

        if (best == null || cnt > best.pixelCount) {
          if (cnt >= minPx) {
            best = _Component(
              pixelCount: cnt,
              boundaryCount: bnd,
              minX: mnX, minY: mnY,
              maxX: mxX, maxY: mxY,
              cx: (mnX + mxX) >> 1,
              cy: (mnY + mxY) >> 1,
              boundaryPixels: boundary,
            );
          }
        }
        nextLabel++;
      }
    }
    return best;
  }

  // ========================================================================
  //  Feature extraction
  // ========================================================================

  _HandFeatures? _extractFeatures(
      _Component comp, _Grid grid, CameraImage image, int stride) {
    final bw = (comp.maxX - comp.minX + 1).toDouble();
    final bh = (comp.maxY - comp.minY + 1).toDouble();
    final asp = bw > 0 && bh > 0 ? bw / bh : 1.0;
    if (asp < 0.25 || asp > 4.0) return null;

    final hull = _convexHull(comp.boundaryPixels);
    final defects = _computeDefects(comp.boundaryPixels, hull);
    final fingerCount = _countFingers(defects, bh);
    final hullArea = _polygonArea(hull);

    final area = comp.pixelCount.toDouble();
    final perimeter = comp.boundaryCount.toDouble();
    final solidity = hullArea > 0 ? area / hullArea : 0.0;
    final circularity =
        perimeter > 0 ? (4 * math.pi * area) / (perimeter * perimeter) : 0.0;
    final fillRatio = (bw * bh) > 0 ? area / (bw * bh) : 0.0;

    return _HandFeatures(
      pixelCount: comp.pixelCount,
      boundaryCount: comp.boundaryCount,
      minX: comp.minX, minY: comp.minY,
      maxX: comp.maxX, maxY: comp.maxY,
      cx: comp.cx.toDouble(), cy: comp.cy.toDouble(),
      bboxLeft: (comp.minX * stride) / image.width,
      bboxTop: (comp.minY * stride) / image.height,
      bboxRight: ((comp.maxX + 1) * stride) / image.width,
      bboxBottom: ((comp.maxY + 1) * stride) / image.height,
      area: area, bboxW: bw, bboxH: bh,
      perimeter: perimeter,
      hull: hull, defects: defects,
      fingerCount: fingerCount,
      solidity: solidity, circularity: circularity,
      aspectRatio: asp, fillRatio: fillRatio,
    );
  }

  // ========================================================================
  //  Convex hull
  // ========================================================================

  List<_Pt> _convexHull(List<_Pt> points) {
    if (points.length < 3) return List.from(points);
    final sorted = List<_Pt>.from(points)
      ..sort((a, b) => a.x != b.x ? a.x - b.x : a.y - b.y);
    final lower = <_Pt>[];
    for (final p in sorted) {
      while (lower.length >= 2 && _cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }
    final upper = <_Pt>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 && _cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  int _cross(_Pt o, _Pt a, _Pt b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }

  // ========================================================================
  //  Convexity defects
  // ========================================================================

  List<double> _computeDefects(List<_Pt> boundary, List<_Pt> hull) {
    if (hull.length < 3 || boundary.isEmpty) return [];
    final defects = <double>[];
    final n = hull.length;
    for (int i = 0; i < n; i++) {
      final p1 = hull[i];
      final p2 = hull[(i + 1) % n];
      if (p1.x == p2.x && p1.y == p2.y) continue;
      final edgeDx = p2.x - p1.x;
      final edgeDy = p2.y - p1.y;
      final edgeLenSq = edgeDx * edgeDx + edgeDy * edgeDy;
      if (edgeLenSq == 0) continue;
      double maxDist = 0;
      for (final bp in boundary) {
        final t = _clamp(
            ((bp.x - p1.x) * edgeDx + (bp.y - p1.y) * edgeDy) / edgeLenSq, 0.0, 1.0);
        final projX = p1.x + t * edgeDx;
        final projY = p1.y + t * edgeDy;
        final dx = bp.x - projX;
        final dy = bp.y - projY;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > maxDist) maxDist = dist;
      }
      if (maxDist > 2.5) defects.add(maxDist);
    }
    return defects;
  }

  double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  // ========================================================================
  //  Finger counting
  // ========================================================================

  int _countFingers(List<double> defects, double bboxH) {
    final significant = defects.where((d) => d > bboxH * 0.08).toList();
    significant.sort((a, b) => b.compareTo(a));
    final top = significant.take(5).toList();
    final count = top.length;
    if (count >= 4) return 5;
    if (count == 3) return 4;
    if (count == 2) return 3;
    if (count == 1) return 2;
    return 1;
  }

  int _stableFingerCount(int raw) {
    _fingerHistory.add(raw);
    if (_fingerHistory.length > kFingerHistorySize) _fingerHistory.removeAt(0);
    if (_fingerHistory.isEmpty) return 0;
    final counts = <int, int>{};
    for (final c in _fingerHistory) { counts[c] = (counts[c] ?? 0) + 1; }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ========================================================================
  //  Weighted confidence (Stage 3)
  // ========================================================================

  VerificationDetail _computeVerificationScore(_HandFeatures f) {
    final double rawS = f.solidity >= 0.10 && f.solidity <= 0.95
        ? 0.20 * (1.0 - (f.solidity - 0.60).abs() / 0.50).clamp(0.0, 1.0) : 0.0;
    final double rawC = f.circularity >= 0.05 && f.circularity <= 0.85
        ? 0.15 * (1.0 - (f.circularity - 0.35).abs() / 0.45).clamp(0.0, 1.0) : 0.0;
    final asp = f.aspectRatio > 1.0 ? 1.0 / f.aspectRatio : f.aspectRatio;
    final double rawA = asp >= 0.20
        ? 0.15 * (1.0 - (asp - 0.65).abs() / 0.65).clamp(0.0, 1.0) : 0.0;
    final double rawF = f.fillRatio >= 0.10 && f.fillRatio <= 0.95
        ? 0.15 * (1.0 - (f.fillRatio - 0.50).abs() / 0.50).clamp(0.0, 1.0) : 0.0;
    final double rawD = 0.15 * (f.defects.length / 4.0).clamp(0.0, 1.0);
    final double rawG = f.fingerCount >= 1 && f.fingerCount <= 5 ? 0.20 : 0.0;
    final total = (rawS + rawC + rawA + rawF + rawD + rawG).clamp(0.0, 1.0);
    return VerificationDetail(
      solidityScore: rawS, circularityScore: rawC,
      aspectRatioScore: rawA, fillRatioScore: rawF,
      defectsScore: rawD, fingerCountScore: rawG,
      totalScore: total,
    );
  }

  // ========================================================================
  //  Open palm score (independent, no fist counterpart)
  // ========================================================================

  double _openPalmScore(_HandFeatures f, int fingerCount) {
    final double fingerScore =
        fingerCount >= 4 ? 1.0 : (fingerCount >= 2 ? 0.50 : 0.20);
    final double defectScore = (f.defects.length / 4.0).clamp(0.0, 1.0);
    final double solidityScore;
    if (f.solidity >= 0.25 && f.solidity <= 0.70) {
      solidityScore = 1.0 - ((f.solidity - 0.45) / 0.25).abs();
    } else if (f.solidity > 0.70 && f.solidity <= 0.90) {
      solidityScore = (0.90 - f.solidity) / 0.20;
    } else if (f.solidity < 0.25) {
      solidityScore = f.solidity / 0.25;
    } else {
      solidityScore = 0.0;
    }
    final double fillScore;
    if (f.fillRatio >= 0.20 && f.fillRatio <= 0.65) {
      fillScore = 1.0;
    } else {
      fillScore = (1.0 - (f.fillRatio - 0.45).abs() / 0.45).clamp(0.0, 1.0);
    }
    final double circScore;
    if (f.circularity >= 0.08 && f.circularity <= 0.45) {
      circScore = 1.0;
    } else if (f.circularity < 0.08) {
      circScore = f.circularity / 0.08;
    } else {
      circScore = ((0.75 - f.circularity) / 0.30).clamp(0.0, 1.0);
    }
    return (fingerScore * 0.20 + defectScore * 0.25 +
            solidityScore.clamp(0.0, 1.0) * 0.25 +
            fillScore.clamp(0.0, 1.0) * 0.15 +
            circScore.clamp(0.0, 1.0) * 0.15)
        .clamp(0.0, 1.0);
  }

  // ========================================================================
  //  Tracking
  // ========================================================================

  void _updateTracking(_HandFeatures features, CameraImage image, int stride) {
    final imgCx = (features.cx * stride) / image.width;
    final imgCy = (features.cy * stride) / image.height;
    if (_currentTrackingId == 0) {
      _currentTrackingId = _nextTrackingId++;
      _trackedCx = imgCx;
      _trackedCy = imgCy;
      return;
    }
    final dx = imgCx - _trackedCx;
    final dy = imgCy - _trackedCy;
    if (math.sqrt(dx * dx + dy * dy) > kTrackMaxDist) {
      _currentTrackingId = _nextTrackingId++;
    }
    _trackedCx = _trackedCx * 0.7 + imgCx * 0.3;
    _trackedCy = _trackedCy * 0.7 + imgCy * 0.3;
  }

  // ========================================================================
  //  Polygon area
  // ========================================================================

  double _polygonArea(List<_Pt> pts) {
    if (pts.length < 3) return 0;
    double area = 0;
    final n = pts.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += pts[i].x * pts[j].y;
      area -= pts[j].x * pts[i].y;
    }
    return area.abs() / 2.0;
  }

  // ========================================================================
  //  EMA
  // ========================================================================

  double _ema(double old, double v) => old * (1 - _emaAlpha) + v * _emaAlpha;

  // ========================================================================
  //  Synthetic landmarks (always open-hand)
  // ========================================================================

  static List<HandLandmark> _genLandmarks({
    required double cx,
    required double cy,
    required double bw,
    required double bh,
  }) {
    final l = <HandLandmark>[];
    l.add(HandLandmark(index: 0, x: cx, y: cy + bh * 0.35, z: 0));
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      l.add(HandLandmark(
          index: i + 1,
          x: (cx - bw * 0.35 - bw * 0.18 * t).clamp(0.0, 1.0),
          y: (cy - bh * 0.05 + bh * 0.15 * t).clamp(0.0, 1.0), z: 0));
    }
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      l.add(HandLandmark(
          index: 5 + i,
          x: (cx - bw * 0.12).clamp(0.0, 1.0),
          y: (cy - bh * 0.3 - bh * 0.55 * t).clamp(0.0, 1.0), z: 0));
    }
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      l.add(HandLandmark(
          index: 9 + i,
          x: cx.clamp(0.0, 1.0),
          y: (cy - bh * 0.3 - bh * 0.65 * t).clamp(0.0, 1.0), z: 0));
    }
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      l.add(HandLandmark(
          index: 13 + i,
          x: (cx + bw * 0.12).clamp(0.0, 1.0),
          y: (cy - bh * 0.3 - bh * 0.55 * t).clamp(0.0, 1.0), z: 0));
    }
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 4;
      l.add(HandLandmark(
          index: 17 + i,
          x: (cx + bw * 0.25).clamp(0.0, 1.0),
          y: (cy - bh * 0.25 - bh * 0.4 * t).clamp(0.0, 1.0), z: 0));
    }
    return l;
  }
}
