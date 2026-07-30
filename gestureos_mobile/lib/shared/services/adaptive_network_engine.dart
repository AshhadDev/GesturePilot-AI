import 'dart:async';

import 'package:gesture_os/core/utils/logger.dart';

/// Dynamically optimizes transfer parameters based on real-time network conditions.
///
/// Monitors latency, bandwidth, and packet loss to choose optimal chunk size.
/// Automatically throttles on weak Wi-Fi to prevent packet loss.
class AdaptiveNetworkEngine {
  AdaptiveNetworkEngine._();
  static final AdaptiveNetworkEngine instance = AdaptiveNetworkEngine._();

  // Network metrics
  double _currentLatencyMs = 30;
  double _currentBandwidthMbps = 50;
  double _currentPacketLoss = 0;
  int _optimalChunkSize = 65536;
  double _throttleFactor = 1.0;

  // History for smoothing
  final _latencyHistory = <double>[];
  final _bandwidthHistory = <double>[];
  final _lossHistory = <double>[];
  static const int _maxHistory = 10;

  // Metrics stream
  final _metricsController = StreamController<NetworkMetrics>.broadcast();
  Timer? _recalcTimer;

  Stream<NetworkMetrics> get metricsStream => _metricsController.stream;

  NetworkMetrics get currentMetrics => NetworkMetrics(
        latencyMs: _currentLatencyMs,
        bandwidthMbps: _currentBandwidthMbps,
        packetLoss: _currentPacketLoss,
        optimalChunkSize: _optimalChunkSize,
        throttleFactor: _throttleFactor,
      );

  /// Starts the adaptive engine with periodic recalculation.
  void start({Duration interval = const Duration(seconds: 3)}) {
    _recalcTimer?.cancel();
    _recalcTimer = Timer.periodic(interval, (_) => _recalculate());
    AppLogger.info('AdaptiveNetworkEngine started');
  }

  void stop() {
    _recalcTimer?.cancel();
    _recalcTimer = null;
  }

  /// Reports a round-trip time measurement.
  void reportLatency(double ms) {
    _latencyHistory.add(ms);
    if (_latencyHistory.length > _maxHistory) _latencyHistory.removeAt(0);
    _currentLatencyMs = _smoothedAverage(_latencyHistory);
  }

  /// Reports measured bandwidth in Mbps.
  void reportBandwidth(double mbps) {
    _bandwidthHistory.add(mbps);
    if (_bandwidthHistory.length > _maxHistory) _bandwidthHistory.removeAt(0);
    _currentBandwidthMbps = _smoothedAverage(_bandwidthHistory);
  }

  /// Reports packet loss ratio (0.0 - 1.0).
  void reportPacketLoss(double loss) {
    _lossHistory.add(loss);
    if (_lossHistory.length > _maxHistory) _lossHistory.removeAt(0);
    _currentPacketLoss = _smoothedAverage(_lossHistory);
  }

  /// Returns the optimal chunk size in bytes for current conditions.
  int getOptimalChunkSize() {
    // Choose chunk size based on bandwidth
    if (_currentBandwidthMbps > 100) return 1048576; // 1 MB
    if (_currentBandwidthMbps > 50) return 524288; // 512 KB
    if (_currentBandwidthMbps > 20) return 262144; // 256 KB
    if (_currentBandwidthMbps > 10) return 131072; // 128 KB
    return 65536; // 64 KB - fallback for slow connections
  }

  /// Returns the transfer throttle (0.0 = stop, 1.0 = full speed).
  double getThrottleFactor() {
    if (_currentPacketLoss > 0.15) return 0.2; // Severe loss: slow way down
    if (_currentPacketLoss > 0.08) return 0.4; // High loss: half speed
    if (_currentPacketLoss > 0.04) return 0.6; // Moderate loss
    if (_currentPacketLoss > 0.02) return 0.8; // Mild loss
    if (_currentLatencyMs > 500) return 0.3; // High latency
    if (_currentLatencyMs > 200) return 0.6; // Moderate latency
    return 1.0; // Full speed
  }

  /// Returns the delay to insert between chunks in milliseconds.
  int getInterChunkDelayMs() {
    final factor = getThrottleFactor();
    if (factor >= 1.0) return 0;
    return ((1.0 / factor) * 5).round();
  }

  /// Reports a successful chunk transfer to measure bandwidth.
  void reportChunkTransfer(int bytes, Duration duration) {
    if (duration.inMilliseconds < 1) return;
    final mbps = (bytes * 8) / (duration.inMilliseconds * 1000);
    reportBandwidth(mbps);
  }

  void _recalculate() {
    _optimalChunkSize = getOptimalChunkSize();
    _throttleFactor = getThrottleFactor();

    _metricsController.add(currentMetrics);

    AppLogger.debug(
      'NetworkMetrics: latency=${_currentLatencyMs.toStringAsFixed(0)}ms '
      'bw=${_currentBandwidthMbps.toStringAsFixed(1)}Mbps '
      'loss=${(_currentPacketLoss * 100).toStringAsFixed(1)}% '
      'chunk=${_optimalChunkSize ~/ 1024}KB '
      'throttle=${(_throttleFactor * 100).toStringAsFixed(0)}%',
    );
  }

  double _smoothedAverage(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;
    // Weighted: most recent counts double
    final weights = List.generate(
      values.length,
      (i) => i == values.length - 1 ? 2.0 : 1.0,
    );
    final totalWeight = weights.fold(0.0, (a, b) => a + b);
    double sum = 0;
    for (int i = 0; i < values.length; i++) {
      sum += values[i] * weights[i];
    }
    return sum / totalWeight;
  }

  void dispose() {
    stop();
    _metricsController.close();
  }
}

class NetworkMetrics {
  final double latencyMs;
  final double bandwidthMbps;
  final double packetLoss;
  final int optimalChunkSize;
  final double throttleFactor;

  const NetworkMetrics({
    required this.latencyMs,
    required this.bandwidthMbps,
    required this.packetLoss,
    required this.optimalChunkSize,
    required this.throttleFactor,
  });
}
