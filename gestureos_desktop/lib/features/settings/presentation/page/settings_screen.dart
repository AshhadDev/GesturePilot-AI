import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/utils/file_utils.dart';
import 'package:gestureos_desktop/core/widgets/desktop_app_bar.dart';
import 'package:gestureos_desktop/shared/models/device_model.dart';
import 'package:gestureos_desktop/shared/providers/app_providers.dart';
import 'package:gestureos_desktop/shared/services/trusted_device_manager.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Column(
      children: [
        const DesktopAppBar(title: 'Settings'),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingXl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('General', Icons.computer_rounded, [
                      _buildTextField(
                        label: 'Desktop Name',
                        value: settings.desktopName,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setDesktopName(v),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection('Connection', Icons.wifi_tethering_rounded, [
                      _buildToggleTile(
                        label: 'Automatic Discovery',
                        subtitle: 'Find nearby phones on the same network',
                        value: settings.autoDiscover,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setAutoDiscover(!settings.autoDiscover),
                      ),
                      const _SectionDivider(),
                      _buildToggleTile(
                        label: 'QR Pairing',
                        subtitle: 'Allow pairing by scanning a QR code',
                        value: settings.enableQr,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setEnableQr(!settings.enableQr),
                      ),
                      const _SectionDivider(),
                      _buildToggleTile(
                        label: 'Auto-accept Trusted Devices',
                        subtitle: 'Skip confirmation for trusted senders',
                        value: settings.autoAccept,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setAutoAccept(!settings.autoAccept),
                      ),
                      const _SectionDivider(),
                      _buildTimeoutSlider(
                        seconds: settings.connectionTimeout,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setConnectionTimeout(v),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection('Security', Icons.shield_rounded, [
                      _buildTrustedDevices(ref),
                      const _SectionDivider(),
                      _buildDangerButton(
                        label: 'Reset All Pairings',
                        icon: Icons.delete_sweep_rounded,
                        onTap: () => _confirmResetPairings(context, ref),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection(
                      'Downloads',
                      Icons.download_rounded,
                      [
                        _buildTextField(
                          label: 'Download Folder',
                          value: settings.downloadFolder,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setDownloadFolder(v),
                          suffixIcon: Icons.folder_open_rounded,
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        _buildActionButton(
                          label: 'Open Folder',
                          icon: Icons.folder_rounded,
                          onTap: settings.downloadFolder.isEmpty
                              ? null
                              : () => openFileWithDefaultApp(
                                  settings.downloadFolder),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection(
                      'Notifications',
                      Icons.notifications_rounded,
                      [
                        _buildToggleTile(
                          label: 'Transfer Notifications',
                          subtitle: 'Show a notification when a transfer ends',
                          value: settings.transferNotification,
                          onChanged: () => ref
                              .read(settingsProvider.notifier)
                              .setTransferNotification(
                                  !settings.transferNotification),
                        ),
                        const _SectionDivider(),
                        _buildToggleTile(
                          label: 'Sound',
                          subtitle: 'Play a sound when files arrive',
                          value: settings.transferSound,
                          onChanged: () => ref
                              .read(settingsProvider.notifier)
                              .setTransferSound(!settings.transferSound),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection('Appearance', Icons.palette_rounded, [
                      _buildToggleTile(
                        label: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: settings.darkMode,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setDarkMode(!settings.darkMode),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection('Startup', Icons.rocket_launch_rounded, [
                      _buildToggleTile(
                        label: 'Auto Start',
                        subtitle: 'Launch GestureOS when computer starts',
                        value: settings.startOnBoot,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setStartOnBoot(!settings.startOnBoot),
                      ),
                      const _SectionDivider(),
                      _buildToggleTile(
                        label: 'Minimize to Tray',
                        subtitle: 'Keep running in the system tray',
                        value: settings.minimizeToTray,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .setMinimizeToTray(!settings.minimizeToTray),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXl),
                    _buildSection('About', Icons.info_rounded, [
                      _buildAboutTile(
                        label: 'Version',
                        value: '1.0.0',
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXxl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResetPairings(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset all pairings?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'All trusted devices will be removed. They will need to pair again.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await TrustedDeviceManager.instance.resetAll();
    }
  }

  Widget _buildTrustedDevices(WidgetRef ref) {
    final devices = ref.watch(trustedDevicesProvider).valueOrNull ?? [];
    if (devices.isEmpty) {
      return const Text(
        'No trusted devices yet. Devices you connect with are listed here.',
        style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
      );
    }
    return Column(
      children: devices.map((device) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingSm),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMd,
                  ),
                ),
                child: Icon(
                  _platformIcon(device.platform),
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      device.ip.isNotEmpty
                          ? device.ip
                          : '${device.platformLabel} device',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      TrustedDeviceManager.instance.remove(device.id),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.remove_circle_outline_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _platformIcon(DevicePlatform platform) {
    switch (platform) {
      case DevicePlatform.android:
        return Icons.smartphone_rounded;
      case DevicePlatform.iOS:
        return Icons.phone_iphone_rounded;
      case DevicePlatform.windows:
        return Icons.computer_rounded;
      case DevicePlatform.macOS:
        return Icons.desktop_windows_rounded;
      case DevicePlatform.linux:
        return Icons.laptop_rounded;
      case DevicePlatform.web:
        return Icons.language_rounded;
      case DevicePlatform.unknown:
        return Icons.devices_rounded;
    }
  }

  Widget _buildTimeoutSlider({
    required int seconds,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Connection Timeout',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$seconds s',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accent.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: seconds.toDouble(),
            min: 10,
            max: 120,
            divisions: 22,
            label: '$seconds s',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.error, size: 16),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cardHover,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled
                    ? AppColors.textSecondary
                    : AppColors.textTertiary,
                size: 16,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? AppColors.textSecondary
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 15),
            const SizedBox(width: AppDimensions.spacingSm),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingLg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        TextField(
          controller: TextEditingController(text: value),
          onChanged: onChanged,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: AppColors.textTertiary, size: 20)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required String label,
    required String subtitle,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onChanged,
            child: AnimatedContainer(
              duration: AppDimensions.animFast,
              width: 48,
              height: 26,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(13),
              ),
              child: AnimatedAlign(
                duration: AppDimensions.animFast,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutTile({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
      child: Divider(color: AppColors.border, height: 1),
    );
  }
}
