import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/providers/device_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localAsync = ref.watch(localDeviceInfoProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection('Device'),
          _buildTile(
            icon: Icons.edit_rounded,
            title: 'Device Name',
            subtitle: localAsync.valueOrNull?.name ?? 'GestureOS Device',
            onTap: () => _showRenameDialog(context),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          const SizedBox(height: 24),
          _buildSection('Discovery'),
          _buildTile(
            icon: Icons.wifi_find_rounded,
            title: 'Auto-discover devices',
            subtitle: 'Find devices on your network',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Transfers'),
          _buildTile(
            icon: Icons.folder_rounded,
            title: 'Download Location',
            subtitle: '/Downloads/GestureOS',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.wifi_protected_setup_rounded,
            title: 'Auto-accept from trusted devices',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Appearance'),
          _buildTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: 'Dark',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.animation_rounded,
            title: 'Animation Quality',
            subtitle: 'High',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Rename Device',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
