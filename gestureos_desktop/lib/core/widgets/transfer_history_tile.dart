import 'package:flutter/material.dart';

import 'package:gestureos_desktop/core/theme/app_colors.dart';
import 'package:gestureos_desktop/core/theme/app_dimensions.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';

class TransferHistoryTile extends StatefulWidget {
  const TransferHistoryTile({
    super.key,
    required this.item,
    this.onOpenFile,
    this.onOpenFolder,
  });

  final TransferHistoryItem item;
  final VoidCallback? onOpenFile;
  final VoidCallback? onOpenFolder;

  @override
  State<TransferHistoryTile> createState() => _TransferHistoryTileState();
}

class _TransferHistoryTileState extends State<TransferHistoryTile> {
  bool _isHovered = false;

  IconData _iconForType(FileType type) {
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

  Color _statusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return AppColors.success;
      case TransferStatus.failed:
        return AppColors.error;
      case TransferStatus.inProgress:
        return AppColors.accent;
      case TransferStatus.pending:
        return AppColors.warning;
      case TransferStatus.cancelled:
        return AppColors.textTertiary;
    }
  }

  String _statusLabel(TransferStatus status) {
    switch (status) {
      case TransferStatus.completed:
        return 'Completed';
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

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final statusColor = _statusColor(item.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onDoubleTap: () => widget.onOpenFile?.call(),
        onSecondaryTapUp: (details) => _showContextMenu(details),
        child: AnimatedContainer(
        duration: AppDimensions.animFast,
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.cardHover : AppColors.card,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(
            color: _isHovered
                ? AppColors.borderLight
                : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Icon(
                _iconForType(item.fileType),
                color: AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.fileName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'From ${item.senderDevice}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                item.sizeFormatted,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  _statusLabel(item.status),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(
              flex: 1,
              child: Text(
                _formatTime(item.timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
