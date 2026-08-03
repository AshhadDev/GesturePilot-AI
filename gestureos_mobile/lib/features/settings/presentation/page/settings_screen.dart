import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/app/router/route_names.dart';
import 'package:gesture_os/core/services/device_info_service.dart';
import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/providers/device_providers.dart';
import 'package:gesture_os/shared/services/clipboard_service.dart';
import 'package:gesture_os/shared/services/discovery_service.dart';
import 'package:gesture_os/shared/services/settings_service.dart';
import 'package:gesture_os/shared/services/network_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _settings = SettingsService.instance;
  bool _loaded = false;

  // Local mirrors of settings for immediate UI reflection
  bool _autoDiscover = true;
  bool _autoAcceptTrusted = false;
  bool _clipboardSync = false;
  String _theme = 'dark';
  String _animationQuality = 'high';
  double _gestureSensitivity = 0.5;
  bool _debugMode = false;
  bool _discoveryVisible = true;
  bool _autoOpenFiles = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _settings.load();
    if (!mounted) return;
    setState(() {
      _autoDiscover = _settings.autoDiscover;
      _autoAcceptTrusted = _settings.autoAcceptTrusted;
      _clipboardSync = _settings.clipboardSync;
      _theme = _settings.theme;
      _animationQuality = _settings.animationQuality;
      _gestureSensitivity = _settings.gestureSensitivity;
      _debugMode = _settings.debugMode;
      _discoveryVisible = _settings.discoveryVisible;
      _autoOpenFiles = _settings.autoOpenFiles;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localAsync = ref.watch(localDeviceInfoProvider);
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
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
              value: _autoDiscover,
              onChanged: (v) {
                setState(() => _autoDiscover = v);
                _settings.setAutoDiscover(v);
                if (v) {
                  DiscoveryService.instance.start();
                } else {
                  DiscoveryService.instance.stop();
                }
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.visibility_rounded,
            title: 'Visible to others',
            subtitle: 'Respond to discovery requests',
            trailing: Switch(
              value: _discoveryVisible,
              onChanged: (v) {
                setState(() => _discoveryVisible = v);
                _settings.setDiscoveryVisible(v);
              },
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
            onTap: () => _showFolderPicker(context),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.wifi_protected_setup_rounded,
            title: 'Auto-accept from trusted devices',
            trailing: Switch(
              value: _autoAcceptTrusted,
              onChanged: (v) {
                setState(() => _autoAcceptTrusted = v);
                _settings.setAutoAcceptTrusted(v);
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.folder_open_rounded,
            title: 'Auto-open received files',
            trailing: Switch(
              value: _autoOpenFiles,
              onChanged: (v) {
                setState(() => _autoOpenFiles = v);
                _settings.setAutoOpenFiles(v);
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Sync'),
          _buildTile(
            icon: Icons.content_paste_rounded,
            title: 'Clipboard Sync',
            subtitle: 'Share clipboard with trusted devices',
            trailing: Switch(
              value: _clipboardSync,
              onChanged: (v) {
                setState(() => _clipboardSync = v);
                _settings.setClipboardSync(v);
                ClipboardSyncService.instance.setEnabled(v);
                if (v) {
                  ClipboardSyncService.instance.startWatching();
                } else {
                  ClipboardSyncService.instance.stopWatching();
                }
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Appearance'),
          _buildTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: _theme == 'dark' ? 'Dark' : 'Light',
            onTap: () => _showThemePicker(context),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.animation_rounded,
            title: 'Animation Quality',
            subtitle: _animationQuality == 'high'
                ? 'High'
                : _animationQuality == 'medium'
                    ? 'Medium'
                    : 'Low',
            onTap: () => _showAnimationQualityPicker(context),
          ),
          const SizedBox(height: 24),
          _buildSection('Gestures'),
          _buildTile(
            icon: Icons.touch_app_rounded,
            title: 'Gesture Sensitivity',
            subtitle: '${(_gestureSensitivity * 100).toInt()}%',
            onTap: () => _showSensitivitySlider(context),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.bug_report_rounded,
            title: 'Debug Mode',
            subtitle: 'Show gesture debug overlay',
            trailing: Switch(
              value: _debugMode,
              onChanged: (v) {
                setState(() => _debugMode = v);
                _settings.setDebugMode(v);
              },
              activeTrackColor: AppColors.primary,
              activeThumbColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildSection('Advanced'),
          _buildTile(
            icon: Icons.speed_rounded,
            title: 'Performance Dashboard',
            subtitle: 'Live FPS, memory, network metrics',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            onTap: () => context.pushNamed(RouteNames.performanceDashboard),
          ),
          const SizedBox(height: 8),
          _buildTile(
            icon: Icons.history_rounded,
            title: 'Transfer History',
            subtitle: 'View past file transfers',
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
            onTap: () => context.pushNamed(RouteNames.transferHistory),
          ),
        ],
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
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await DeviceInfoService.instance.setDeviceName(name);
                // Invalidate provider so UI reflects name change
                ref.invalidate(localDeviceInfoProvider);
                // Update running services
                DiscoveryService.instance.notifyNameChange(name);
                NetworkService.instance.notifyNameChange(name);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.card,
        title: Text('Theme', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        children: ['dark', 'light'].map((t) => SimpleDialogOption(
          onPressed: () {
            setState(() => _theme = t);
            _settings.setTheme(t);
            Navigator.pop(ctx);
          },
          child: Text(
            t == 'dark' ? 'Dark' : 'Light',
            style: GoogleFonts.poppins(color: AppColors.textPrimary),
          ),
        )).toList(),
      ),
    );
  }

  void _showAnimationQualityPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.card,
        title: Text('Animation Quality', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        children: ['high', 'medium', 'low'].map((q) => SimpleDialogOption(
          onPressed: () {
            setState(() => _animationQuality = q);
            _settings.setAnimationQuality(q);
            Navigator.pop(ctx);
          },
          child: Text(
            q == 'high' ? 'High' : q == 'medium' ? 'Medium' : 'Low',
            style: GoogleFonts.poppins(color: AppColors.textPrimary),
          ),
        )).toList(),
      ),
    );
  }

  void _showSensitivitySlider(BuildContext context) {
    double tempValue = _gestureSensitivity;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('Gesture Sensitivity', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(tempValue * 100).toInt()}%',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Slider(
                value: tempValue,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                activeColor: AppColors.primary,
                onChanged: (v) => setDialogState(() => tempValue = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                setState(() => _gestureSensitivity = tempValue);
                _settings.setGestureSensitivity(tempValue);
                Navigator.pop(ctx);
              },
              child: Text('Save', style: GoogleFonts.poppins(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFolderPicker(BuildContext context) {
    // On Android, the transfer folder is fixed. On desktop, we could use a directory picker.
    // For now, show an info dialog.
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Download Location', style: GoogleFonts.poppins(color: AppColors.textPrimary)),
        content: Text(
          'Files are saved to /GestureOS/ in your storage.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins(color: AppColors.primary)),
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
}
