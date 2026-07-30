import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';

import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/features/magic_transfer/domain/hand_landmark.dart';

// ---------------------------------------------------------------------------
//  Configurable thresholds (tune for your environment)
// ---------------------------------------------------------------------------

const double kVerificationThreshold = 0.40;        // was 0.55 — lowered so real hands pass morphology flattening
const double kOpenPalmScoreThreshold = 0.50;       // was 0.85 — lowered for testing
const double kFistScoreThreshold = 0.85;           // was 0.90
const int kOpenPalmConsecutiveRequired = 8;        // frames of stable open palm
const int kFistConsecutiveRequired = 5;            // frames of stable fist
const int kHandLostThreshold = 15;                 // frames before hand-off
const int kTrackHoldFrames = 30;                   // grace window for brief tracking gaps
const double kTrackMaxDist = 0.3;                  // normalised displacement resets ID
const int kFingerHistorySize = 5;                  // frames for mode filter

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
//  Binary grid (skin mask) – used for morphology & component analysis
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
//  Component found by flood-fill
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
//  Extracted hand features after verification
// ---------------------------------------------------------------------------

class _HandFeatures {
  final int pixelCount;
  final int boundaryCount;
  final int minX, minY, maxX, maxY;
  final double cx, cy; // grid-space centroid
  final double bboxLeft, bboxTop, bboxRight, bboxBottom; // image-space

  // Derived metrics
  final double area; // pixelCount
  final double bboxW, bboxH;
  final double perimeter; // boundaryCount
  final List<_Pt> hull; // convex hull vertices (grid-space)
  final List<double> defects; // defect depths
  final int fingerCount;
  final double solidity; // area / convexHullArea
  final double circularity; // 4πA / P²
  final double aspectRatio; // w/h
  final double fillRatio; // area / (bboxW * bboxH)

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

// ---------------------------------------------------------------------------
//  Main service – singleton
// ---------------------------------------------------------------------------

class MediapipeService {
  MediapipeService._();
  static final MediapipeService _instance = MediapipeService._();
  static MediapipeService get instance => _instance;

  // ---- MediaPipe landmark constants (kept) --------------------------------
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
  double _smoothFist = 0.0;
  static const double _emaAlpha = 0.30;

  // ---- Multi-frame validation --------------------------------------------
  int _totalProcessed = 0;
  int _handPresentFrames = 0; // frames with verified hand
  int _fistConsecutiveFrames = 0;
  int _openPalmConsecutiveFrames = 0;
  int _handLostFrames = 0;

  // ---- Tracking hold (brief gap tolerance) -------------------------------
  int _lastVerifiedFrame = 0;
  GestureResult? _lastResult;

  // ---- Tracking ID -------------------------------------------------------
  int _nextTrackingId = 1;
  int _currentTrackingId = 0;
  double _trackedCx = 0, _trackedCy = 0;

  // ---- Finger-count history for stability --------------------------------
  final _fingerHistory = <int>[];

  // ---- FPS ---------------------------------------------------------------
  int _fpsCounter = 0;
  double _currentFps = 0.0;
  int _lastFpsTick = 0;
  static const int _fpsWindow = 30;

  // ---- Public accessors --------------------------------------------------
  double get fps => _currentFps;
  int get handFrames => _handPresentFrames;
  int get fistFrames => _fistConsecutiveFrames;
  int get lostFrames => _handLostFrames;
  int get trackingId => _currentTrackingId;
  int get consecutiveOpenPalmFrames => _openPalmConsecutiveFrames;
  int get consecutiveFistFrames => _fistConsecutiveFrames;
  double get verificationScore =>
      (_handPresentFrames > 0 && _lastResult != null)
          ? _lastResult!.verificationScore
          : 0.0;

  // ========================================================================
  //  Entry point
  // ========================================================================

