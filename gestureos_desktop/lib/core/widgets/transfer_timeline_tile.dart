import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';

class TransferTimelineTile extends StatefulWidget {
  const TransferTimelineTile({
    super.key,
    required this.item,
    this.isLast = false,
    this.onOpenFile,
    this.onOpenFolder,
  });

  final TransferHistoryItem item;
  final bool isLast;
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenFolder;

  @override
  State<TransferTimelineTile> createState() => _TransferTimelineTileState();
}

class _TransferTimelineTileState extends State<TransferTimelineTile> {
  bool _isHovered = false;

  static IconData _iconForType(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image_rounded;
      case FileType.video:
        return Icons.videocam_rounded;
      case FileType.document:
        return Icons.description_rounded;
      case FileType.audio:
        return Icons.audiotrack_rounded;
      case FileType.other:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final success = item.status == TransferStatus.completed;
    final accent = success ? AppColors.success : AppColors.error;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMd),
          Expanded(
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onDoubleTap: widget.onOpenFile,
                onSecondaryTapUp: widget.onOpenFolder != null
                    ? (details) => _showContextMenu(details)
                    : null,
                child: AnimatedContainer(
                  duration: AppDimensions.animFast,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(AppDimensions.spacingMd),
                  decoration: BoxDecoration(
                    color: _isHovered
                        ? AppColors.cardHover
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLg,
                    ),
                    border: Border.all(
                      color: _isHovered
                          ? AppColors.borderLight
                          : AppColors.border,
                      width: 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMd,
                          ),
                        ),
                        child: Icon(
                          _iconForType(item.fileType),
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.fileName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (success) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: AppDimensions.spacingMd,
                              runSpacing: 4,
                              children: [
                                _meta(
                                  Icons.phone_android_rounded,
                                  item.senderDevice,
                                ),
                                _meta(Icons.schedule_rounded,
                                    _formatTime(item.timestamp)),
                                _meta(
                                  Icons.timer_outlined,
                                  item.durationFormatted,
                                ),
                                _meta(Icons.speed_rounded,
                                    item.speedFormatted),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item.sizeFormatted,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              success ? 'Received' : _statusLabel(item.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return 'Received';
      case TransferStatus.failed:
        return 'Failed';
      case TransferStatus.inProgress:
        return 'In Progress';
      case TransferStatus.pending:
        return 'Pending';
      case TransferStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 13),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(TapUpDetails details) {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    showMenu<int>(
      context: context,
      position: RelativeRect.fromRect(
        details.globalPosition & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
      color: AppColors.surface,
      items: [
        if (widget.onOpenFile != null)
          const PopupMenuItem<int>(
            value: 0,
            child: ListTile(
              leading: Icon(Icons.open_in_new_rounded),
              title: Text('Open File'),
            ),
          ),
        if (widget.onOpenFolder != null)
          const PopupMenuItem<int>(
            value: 1,
            child: ListTile(
              leading: Icon(Icons.folder_open_rounded),
              title: Text('Open Containing Folder'),
            ),
          ),
      ],
    ).then((value) {
      if (value == null) return;
      if (value == 0) widget.onOpenFile?.call();
      if (value == 1) widget.onOpenFolder?.call();
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
