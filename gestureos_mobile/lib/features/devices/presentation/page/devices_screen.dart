import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/core/widgets/empty_state.dart';
import 'package:gesture_os/features/devices/presentation/widgets/device_tile.dart';
import 'package:gesture_os/shared/providers/device_providers.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(discoveryControllerProvider).start();
      await ref.read(trustedDevicesProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    // Defer past widget teardown so the controller can still read providers
    // without touching an already-defunct element.
    Future.microtask(() async {
      try {
        await ref.read(discoveryControllerProvider).stop();
      } catch (_) {}
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localDeviceAsync = ref.watch(localDeviceInfoProvider);
    final discoveredAsync = ref.watch(discoveredDevicesStreamProvider);
    final trusted = ref.watch(trustedDevicesProvider);
    final isActive = ref.watch(discoveryActiveProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Devices',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(RouteNames.qrScanner),
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Scan desktop QR code',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isActive ? 'Discovering' : 'Stopped',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(discoveryControllerProvider).start();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: localDeviceAsync.when(
                  data: (info) => _buildLocalDeviceCard(info),
                  loading: () => const SizedBox(height: 80),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionTitle('Trusted Devices'),
              ),
            ),
            if (trusted.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.favorite_outline_rounded,
                    title: 'No trusted devices',
                    subtitle: 'Trust a discovered device to see it here',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final d = trusted[index];
                      return DeviceTile(
                        device: d,
                        isTrusted: true,
                        onTap: () => context.pushNamed(
                          RouteNames.deviceDetail,
                          pathParameters: {
                            'deviceId': d.id,
                            'deviceName': base64Url.encode(utf8.encode(d.name)),
                            'deviceIp': d.ip,
                            'devicePlatform': d.platform.index.toString(),
                            'devicePort': d.port.toString(),
                            'isTrusted': 'true',
                          },
                        ),
                        onForget: () => ref.read(trustedDevicesProvider.notifier).remove(d.id),
                      );
                    },
                    childCount: trusted.length,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildSectionTitle('Nearby Devices'),
              ),
            ),
            discoveredAsync.when(
              data: (devices) {
                final visible = devices.where((d) => !trusted.any((t) => t.id == d.id)).toList();
                if (visible.isEmpty) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                    sliver: SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.wifi_find_rounded,
                        title: 'Searching...',
                        subtitle: 'Make sure the other device has GestureOS open',
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final d = visible[index];
                        return DeviceTile(
                          device: d,
                          onTap: () => context.pushNamed(
                            RouteNames.pairing,
                            pathParameters: {
                              'deviceId': d.id,
                              'deviceName': base64Url.encode(utf8.encode(d.name)),
                              'deviceIp': d.ip,
                              'devicePlatform': d.platform.index.toString(),
                            },
                          ),
                          onTrust: () async {
                            await ref.read(trustedDevicesProvider.notifier).add(d);
                          },
                        );
                      },
                      childCount: visible.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                sliver: SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.wifi_find_rounded,
                    title: 'Scanning network...',
                    subtitle: 'Looking for GestureOS devices',
                  ),
                ),
              ),
              error: (err, _) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
                sliver: SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.wifi_off_rounded,
                    title: 'Discovery error',
                    subtitle: '$err',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalDeviceCard(LocalDeviceInfo info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(25),
            AppColors.secondary.withAlpha(12),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.devices_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${info.ip} \u2022 ${info.platform.name}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'This device',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
