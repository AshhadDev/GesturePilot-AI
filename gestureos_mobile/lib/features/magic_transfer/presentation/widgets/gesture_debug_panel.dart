import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';

class GestureDebugPanel extends StatelessWidget {
  final GestureResult? lastResult;
  final bool isVisible;
  final double fps;
  final String currentState;

  const GestureDebugPanel({
    super.key,
    this.lastResult,
    this.isVisible = false,
    this.fps = 0,
    this.currentState = 'idle',
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    final r = lastResult;
    final m = r?.metrics;

    return Positioned(
      top: 4,
      left: 4,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.overlay,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('FPS', fps.toStringAsFixed(0), AppColors.textSecondary),
            _row('State', currentState, AppColors.accent),
            _divider(),
            _row('Detected', r?.isHandDetected == true ? 'YES' : 'NO',
                r?.isHandDetected == true ? AppColors.success : AppColors.error),
            _row('Stage2', r?.stage2Passed == true ? 'PASS' : 'FAIL',
                r?.stage2Passed == true ? AppColors.success : AppColors.error),
            _row('Stage3', r?.stage3Passed == true ? 'PASS' : 'FAIL',
                r?.stage3Passed == true ? AppColors.success : AppColors.error),
            if (r?.rejectionReason != null && r!.rejectionReason != RejectionReason.none)
              _row('Reject', _rejectionLabel(r.rejectionReason), AppColors.error),
            _divider(),
            _row('Open Hand', '${(r?.openHandScore ?? 0 * 100).round()}%',
                AppColors.success),
            _row('Conf', '${(r?.confidence ?? 0 * 100).round()}%',
                AppColors.primary),
            _row('Raw', '${(r?.rawConfidence ?? 0 * 100).round()}%',
                AppColors.textSecondary),
            _divider(),
            _row('Open#', '${r?.consecutiveOpenHandFrames ?? 0}', AppColors.success),
            _row('Lost#', '${r?.handLostFrames ?? 0}', AppColors.error),
            _divider(),
            if (m != null) ...[
              _row('Area', m.contourArea.toStringAsFixed(0), AppColors.primary),
              _row('BBox', '${m.bboxWidth.toStringAsFixed(0)}x${m.bboxHeight.toStringAsFixed(0)}',
                  AppColors.textSecondary),
              _row('Extent', m.extent.toStringAsFixed(2), AppColors.textSecondary),
              _row('Solidity', m.solidity.toStringAsFixed(2), AppColors.textSecondary),
              _row('Aspect', m.aspectRatio.toStringAsFixed(2), AppColors.textSecondary),
              _row('Smooth', m.smoothness.toStringAsFixed(1), AppColors.textSecondary),
              _row('Fingers', '${m.fingerCount}', AppColors.accent),
            ],
            _divider(),
            _row('Track', '${r?.trackingId ?? 0}', AppColors.primary),
            _row('LMs', '${r?.landmarks?.length ?? 0}', AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Divider(height: 1, color: AppColors.border),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _rejectionLabel(RejectionReason reason) {
    switch (reason) {
      case RejectionReason.none: return 'none';
      case RejectionReason.noComponent: return 'no component';
      case RejectionReason.tooSmall: return 'too small';
      case RejectionReason.badAspectRatio: return 'bad aspect';
      case RejectionReason.lowExtent: return 'low extent';
      case RejectionReason.lowSolidity: return 'low solidity';
      case RejectionReason.tooSmooth: return 'too smooth';
    }
  }
}
