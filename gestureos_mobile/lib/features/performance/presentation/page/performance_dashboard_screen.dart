import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/providers/production_providers.dart';
import 'package:gesture_os/shared/services/adaptive_network_engine.dart';

class PerformanceDashboardScreen extends ConsumerStatefulWidget {
  const PerformanceDashboardScreen({super.key});

  @override
  ConsumerState<PerformanceDashboardScreen> createState() =>
      _PerformanceDashboardScreenState();
}

class _PerformanceDashboardScreenState
    extends ConsumerState<PerformanceDashboardScreen> {
  StreamSubscription<NetworkMetrics>? _metricsSub;
  double _bandwidthMbps = 0;
  double _latencyMs = 0;
  double _packetLoss = 0;
  int _optimalChunk = 65536;
  double _throttle = 1.0;

  @override
  void initState() {
    super.initState();
    AdaptiveNetworkEngine.instance.start();
    _metricsSub = AdaptiveNetworkEngine.instance.metricsStream.listen((m) {
      setState(() {
        _bandwidthMbps = m.bandwidthMbps;
        _latencyMs = m.latencyMs;
        _packetLoss = m.packetLoss;
        _optimalChunk = m.optimalChunkSize;
        _throttle = m.throttleFactor;
      });
    });
  }

  @override
  void dispose() {
    _metricsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perf = ref.watch(performanceMetricsProvider);
    final chunkKB = _optimalChunk ~/ 1024;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Dashboard',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Live metrics for debugging transfer performance',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _buildMetricCard('Network', _bandwidthMbps.toStringAsFixed(1), 'Mbps', AppColors.accent),
                    _buildMetricCard('Latency', _latencyMs.toStringAsFixed(0), 'ms', AppColors.primary),
                    _buildMetricCard('Packet Loss', (_packetLoss * 100).toStringAsFixed(1), '%', _packetLoss > 0.05 ? AppColors.error : AppColors.success),
                    _buildMetricCard('Chunk Size', chunkKB.toString(), 'KB', AppColors.accent),
                    _buildMetricCard('Throttle', (_throttle * 100).toStringAsFixed(0), '%', _throttle < 0.5 ? Colors.orange : AppColors.success),
                    _buildMetricCard('FPS', perf.fps.toStringAsFixed(0), 'fps', perf.fps > 30 ? AppColors.success : Colors.orange),
                    _buildMetricCard('Memory', perf.memoryMb.toStringAsFixed(0), 'MB', perf.memoryMb > 200 ? AppColors.error : AppColors.textPrimary),
                    _buildMetricCard('Discovery', perf.discoveryTimeMs.toString(), 'ms', AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
      String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
