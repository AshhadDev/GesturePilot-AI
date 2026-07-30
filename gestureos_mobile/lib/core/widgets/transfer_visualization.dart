import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class TransferVisualization extends StatefulWidget {
  final double progress;
  final double speedBytesPerSec;
  final String currentFile;
  final String transferredSize;
  final String eta;
  final int packetCount;
  final int ackCount;
  final bool hasError;
  final bool isPaused;

  const TransferVisualization({
    super.key,
    this.progress = 0,
    this.speedBytesPerSec = 0,
    this.currentFile = '',
    this.transferredSize = '',
    this.eta = '',
    this.packetCount = 0,
    this.ackCount = 0,
    this.hasError = false,
    this.isPaused = false,
  });

  @override
  State<TransferVisualization> createState() => _TransferVisualizationState();
}

class _TransferVisualizationState extends State<TransferVisualization>
    with SingleTickerProviderStateMixin {
  late final AnimationController _packetController;
  final List<_Packet> _packets = [];
  final List<_AckRipple> _ripples = [];
  final math.Random _random = math.Random();
  int _lastPacketCount = 0;
  int _lastAckCount = 0;
  final List<double> _speedHistory = [];
  int _speedFrame = 0;

  @override
  void initState() {
    super.initState();
    _packetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void didUpdateWidget(TransferVisualization old) {
    super.didUpdateWidget(old);
    if (widget.packetCount > _lastPacketCount) {
      _addPacket();
    }
    if (widget.ackCount > _lastAckCount) {
      _addRipple();
    }
    _lastPacketCount = widget.packetCount;
    _lastAckCount = widget.ackCount;
  }

  @override
  void dispose() {
    _packetController.dispose();
    super.dispose();
  }

  void _addPacket() {
    _packets.add(_Packet(
      x: -20,
      y: 50 + _random.nextDouble() * 60,
      targetX: 140,
      targetY: 50 + _random.nextDouble() * 60,
      speed: 2 + _random.nextDouble() * 1.5,
      size: 2 + _random.nextDouble() * 3,
      alpha: 0.4 + _random.nextDouble() * 0.6,
    ));
  }

  void _addRipple() {
    _ripples.add(_AckRipple(
      x: 140,
      y: 50,
      maxRadius: 15 + _random.nextDouble() * 10,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final speed = _formatSpeed(widget.speedBytesPerSec);
    final isSlow = widget.speedBytesPerSec > 0 && widget.speedBytesPerSec < 50000;
    final isFast = widget.speedBytesPerSec > 5000000;

    // Record speed history for sparkline
    _speedFrame++;
    if (_speedFrame % 3 == 0) {
      _speedHistory.add(widget.speedBytesPerSec);
      if (_speedHistory.length > 40) _speedHistory.removeAt(0);
    }

    _packets.removeWhere((p) => p.x > p.targetX + 10);
    _ripples.removeWhere((r) => r.progress >= 1);

    return AnimatedBuilder(
      animation: _packetController,
      builder: (context, _) {
        final dt = _packetController.value;
        for (final p in _packets) {
          p.update();
        }
        for (final r in _ripples) {
          r.update(dt);
        }

        return Column(
          children: [
            // Visualization area
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Background grid
                    CustomPaint(
                      size: const Size(double.infinity, 120),
                      painter: _GridPainter(),
                    ),
                    // Packet particles
                    ..._packets.map((p) => Positioned(
                          left: p.x,
                          top: p.y,
                          child: Container(
                            width: p.size,
                            height: p.size,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.hasError
                                  ? AppColors.error.withValues(alpha: p.alpha)
                                  : AppColors.accent.withValues(alpha: p.alpha),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.hasError ? AppColors.error : AppColors.accent)
                                      .withValues(alpha: p.alpha * 0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        )),
                    // ACK ripples
                    ..._ripples.map((r) => Positioned(
                          left: r.x - r.maxRadius * r.progress,
                          top: r.y - r.maxRadius * r.progress,
                          child: Opacity(
                            opacity: 1 - r.progress,
                            child: Container(
                              width: r.maxRadius * 2 * r.progress,
                              height: r.maxRadius * 2 * r.progress,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.6 * (1 - r.progress)),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        )),
                    // Sender icon
                    Positioned(
                      left: 8,
                      top: 40,
                      child: _deviceDot(AppColors.primary, 'Phone'),
                    ),
                    // Receiver icon
                    Positioned(
                      right: 8,
                      top: 40,
                      child: _deviceDot(AppColors.accent, 'Desktop'),
                    ),
                    // Progress indicator at bottom
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: AppColors.border,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: widget.hasError
                                    ? [AppColors.error, AppColors.error]
                                    : [AppColors.primary, AppColors.accent],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Pause overlay
                    if (widget.isPaused)
                      Container(
                        color: AppColors.background.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.pause_rounded,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                      ),
                    // Error overlay
                    if (widget.hasError)
                      Container(
                        color: AppColors.background.withValues(alpha: 0.3),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _statTile(Icons.speed_rounded, speed, 'Speed'),
                _statTile(Icons.timer_outlined, widget.eta, 'ETA'),
                _statTile(Icons.insert_drive_file_outlined, widget.currentFile, 'File'),
              ],
            ),
            // Slow/Fast indicator
            if (isSlow)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text('Slow connection', style: TextStyle(fontSize: 10, color: AppColors.error.withValues(alpha: 0.7))),
                  ],
                ),
              ),
            if (isFast)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 4),
                    const Text('High speed', style: TextStyle(fontSize: 10, color: AppColors.success)),
                  ],
                ),
              ),
            // Speed sparkline
            if (_speedHistory.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 32,
                  child: CustomPaint(
                    size: const Size(double.infinity, 32),
                    painter: _SparklinePainter(
                      values: _speedHistory,
                      isSlow: isSlow,
                      isFast: isFast,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _deviceDot(Color color, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec >= 1073741824) return '${(bytesPerSec / 1073741824).toStringAsFixed(1)} GB/s';
    if (bytesPerSec >= 1048576) return '${(bytesPerSec / 1048576).toStringAsFixed(1)} MB/s';
    if (bytesPerSec >= 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${bytesPerSec.toStringAsFixed(0)} B/s';
  }
}

class _Packet {
  double x, y;
  final double targetX, targetY;
  final double speed, size, alpha;

  _Packet({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.speed,
    required this.size,
    required this.alpha,
  });

  void update() {
    final dx = targetX - x;
    final dy = targetY - y;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist > 1) {
      x += dx / dist * speed;
      y += dy / dist * speed + math.sin(x * 0.1) * 0.3;
    }
  }
}

class _AckRipple {
  final double x, y, maxRadius;
  double progress = 0;

  _AckRipple({required this.x, required this.y, required this.maxRadius});

  void update(double dt) {
    progress += dt * 0.5;
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final bool isSlow;
  final bool isFast;

  _SparklinePainter({
    required this.values,
    this.isSlow = false,
    this.isFast = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final maxVal = values.reduce(math.max);
    final minVal = values.reduce(math.min);
    final range = (maxVal - minVal).clamp(1, double.infinity);

    final lineColor = isSlow
        ? AppColors.error
        : isFast
            ? AppColors.success
            : AppColors.accent;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - ((values[i] - minVal) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Fill gradient below line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      values.length != old.values.length ||
      values.last != old.values.last;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
