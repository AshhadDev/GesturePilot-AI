import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/data/camera_service.dart';
import 'package:gesture_os/features/magic_transfer/data/mediapipe_service.dart';
import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/gesture_debug_panel.dart';
import 'package:gesture_os/features/magic_transfer/presentation/widgets/hand_skeleton_overlay.dart';

class CameraPreviewWidget extends StatefulWidget {
  final double height;
  final bool showGlow;
  final bool debugMode;
  final String currentStateLabel;
  final void Function(GestureResult)? onHandDetected;
  final VoidCallback? onHandLost;
  final void Function(GestureResult)? onFistDetected;
  final VoidCallback? onFistLost;
  final void Function(double)? onConfidenceUpdate;
  final void Function(double, double)? onHandPosition;

  const CameraPreviewWidget({
    super.key,
    this.height = 160,
    this.showGlow = false,
    this.debugMode = false,
    this.currentStateLabel = 'idle',
    this.onHandDetected,
    this.onHandLost,
    this.onFistDetected,
    this.onFistLost,
    this.onConfidenceUpdate,
    this.onHandPosition,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget>
    with WidgetsBindingObserver {
  final _cameraService = CameraService.instance;
  final _service = MediapipeService.instance;
  String? _error;
  bool _handDetected = false;
  bool _fistDetected = false;
  GestureResult? _lastResult;

  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _initAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    if (state == AppLifecycleState.resumed) {
      _cameraService.resume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraService.pause();
    }
  }

  Future<void> _initCamera() async {
    if (_isDisposed || _initAttempted) return;
    _initAttempted = true;

    if (_cameraService.isInitialized) {
      if (!_isDisposed && mounted) {
        _startImageProcessing();
      }
      return;
    }

    try {
      await _cameraService.ensureInitialized();
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() => _error = 'Camera offline: $e');
      }
      return;
    }

    if (!_isDisposed && mounted) {
      _startImageProcessing();
    }
  }

  void _startImageProcessing() {
    if (_isDisposed) return;
    if (!_cameraService.isInitialized) return;
    _cameraService.start(_onCameraImage);
    if (mounted && !_isDisposed) setState(() {});
  }

  void _onCameraImage(CameraImage image) {
    if (_isDisposed || _isProcessing) return;
    _isProcessing = true;

    try {
      final result = _service.processFrame(image);
      if (_isDisposed || !mounted) return;

      _lastResult = result;

      if (!_isDisposed && mounted) {
        setState(() {});
      }

      if (_isDisposed || !mounted) return;

      final handNow = result.isHandDetected;
      final fistNow = handNow && result.isFist;

      // Hand appeared
      if (handNow && !_handDetected) {
        _handDetected = true;
        widget.onHandDetected?.call(result);
      }

      if (_isDisposed || !mounted) return;

      // Hand disappeared
      if (!handNow && _handDetected) {
        _handDetected = false;
        _fistDetected = false;
        widget.onHandLost?.call();
        return;
      }

      if (_isDisposed || !mounted) return;

      // Fist appeared (hand must be present)
      if (fistNow && !_fistDetected) {
        _fistDetected = true;
        widget.onFistDetected?.call(result);
      }

      if (_isDisposed || !mounted) return;

      // Fist disappeared (but hand still present)
      if (!fistNow && _fistDetected) {
        _fistDetected = false;
        widget.onFistLost?.call();
      }

      if (_isDisposed || !mounted) return;

      // Per-frame updates while hand is present
      if (handNow) {
        widget.onConfidenceUpdate?.call(result.confidence);
        if (result.landmarks != null && result.landmarks!.isNotEmpty) {
          final wrist = result.landmarks![0];
          widget.onHandPosition?.call(wrist.x, wrist.y);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: widget.showGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_error != null)
            _buildError()
          else if (!_cameraService.isAvailable)
            _buildLoading()
          else
            CameraPreview(_cameraService.controller!),
          HandSkeletonOverlay(
            landmarks: _lastResult?.landmarks,
            intensity: _lastResult?.confidence ?? 0.0,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.overlay,
                  Colors.transparent,
                  AppColors.overlay,
                ],
              ),
            ),
          ),
          GestureDebugPanel(
            lastResult: _lastResult,
            isVisible: widget.debugMode,
            fps: _service.fps,
            handFrames: _service.handFrames,
            fistFrames: _service.fistFrames,
            lostFrames: _service.lostFrames,
            currentState: widget.currentStateLabel,
            trackingId: _service.trackingId,
            consecutiveOpenPalmFrames: _service.consecutiveOpenPalmFrames,
            consecutiveFistFrames: _service.consecutiveFistFrames,
          ),
          ..._buildScanCorners(),
          if (widget.showGlow)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent, AppColors.primary],
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Text(
              _handDetected ? 'Hand detected' : 'Point camera at your hand',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded,
              color: AppColors.textSecondary, size: 28),
          const SizedBox(height: 4),
          Text(
            _error!,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScanCorners() {
    const gap = 12.0;
    return [
      Positioned(top: gap, left: gap, child: _CornerWidget(alignment: CornerAlignment.topLeft)),
      Positioned(top: gap, right: gap, child: _CornerWidget(alignment: CornerAlignment.topRight)),
      Positioned(bottom: gap, left: gap, child: _CornerWidget(alignment: CornerAlignment.bottomLeft)),
      Positioned(bottom: gap, right: gap, child: _CornerWidget(alignment: CornerAlignment.bottomRight)),
    ];
  }
}

enum CornerAlignment { topLeft, topRight, bottomLeft, bottomRight }

class _CornerWidget extends StatelessWidget {
  final CornerAlignment alignment;
  const _CornerWidget({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _CornerPainter(alignment),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final CornerAlignment alignment;
  _CornerPainter(this.alignment);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const len = 22.0;
    final w = size.width;
    final h = size.height;

    switch (alignment) {
      case CornerAlignment.topLeft:
        canvas.drawLine(const Offset(0, len), Offset.zero, paint);
        canvas.drawLine(Offset.zero, Offset(len, 0), paint);
      case CornerAlignment.topRight:
        canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
        canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
      case CornerAlignment.bottomLeft:
        canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
        canvas.drawLine(Offset(0, h), Offset(len, h), paint);
      case CornerAlignment.bottomRight:
        canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);
        canvas.drawLine(Offset(w, h), Offset(w - len, h), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) => alignment != old.alignment;
}
