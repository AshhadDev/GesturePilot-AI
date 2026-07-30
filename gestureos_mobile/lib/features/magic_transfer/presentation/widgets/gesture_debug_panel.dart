import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/features/magic_transfer/domain/gesture_result.dart';

class GestureDebugPanel extends StatelessWidget {
  final GestureResult? lastResult;
  final bool isVisible;
  final double fps;
  final int handFrames;
  final int fistFrames;
  final int lostFrames;
  final String currentState;
  final int trackingId;
  final int consecutiveOpenPalmFrames;
  final int consecutiveFistFrames;

  const GestureDebugPanel({
    super.key,
    this.lastResult,
    this.isVisible = false,
    this.fps = 0,
    this.handFrames = 0,
    this.fistFrames = 0,
    this.lostFrames = 0,
    this.currentState = 'idle',
    this.trackingId = 0,
    this.consecutiveOpenPalmFrames = 0,
    this.consecutiveFistFrames = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();
    final r = lastResult;
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
            _row('Hand', r?.isHandDetected == true ? 'YES' : 'NO',
                r?.isHandDetected == true ? AppColors.success : AppColors.error),
            _row('Verified', r?.isHandVerified == true ? 'YES' : 'NO',
                r?.isHandVerified == true ? AppColors.success : AppColors.error),
            _row('Open Palm', r?.isOpenPalm == true ? 'YES' : 'NO',
                r?.isOpenPalm == true ? AppColors.accent : AppColors.textSecondary),
            _row('Fist', r?.isFist == true ? 'YES' : 'NO',
                r?.isFist == true ? AppColors.error : AppColors.textSecondary),
            _divider(),
            _row('Fingers', '${r?.fingerCount ?? 0}', AppColors.accent),
            _row('Hand Conf', '${(r?.confidence ?? 0) * 100 ~/ 1}%',
                AppColors.success),
            _row('Fist Conf', '${(r?.fistConfidence ?? 0) * 100 ~/ 1}%',
                const Color(0xFFF59E0B)),
            _verDetail(r?.verificationDetail, r?.verificationScore ?? 0),
            _divider(),
            _row('Track ID', '$trackingId', AppColors.primary),
            _row('Size', (r?.normalizedHandSize ?? 0).toStringAsFixed(3),
                AppColors.textSecondary),
            _row('Open#', '$consecutiveOpenPalmFrames', AppColors.accent),
            _row('Fist#', '$consecutiveFistFrames', AppColors.error),
            _row('Lost#', '$lostFrames', AppColors.textSecondary),
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
              style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _verDetail(VerificationDetail? d, double rawScore) {
    if (d == null) {
      return _row('Ver Score', '${rawScore.toStringAsFixed(2)} (?)',
          AppColors.textSecondary);
    }
    final pass = d.totalScore >= 0.40;
    final color = pass ? AppColors.success : AppColors.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _row('Ver Score', '${d.totalScore.toStringAsFixed(2)} '
            '${pass ? 'PASS' : 'FAIL'}@40',
            color),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _check('S', d.solidityScore, d.isSolidityPass),
              _check('C', d.circularityScore, d.isCircularityPass),
              _check('A', d.aspectRatioScore, d.isAspectRatioPass),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _check('F', d.fillRatioScore, d.isFillRatioPass),
              _check('D', d.defectsScore, d.isDefectsPass),
              _check('G', d.fingerCountScore, d.isFingerCountPass),
            ],
          ),
        ),
      ],
    );
  }

  Widget _check(String label, double score, bool pass) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        '$label${pass ? '+' : '-'}${(score * 100).round()}',
        style: TextStyle(
          fontSize: 8,
          color: pass ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