  GestureResult processFrame(CameraImage image) {
    _totalProcessed++;

    // Brightness adaptation (every 30 frames)
    if (_totalProcessed % 30 == 0) _adaptThresholds(image);

    // ---- Stage 1: skin classification + morphology -----------------------
    final stride = math.max(3, image.width ~/ 160);
    final grid = _classifySkin(image, stride);

    // Apply Gaussian-like blur: a simple 3x3 box filter on the grid
    final blurred = _boxBlur3(grid);

    // Morphological cleanup
    final cleaned = blurred.open().close();

    // ---- Stage 2: connected components -----------------------------------
    final comp = _findLargestComponent(cleaned, stride, image);

    // ---- Stage 3–4: feature extraction + verification --------------------
    _HandFeatures? features;
    if (comp != null) {
      features = _extractFeatures(comp, cleaned, image, stride);
    }

    bool handVerified = false;
    int fingerCount = 0;
    VerificationDetail? vDetail;
    double bL = 0, bT = 0, bR = 0, bB = 0;
    double normSize = 0.0;
    List<HandLandmark>? lms;
    double rawConf = 0.0;

    if (features != null) {
      vDetail = _computeVerificationScore(features);
      handVerified = vDetail.totalScore >= kVerificationThreshold;
    }
    final double verificationScore = vDetail?.totalScore ?? 0.0;

    // ---- Stage 5: palm / fist classification (only on verified) ----------
    bool isOpenPalm = false;
    bool isFist = false;
    double fistScore = 0.0;
    double handConf = 0.0;
    double fistConf = 0.0;
    final stableFingers = _stableFingerCount(features?.fingerCount ?? 0);

    if (handVerified && features != null) {
      fingerCount = stableFingers;
      rawConf = verificationScore;

      // Open palm: many fingers, low solidity (gaps between fingers)
      final openPalmScore = _openPalmScore(features, fingerCount);
      final fistScoreVal = _fistScoreCalc(features, fingerCount);

      isOpenPalm = openPalmScore >= kOpenPalmScoreThreshold;
      isFist = fistScoreVal >= kFistScoreThreshold;

      handConf = isOpenPalm ? openPalmScore : (isFist ? fistScoreVal : verificationScore);
      fistConf = fistScoreVal;
      fistScore = fistScoreVal;

      // Bounding box (image-space)
      bL = (features.minX * stride) / image.width;
      bT = (features.minY * stride) / image.height;
      bR = ((features.maxX + 1) * stride) / image.width;
      bB = ((features.maxY + 1) * stride) / image.height;
      normSize = (bR - bL) * (bB - bT);

      // Synthetic landmarks for orb tracking
      lms = _genLandmarks(
        cx: (features.cx * stride) / image.width,
        cy: (features.cy * stride) / image.height,
        bw: features.bboxW,
        bh: features.bboxH,
        isFist: isFist,
      );

      // Update tracking
      _updateTracking(features, image, stride);
    }

    // ---- Multi-frame validation ------------------------------------------
    final validated = _validateMultiFrame(
      handVerified: handVerified,
      isOpenPalm: isOpenPalm,
      isFist: isFist,
      confidence: handConf,
      fistScore: fistScore,
      fistConfidence: fistConf,
      verificationScore: verificationScore,
      fingerCount: fingerCount,
      landmarks: lms,
      bboxLeft: bL,
      bboxTop: bT,
      bboxRight: bR,
      bboxBottom: bB,
      normSize: normSize,
      vDetail: vDetail,
    );

    // ---- EMA smoothing ---------------------------------------------------
    if (validated.isHandDetected) {
      _smoothConf = _ema(_smoothConf, validated.confidence);
      _smoothFist = _ema(_smoothFist, validated.fistScore);
    } else {
      _smoothConf = 0;
      _smoothFist = 0;
    }

    // ---- FPS -------------------------------------------------------------
    _fpsCounter++;
    if (_fpsCounter >= _fpsWindow) {
      final now = _totalProcessed;
      _currentFps = _fpsWindow / ((now - _lastFpsTick) / 30.0);
      _lastFpsTick = now;
      _fpsCounter = 0;
    }

    return GestureResult(
      isHandDetected: validated.isHandDetected,
      isFist: validated.isFist,
      confidence: _smoothConf,
      landmarks: validated.landmarks,
      fistScore: _smoothFist,
      rawConfidence: rawConf,
      normalizedHandSize: validated.normalizedHandSize,
      bboxLeft: validated.bboxLeft,
      bboxTop: validated.bboxTop,
      bboxRight: validated.bboxRight,
      bboxBottom: validated.bboxBottom,
      isHandVerified: validated.isHandDetected,
      isOpenPalm: validated.isHandDetected && _openPalmConsecutiveFrames >= kOpenPalmConsecutiveRequired,
      fingerCount: validated.fingerCount,
      verificationScore: validated.verificationScore,
      trackingId: validated.trackingId,
      fistConfidence: validated.fistConfidence,
      verificationDetail: validated.verificationDetail,
    );
  }

