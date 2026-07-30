import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/services/trusted_device_manager.dart';

class DevicesDetailScreen extends ConsumerStatefulWidget {
  final Device device;

  const DevicesDetailScreen({super.key, required this.device});

  @override
  ConsumerState<DevicesDetailScreen> createState() => _DevicesDetailScreenState();
}

class _DevicesDetailScreenState extends ConsumerState<DevicesDetailScreen> {
  bool _isTrusted = true;

  @override
  void initState() {
    super.initState();
    _isTrusted = widget.device.isTrusted;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Device Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 32),
              // Device identity
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: _isTrusted
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.card,
                                  AppColors.card,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isTrusted
                              ? AppColors.accent.withValues(alpha: 0.3)
                              : AppColors.border,
                        ),
                        boxShadow: _isTrusted
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.devices_rounded,
                        color: _isTrusted ? Colors.white : AppColors.textSecondary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      d.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.platformLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Info items
              _buildInfoItem('IP Address', d.ip),
              _buildInfoItem('Port', d.port.toString()),
              _buildInfoItem('Status', d.isOnline ? 'Online' : 'Offline'),
              _buildInfoItem('Last Seen', _formatDate(d.lastSeen)),
              _buildInfoItem('ID', d.id.length > 24 ? '${d.id.substring(0, 24)}...' : d.id),
              const SizedBox(height: 32),
              // Actions
              _buildActionTile(
                icon: Icons.edit_rounded,
                title: 'Rename',
                onTap: () => _showRenameDialog(d),
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: _isTrusted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                title: _isTrusted ? 'Revoke Trust' : 'Trust Device',
                subtitle: _isTrusted ? 'Remove from trusted devices' : 'Mark as trusted',
                color: _isTrusted ? AppColors.error : AppColors.success,
                onTap: () => _toggleTrust(d),
              ),
              const SizedBox(height: 8),
              _buildActionTile(
                icon: Icons.delete_forever_rounded,
                title: 'Forget Device',
                subtitle: 'Remove from device list',
                color: AppColors.error,
                onTap: () => _showForgetDialog(d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color color = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
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
                      color: color,
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
          ],
        ),
      ),
    );
  }

  void _toggleTrust(Device d) {
    TrustedDeviceManager.instance.setTrusted(d.id, !_isTrusted);
    setState(() => _isTrusted = !_isTrusted);
  }

  void _showRenameDialog(Device d) {
    final controller = TextEditingController(text: d.name);
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
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                TrustedDeviceManager.instance.rename(d.id, name);
              }
              Navigator.pop(ctx);
            },
            child: Text('Save', style: GoogleFonts.poppins(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showForgetDialog(Device d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          'Forget Device?',
          style: GoogleFonts.poppins(color: AppColors.textPrimary),
        ),
        content: Text(
          'Remove ${d.name} from device list?',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              TrustedDeviceManager.instance.remove(d.id);
              Navigator.pop(ctx);
              context.pop();
            },
            child: Text('Forget', style: GoogleFonts.poppins(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
