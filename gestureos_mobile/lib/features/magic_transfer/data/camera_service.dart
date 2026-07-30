import 'package:camera/camera.dart';
import 'package:logger/logger.dart';

/// Singleton service that owns one [CameraController] at a time and uses
/// reference counting so multiple widgets can share the camera without
/// disposing the controller out from under each other.
///
/// Call [start] when a widget begins receiving frames (increments ref count
/// and swaps the active callback).  Call [stop] when it stops (decrements ref
/// count; stops the stream only when the count reaches zero).
///
/// Lifecycle pause/resume is handled via [pause] / [resume] without changing
/// the ref count.  [dispose] tears everything down for good.
class CameraService {
  CameraService._();
  static final CameraService _instance = CameraService._();
  static CameraService get instance => _instance;

  static final _logger = Logger();

  CameraController? _controller;
  void Function(CameraImage)? _currentCallback;
  int _refCount = 0;
  bool _isDisposed = false;

  CameraController? get controller => _controller;

  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Safe to call [CameraPreview] with this controller when true.
  bool get isAvailable =>
      _controller != null &&
      _controller!.value.isInitialized &&
      !_controller!.value.isTakingPicture;

  bool get isStreaming =>
      _refCount > 0 && _controller != null && _controller!.value.isInitialized;

  // ========================================================================
  //  Controller lifecycle
  // ========================================================================

  /// Ensures a controller exists and is initialized.
  /// Disposes any previous controller first to guarantee only ONE exists.
  Future<void> ensureInitialized({
    CameraLensDirection lens = CameraLensDirection.front,
  }) async {
    if (_isDisposed) return;
    if (_controller != null && _controller!.value.isInitialized) return;

    await _controller?.dispose();
    _controller = null;

    try {
      final cameras = await availableCameras();
      final target = cameras.firstWhere(
        (c) => c.lensDirection == lens,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        target,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      _logger.i('Camera initialized: ${target.name}');
    } catch (e) {
      _logger.e('Camera init failed: $e');
      rethrow;
    }
  }

  // ========================================================================
  //  Ref-counted start / stop
  // ========================================================================

  /// Register a consumer and set [onImage] as the active frame callback.
  /// If the stream is already running the callback is swapped in-place.
  void start(void Function(CameraImage) onImage) {
    if (_isDisposed) return;
    _refCount++;
    _currentCallback = onImage;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_refCount > 1) return; // stream already running
    _controller!.startImageStream(_dispatchImage);
  }

  /// Unregister a consumer.  Stops the stream only when the last consumer
  /// has called [stop] (ref count reaches zero).
  void stop() {
    if (_isDisposed) return;
    _refCount = (_refCount - 1).clamp(0, _refCount);
    if (_refCount > 0) return;
    _currentCallback = null;
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  // ========================================================================
  //  Lifecycle pause / resume (don't touch ref count)
  // ========================================================================

  /// Temporarily stop delivering frames (e.g. app backgrounded).
  void pause() {
    if (_controller != null && _controller!.value.isInitialized) {
      try {
        _controller!.stopImageStream();
      } catch (_) {}
    }
  }

  /// Restart frame delivery after [pause].
  void resume() {
    if (_isDisposed) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_refCount <= 0 || _currentCallback == null) return;
    _controller!.startImageStream(_dispatchImage);
  }

  // ========================================================================
  //  Full teardown
  // ========================================================================

  /// Destroy the controller and reset all state.  After this call the
  /// service must be [ensureInitialized] again before [start] will work.
  Future<void> dispose() async {
    _isDisposed = true;
    _refCount = 0;
    _currentCallback = null;
    if (_controller != null) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
      await _controller!.dispose();
      _controller = null;
    }
  }

  // ========================================================================
  //  Internal dispatch
  // ========================================================================

  void _dispatchImage(CameraImage image) {
    _currentCallback?.call(image);
  }
}