  // ========================================================================
  //  Multi-frame validation
  // ========================================================================

  GestureResult _validateMultiFrame({
    required bool handVerified,
    required bool isOpenPalm,
    required bool isFist,
    required double confidence,
    required double fistScore,
    required double fistConfidence,
    required double verificationScore,
    required int fingerCount,
    required List<HandLandmark>? landmarks,
    required double bboxLeft,
    required double bboxTop,
    required double bboxRight,
    required double bboxBottom,
    required double normSize,
    required VerificationDetail? vDetail,
  }) {
    // Track hold: if hand was present but briefly lost, reuse last result
    if (!handVerified && _lastResult != null &&
        (_totalProcessed - _lastVerifiedFrame) < kTrackHoldFrames) {
      final hold = _lastResult!;
      _handLostFrames = 0;
      return GestureResult(
        isHandDetected: true,
        isFist: hold.isFist,
        confidence: hold.confidence * 0.7,
        landmarks: hold.landmarks,
        fistScore: hold.fistScore,
        rawConfidence: hold.rawConfidence,
        normalizedHandSize: hold.normalizedHandSize,
        bboxLeft: hold.bboxLeft,
        bboxTop: hold.bboxTop,
        bboxRight: hold.bboxRight,
        bboxBottom: hold.bboxBottom,
        isHandVerified: true,
        isOpenPalm: hold.isOpenPalm,
        fingerCount: hold.fingerCount,
        verificationScore: hold.verificationScore,
        trackingId: _currentTrackingId,
        fistConfidence: hold.fistConfidence,
        verificationDetail: hold.verificationDetail,
      );
    }

    if (!handVerified) {
      // Hand lost
      _handPresentFrames = 0;
      _openPalmConsecutiveFrames = 0;
      _fistConsecutiveFrames = 0;
      _handLostFrames++;
      _currentTrackingId = 0;
      _lastResult = null;
      return GestureResult(isHandDetected: false);
    }

    // Hand is verified this frame
    _handPresentFrames++;
    _handLostFrames = 0;
    _lastVerifiedFrame = _totalProcessed;

    // Open palm consecutive counting
    if (isOpenPalm) {
      _openPalmConsecutiveFrames++;
    } else {
      _openPalmConsecutiveFrames = 0;
    }

    // Fist consecutive counting
    if (isFist) {
      _fistConsecutiveFrames++;
    } else {
      _fistConsecutiveFrames = 0;
    }

    // Only report open palm after enough consecutive frames
    final bool finalOpenPalm =
        _openPalmConsecutiveFrames >= kOpenPalmConsecutiveRequired;
    final bool finalFist =
        _fistConsecutiveFrames >= kFistConsecutiveRequired;
    final bool finalHand = _handPresentFrames >= 1;

    final result = GestureResult(
      isHandDetected: finalHand,
      isFist: finalFist,
      confidence: confidence,
      landmarks: landmarks,
      fistScore: fistScore,
      rawConfidence: verificationScore,
      normalizedHandSize: normSize,
      bboxLeft: bboxLeft,
      bboxTop: bboxTop,
      bboxRight: bboxRight,
      bboxBottom: bboxBottom,
      isHandVerified: true,
      isOpenPalm: finalOpenPalm,
      fingerCount: fingerCount,
      verificationScore: verificationScore,
      trackingId: _currentTrackingId,
      fistConfidence: fistConfidence,
      verificationDetail: vDetail,
    );

    _lastResult = result;
    return result;
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
  //  3×3 box blur on grid
  // ========================================================================

  _Grid _boxBlur3(_Grid g) {
    final out = _Grid(g.w, g.h);
    for (int y = 0; y < g.h; y++) {
      for (int x = 0; x < g.w; x++) {
        int sum = 0;
        int count = 0;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            final val = g.get(x + dx, y + dy);
            sum += val;
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
        if (idx < yB.length) {
          sumY += yB[idx];
          n++;
        }
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
  //  Connected-component extraction (flood-fill)
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

          // Check if boundary pixel
          final isBoundary =
              px == 0 || g.data[py * g.w + (px - 1)] == 0 ||
              px == g.w - 1 || g.data[py * g.w + (px + 1)] == 0 ||
              py == 0 || g.data[(py - 1) * g.w + px] == 0 ||
              py == g.h - 1 || g.data[(py + 1) * g.w + px] == 0;
          if (isBoundary) {
            bnd++;
            boundary.add(_Pt(px, py));
          }

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

    // Reject extreme aspect ratios early
    final asp = bw > 0 && bh > 0 ? bw / bh : 1.0;
    if (asp < 0.25 || asp > 4.0) return null;

    // Convex hull from boundary pixels
    final hull = _convexHull(comp.boundaryPixels);

    // Compute convexity defects and finger count
    final defects = _computeDefects(comp.boundaryPixels, hull);
    final fingerCount = _countFingers(defects, bh);

    // Hull area (polygon area)
    final hullArea = _polygonArea(hull);

    // Metrics
    final area = comp.pixelCount.toDouble();
    final perimeter = comp.boundaryCount.toDouble();
    final solidity = hullArea > 0 ? area / hullArea : 0.0;
    final circularity =
        perimeter > 0 ? (4 * math.pi * area) / (perimeter * perimeter) : 0.0;
    final fillRatio =
        (bw * bh) > 0 ? area / (bw * bh) : 0.0;
    final aspectRatio = asp;

    return _HandFeatures(
      pixelCount: comp.pixelCount,
      boundaryCount: comp.boundaryCount,
      minX: comp.minX,
      minY: comp.minY,
      maxX: comp.maxX,
      maxY: comp.maxY,
      cx: comp.cx.toDouble(),
      cy: comp.cy.toDouble(),
      bboxLeft: (comp.minX * stride) / image.width,
      bboxTop: (comp.minY * stride) / image.height,
      bboxRight: ((comp.maxX + 1) * stride) / image.width,
      bboxBottom: ((comp.maxY + 1) * stride) / image.height,
      area: area,
      bboxW: bw,
      bboxH: bh,
      perimeter: perimeter,
      hull: hull,
      defects: defects,
      fingerCount: fingerCount,
      solidity: solidity,
      circularity: circularity,
      aspectRatio: aspectRatio,
      fillRatio: fillRatio,
    );
  }

  // ========================================================================
  //  Convex hull (Andrew's Monotone Chain)
  // ========================================================================

  List<_Pt> _convexHull(List<_Pt> points) {
    if (points.length < 3) return List.from(points);

    // Sort by x then y
    final sorted = List<_Pt>.from(points)
      ..sort((a, b) => a.x != b.x ? a.x - b.x : a.y - b.y);

    // Build lower hull
    final lower = <_Pt>[];
    for (final p in sorted) {
      while (lower.length >= 2 &&
          _cross(lower[lower.length - 2], lower.last, p) <= 0) {
        lower.removeLast();
      }
      lower.add(p);
    }

    // Build upper hull
    final upper = <_Pt>[];
    for (final p in sorted.reversed) {
      while (upper.length >= 2 &&
          _cross(upper[upper.length - 2], upper.last, p) <= 0) {
        upper.removeLast();
      }
      upper.add(p);
    }

    // Remove last point of each (it's the same as first of the other)
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  int _cross(_Pt o, _Pt a, _Pt b) {
    return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
  }

  // ========================================================================
  //  Convexity defects (finger valleys)
  //    For each hull edge, find the boundary point farthest from the edge.
  //    The distance (defect depth) indicates a finger valley.
  // ========================================================================

  List<double> _computeDefects(List<_Pt> boundary, List<_Pt> hull) {
    if (hull.length < 3 || boundary.isEmpty) return [];

    final defects = <double>[];
    final n = hull.length;

    for (int i = 0; i < n; i++) {
      final p1 = hull[i];
      final p2 = hull[(i + 1) % n];

      // Skip zero-length edge
      if (p1.x == p2.x && p1.y == p2.y) continue;

      // Vector from p1 to p2
      final edgeDx = p2.x - p1.x;
      final edgeDy = p2.y - p1.y;
      final edgeLenSq = edgeDx * edgeDx + edgeDy * edgeDy;
      if (edgeLenSq == 0) continue;

      double maxDist = 0;

      for (final bp in boundary) {
        // Distance from point to line segment
        final t = _clamp(
            ((bp.x - p1.x) * edgeDx + (bp.y - p1.y) * edgeDy) / edgeLenSq,
            0.0,
            1.0);
        final projX = p1.x + t * edgeDx;
        final projY = p1.y + t * edgeDy;
        final dx = bp.x - projX;
        final dy = bp.y - projY;
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist > maxDist) maxDist = dist;
      }

      // Only count significant defects
      if (maxDist > 2.5) {
        defects.add(maxDist);
      }
    }

    return defects;
  }

  double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  // ========================================================================
  //  Finger counting from convexity defects
  // ========================================================================

  int _countFingers(List<double> defects, double bboxH) {
    // Filter by relative depth
    final significant =
        defects.where((d) => d > bboxH * 0.08).toList();

    // Sort by depth descending
    significant.sort((a, b) => b.compareTo(a));

    // Take up to 5 deepest
    final top = significant.take(5).toList();

    // Number of valleys = (fingers - 1) approximately.
    // But we count: each defect = one inter-finger valley.
    // For open palm with 5 fingers: ~4 valleys.
    // For fist: 0 valleys.
    // Add 1 to get finger count, but clamp to 0-5.
    final count = top.length;
    if (count >= 4) return 5; // definitely 5 fingers
    if (count == 3) return 4; // most likely 4 fingers
    if (count == 2) return 3; // 3 fingers
    if (count == 1) return 2; // maybe 2 fingers
    return 1; // 0 or 1 finger = fist
  }

  // ========================================================================
  //  Stable finger count (history-based)
  // ========================================================================

  int _stableFingerCount(int raw) {
    _fingerHistory.add(raw);
    if (_fingerHistory.length > kFingerHistorySize) {
      _fingerHistory.removeAt(0);
    }
    if (_fingerHistory.isEmpty) return 0;
    // Return mode (most common value)
    final counts = <int, int>{};
    for (final c in _fingerHistory) {
      counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ========================================================================
  //  Hand verification score (Stage 3)
  // ========================================================================

  VerificationDetail _computeVerificationScore(_HandFeatures f) {
    // 1. Solidity (weight 0.20): peak at 0.60, gradual falloff either side
    final double rawS = f.solidity >= 0.10 && f.solidity <= 0.95
        ? 0.20 * (1.0 - (f.solidity - 0.60).abs() / 0.50).clamp(0.0, 1.0)
        : 0.0;

    // 2. Circularity (weight 0.15): peak at 0.35
    final double rawC = f.circularity >= 0.05 && f.circularity <= 0.85
        ? 0.15 * (1.0 - (f.circularity - 0.35).abs() / 0.45).clamp(0.0, 1.0)
        : 0.0;

    // 3. Aspect ratio (weight 0.15): prefer ~0.65
    final asp = f.aspectRatio > 1.0 ? 1.0 / f.aspectRatio : f.aspectRatio;
    final double rawA = asp >= 0.20
        ? 0.15 * (1.0 - (asp - 0.65).abs() / 0.65).clamp(0.0, 1.0)
        : 0.0;

    // 4. Fill ratio (weight 0.15): prefer ~0.50
    final double rawF = f.fillRatio >= 0.10 && f.fillRatio <= 0.95
        ? 0.15 * (1.0 - (f.fillRatio - 0.50).abs() / 0.50).clamp(0.0, 1.0)
        : 0.0;

    // 5. Defects (weight 0.15): 0 → 0.0, 4+ → full score
    final double rawD = 0.15 * (f.defects.length / 4.0).clamp(0.0, 1.0);

    // 6. Finger count (weight 0.20): 1-5 → full score
    final double rawG = f.fingerCount >= 1 && f.fingerCount <= 5 ? 0.20 : 0.0;

    final total = (rawS + rawC + rawA + rawF + rawD + rawG).clamp(0.0, 1.0);

    return VerificationDetail(
      solidityScore: rawS,
      circularityScore: rawC,
      aspectRatioScore: rawA,
      fillRatioScore: rawF,
      defectsScore: rawD,
      fingerCountScore: rawG,
      totalScore: total,
    );
  }

  // ========================================================================
  //  Open palm score (Stage 5)
  // ========================================================================

  double _openPalmScore(_HandFeatures f, int fingerCount) {
    // Finger count contributes but does not gate — a shape can look
    // like an open palm even when valleys are filled by morphology.
    final double fingerScore =
        fingerCount >= 4 ? 1.0 : (fingerCount >= 2 ? 0.50 : 0.20);

    // Defects = inter-finger valleys
    final double defectScore = (f.defects.length / 4.0).clamp(0.0, 1.0);

    // Low solidity means gaps between fingers
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

    // Moderate fill ratio
    final double fillScore;
    if (f.fillRatio >= 0.20 && f.fillRatio <= 0.65) {
      fillScore = 1.0;
    } else {
      fillScore = (1.0 - (f.fillRatio - 0.45).abs() / 0.45).clamp(0.0, 1.0);
    }

    // Low-to-moderate circularity (not too round)
    final double circScore;
    if (f.circularity >= 0.08 && f.circularity <= 0.45) {
      circScore = 1.0;
    } else if (f.circularity < 0.08) {
      circScore = f.circularity / 0.08;
    } else {
      circScore = ((0.75 - f.circularity) / 0.30).clamp(0.0, 1.0);
    }

    return (fingerScore * 0.20 +
            defectScore * 0.25 +
            solidityScore.clamp(0.0, 1.0) * 0.25 +
            fillScore.clamp(0.0, 1.0) * 0.15 +
            circScore.clamp(0.0, 1.0) * 0.15)
        .clamp(0.0, 1.0);
  }

  // ========================================================================
  //  Fist score (Stage 6)
  // ========================================================================

  double _fistScoreCalc(_HandFeatures f, int fingerCount) {
    // Few fingers
    if (fingerCount > 2) return 0.0;

    // High solidity (compact)
    final solidityScore =
        f.solidity >= 0.60
            ? 1.0
            : (f.solidity / 0.60).clamp(0.0, 1.0);

    // High circularity (rounded)
    final circScore =
        f.circularity >= 0.40
            ? 1.0
            : (f.circularity / 0.40).clamp(0.0, 1.0);

    // High fill ratio (fist fills bbox)
    final fillScore =
        f.fillRatio >= 0.55
            ? 1.0
            : (f.fillRatio / 0.55).clamp(0.0, 1.0);

    // Near-square aspect ratio
    final asp = f.aspectRatio > 1.0 ? 1.0 / f.aspectRatio : f.aspectRatio;
    final aspScore =
        asp >= 0.60 ? 1.0 : (asp / 0.60).clamp(0.0, 1.0);

    // Few or no defects (fingers curled)
    final defectScore =
        f.defects.isEmpty
            ? 1.0
            : (1.0 - (f.defects.length / 5.0)).clamp(0.0, 1.0);

    return (solidityScore * 0.25 +
            circScore * 0.20 +
            fillScore * 0.20 +
            aspScore * 0.15 +
            defectScore * 0.20)
        .clamp(0.0, 1.0);
  }

  // ========================================================================
  //  Tracking
  // ========================================================================

  void _updateTracking(_HandFeatures features, CameraImage image, int stride) {
    final imgCx = (features.cx * stride) / image.width;
    final imgCy = (features.cy * stride) / image.height;

    if (_currentTrackingId == 0) {
      // Start new track
      _currentTrackingId = _nextTrackingId++;
      _trackedCx = imgCx;
      _trackedCy = imgCy;
      return;
    }

    // Distance from tracked position
    final dx = imgCx - _trackedCx;
    final dy = imgCy - _trackedCy;
    final dist = math.sqrt(dx * dx + dy * dy);

    if (dist > kTrackMaxDist) {
      // Too far — new hand, reset tracking
      _currentTrackingId = _nextTrackingId++;
    }

    // Update tracked position (smooth)
    _trackedCx = _trackedCx * 0.7 + imgCx * 0.3;
    _trackedCy = _trackedCy * 0.7 + imgCy * 0.3;
  }

  // ========================================================================
  //  Utility – polygon area
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
  //  EM A
  // ========================================================================

  double _ema(double old, double v) => old * (1 - _emaAlpha) + v * _emaAlpha;

  // ========================================================================
  //  Synthetic 21-landmark generation (unchanged)
  // ========================================================================

  static List<HandLandmark> _genLandmarks({
    required double cx,
    required double cy,
    required double bw,
    required double bh,
    required bool isFist,
  }) {
    final l = <HandLandmark>[];
    l.add(HandLandmark(index: 0, x: cx, y: cy + bh * 0.35, z: 0));
    if (isFist) {
      for (int i = 1; i <= 20; i++) {
        final a = i * 0.3;
        final d = bw * 0.18;
        l.add(HandLandmark(
          index: i,
          x: (cx + math.cos(a) * d).clamp(0.0, 1.0),
          y: (cy + math.sin(a) * d * 0.5).clamp(0.0, 1.0),
          z: 0,
        ));
      }
    } else {
      for (int i = 0; i < 4; i++) {
        final t = (i + 1) / 4;
        l.add(HandLandmark(
            index: i + 1,
            x: (cx - bw * 0.35 - bw * 0.18 * t).clamp(0.0, 1.0),
            y: (cy - bh * 0.05 + bh * 0.15 * t).clamp(0.0, 1.0),
            z: 0));
      }
      for (int i = 0; i < 4; i++) {
        final t = (i + 1) / 4;
        l.add(HandLandmark(
            index: 5 + i,
            x: (cx - bw * 0.12).clamp(0.0, 1.0),
            y: (cy - bh * 0.3 - bh * 0.55 * t).clamp(0.0, 1.0),
            z: 0));
      }
      for (int i = 0; i < 4; i++) {
        final t = (i + 1) / 4;
        l.add(HandLandmark(
            index: 9 + i,
            x: cx.clamp(0.0, 1.0),
            y: (cy - bh * 0.3 - bh * 0.65 * t).clamp(0.0, 1.0),
            z: 0));
      }
      for (int i = 0; i < 4; i++) {
        final t = (i + 1) / 4;
        l.add(HandLandmark(
            index: 13 + i,
            x: (cx + bw * 0.12).clamp(0.0, 1.0),
            y: (cy - bh * 0.3 - bh * 0.55 * t).clamp(0.0, 1.0),
            z: 0));
      }
      for (int i = 0; i < 4; i++) {
        final t = (i + 1) / 4;
        l.add(HandLandmark(
            index: 17 + i,
            x: (cx + bw * 0.25).clamp(0.0, 1.0),
            y: (cy - bh * 0.25 - bh * 0.4 * t).clamp(0.0, 1.0),
            z: 0));
      }
    }
    return l;
  }
}
