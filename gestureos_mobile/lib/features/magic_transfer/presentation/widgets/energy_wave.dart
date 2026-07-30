import 'package:flutter/material.dart';

class EnergyWave extends StatelessWidget {
  final double time;
  final double intensity;
  final Color color;
  final double size;

  const EnergyWave({
    super.key,
    required this.time,
    required this.intensity,
    required this.size,
    this.color = const Color(0xFF7C3AED),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WavePainter(time, intensity, color, size),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double time;
  final double intensity;
  final Color color;
  final double size;

  _WavePainter(this.time, this.intensity, this.color, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final phase = i * 0.33;
      final waveTime = (time + phase) % 1.0;
      final radius = baseRadius * (0.4 + waveTime * 1.2);
      final alpha = (1.0 - waveTime) * 0.25 * intensity;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * (1.0 - waveTime)
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      time != old.time || intensity != old.intensity;
}
