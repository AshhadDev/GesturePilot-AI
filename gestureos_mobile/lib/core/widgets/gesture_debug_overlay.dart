import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Debug overlay for visualizing gesture detection data.
/// Shows bounding box, landmarks, confidence scores, and fist detection.
class GestureDebugOverlay extends StatelessWidget {
  final double? confidence;
  final double? fistScore;
  final List<Offset>? landmarks;
  final Rect? boundingBox;
  final String? label;
  final Size? imageSize;

  const GestureDebugOverlay({
    super.key,
    this.confidence,
    this.fistScore,
    this.landmarks,
    this.boundingBox,
    this.label,
    this.imageSize,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = confidence != null ||
        fistScore != null ||
        landmarks != null ||
        boundingBox != null;

    if (!hasData) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confidence bar
        if (confidence != null) _buildConfidenceBar('Confidence', confidence!),
        if (fistScore != null) _buildConfidenceBar('Fist Score', fistScore!),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        // Landmark count
        if (landmarks != null)
          Text(
            'Landmarks: ${landmarks!.length}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        // Bounding box info
        if (boundingBox != null)
          Text(
            'BBox: ${boundingBox!.left.toInt()},${boundingBox!.top.toInt()} '
            '${boundingBox!.width.toInt()}x${boundingBox!.height.toInt()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildConfidenceBar(String label, double value) {
    final clamped = value.clamp(0.0, 1.0);
    final color = clamped > 0.7
        ? AppColors.success
        : clamped > 0.4
            ? AppColors.accent
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ),
          Container(
            width: 60,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(clamped * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints landmarks and bounding boxes directly onto the camera preview.
class DebugLandmarkPainter extends CustomPainter {
  final List<Offset>? landmarks;
  final Rect? boundingBox;

  DebugLandmarkPainter({
    this.landmarks,
    this.boundingBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw bounding box
    if (boundingBox != null) {
      final rect = Rect.fromLTWH(
        boundingBox!.left * size.width,
        boundingBox!.top * size.height,
        boundingBox!.width * size.width,
        boundingBox!.height * size.height,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      // Corner markers
      final corners = [
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ];
      for (final corner in corners) {
        canvas.drawCircle(
          corner,
          3,
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.fill,
        );
      }
    }

    // Draw landmarks
    final lm = landmarks;
    if (lm != null) {
      for (int i = 0; i < lm.length; i++) {
        final pt = lm[i];
        final pixel = Offset(pt.dx * size.width, pt.dy * size.height);
        canvas.drawCircle(
          pixel,
          3,
          Paint()..color = AppColors.primary,
        );
        canvas.drawCircle(
          pixel,
          5,
          Paint()
            ..color = AppColors.primary.withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }

      // Draw connections between consecutive landmarks
      if (lm.length > 1) {
        for (int i = 0; i < lm.length - 1; i++) {
          final p1 = Offset(
            lm[i].dx * size.width,
            lm[i].dy * size.height,
          );
          final p2 = Offset(
            lm[i + 1].dx * size.width,
            lm[i + 1].dy * size.height,
          );
          canvas.drawLine(
            p1,
            p2,
            Paint()
              ..color = AppColors.accent.withValues(alpha: 0.3)
              ..strokeWidth = 1,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(DebugLandmarkPainter old) {
    if (boundingBox != old.boundingBox) return true;
    if (landmarks?.length != old.landmarks?.length) return true;
    return false;
  }
}
