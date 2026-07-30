import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

class NetworkDiagnostics extends StatefulWidget {
  final int latencyMs;
  final double bandwidthMbps;
  final String protocol;
  final bool encryptionEnabled;
  final double connectionQuality;
  final String wifiName;
  final String deviceIp;

  const NetworkDiagnostics({
    super.key,
    this.latencyMs = 0,
    this.bandwidthMbps = 0,
    this.protocol = 'TCP',
    this.encryptionEnabled = false,
    this.connectionQuality = 1.0,
    this.wifiName = '',
    this.deviceIp = '',
  });

  @override
  State<NetworkDiagnostics> createState() => _NetworkDiagnosticsState();
}

class _NetworkDiagnosticsState extends State<NetworkDiagnostics>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _expandController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() => _expanded = !_expanded);
            if (_expanded) {
              _expandController.forward();
            } else {
              _expandController.reverse();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.monitor_heart_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                const Text(
                  'Network Diagnostics',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const Spacer(),
                _qualityIndicator(widget.connectionQuality),
                const SizedBox(width: 8),
                Text(
                  '${widget.latencyMs}ms',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _latencyColor(widget.latencyMs),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        SizeTransition(
          sizeFactor: _expandAnimation,
          alignment: const Alignment(-1, 0),
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _row('Latency', '${widget.latencyMs} ms', _latencyColor(widget.latencyMs)),
                const SizedBox(height: 6),
                _row('Bandwidth', '${widget.bandwidthMbps.toStringAsFixed(1)} Mbps', AppColors.accent),
                const SizedBox(height: 6),
                _row('Protocol', widget.protocol, AppColors.textPrimary),
                const SizedBox(height: 6),
                _row('Encryption', widget.encryptionEnabled ? 'AES-256' : 'None',
                    widget.encryptionEnabled ? AppColors.success : AppColors.textSecondary),
                const SizedBox(height: 6),
                _row('Quality', '${(widget.connectionQuality * 100).toStringAsFixed(0)}%',
                    _qualityColor(widget.connectionQuality)),
                if (widget.wifiName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _row('Network', widget.wifiName, AppColors.textPrimary),
                ],
                if (widget.deviceIp.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _row('IP', widget.deviceIp, AppColors.textSecondary),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: valueColor)),
      ],
    );
  }

  Widget _qualityIndicator(double quality) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _qualityColor(quality),
      ),
    );
  }

  Color _qualityColor(double q) {
    if (q >= 0.8) return AppColors.success;
    if (q >= 0.5) return AppColors.accent;
    return AppColors.error;
  }

  Color _latencyColor(int ms) {
    if (ms < 30) return AppColors.success;
    if (ms < 100) return AppColors.accent;
    return AppColors.error;
  }
}
