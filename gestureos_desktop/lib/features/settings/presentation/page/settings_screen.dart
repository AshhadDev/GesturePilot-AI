import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/core/widgets/desktop_app_bar.dart';
import 'package:gestureos_desktop/shared/providers/mock_providers.dart';

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
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('General', [
                      _buildTextField(
                        label: 'Desktop Name',
                        value: settings.desktopName,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setDesktopName(v),
                      ),
                      const SizedBox(height: AppDimensions.spacingMd),
                      _buildTextField(
                        label: 'Download Folder',
                        value: settings.downloadFolder,
                        onChanged: (v) => ref
                            .read(settingsProvider.notifier)
                            .setDownloadFolder(v),
                        suffixIcon: Icons.folder_open_rounded,
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    _buildSection('Appearance', [
                      _buildToggleTile(
                        label: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: settings.darkMode,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .toggleDarkMode(),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    _buildSection('Startup', [
                      _buildToggleTile(
                        label: 'Auto Start',
                        subtitle: 'Launch GestureOS when computer starts',
                        value: settings.autoStart,
                        onChanged: () => ref
                            .read(settingsProvider.notifier)
                            .toggleAutoStart(),
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    _buildSection('Camera', [
                      _buildCameraPlaceholder(),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXxl),
                    _buildSection('About', [
                      _buildAboutTile(
                        label: 'Version',
                        value: '1.0.0 (UI Only)',
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
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

  Widget _buildCameraPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            color: AppColors.textTertiary,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Camera not available in UI-only mode',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
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
