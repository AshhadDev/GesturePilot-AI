import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gesture_os/core/theme/app_colors.dart';
import 'package:gesture_os/shared/models/app_file.dart';

class AnimatedFileCard extends StatelessWidget {
  final AppFile file;
  final double size;
  final double rotation;
  final double elevation;
  final double opacity;
  final bool floating;

  const AnimatedFileCard({
    super.key,
    required this.file,
    this.size = 64,
    this.rotation = 0,
    this.elevation = 1.0,
    this.opacity = 1.0,
    this.floating = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..rotateZ(rotation)
          ..translate(0.0, -math.sin(rotation) * 4),
        child: Container(
          width: size,
          height: size * 1.2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            boxShadow: floating
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15 * elevation),
                      blurRadius: 12 * elevation,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (file.category == FileCategory.images) {
      return _buildImageCard();
    }
    if (file.category == FileCategory.videos) {
      return _buildVideoCard();
    }
    if (file.isImage) {
      return _buildImageCard();
    }
    if (file.isVideo) {
      return _buildVideoCard();
    }
    return _buildGenericCard();
  }

  Widget _buildImageCard() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.surface),
        Icon(Icons.image_rounded, size: size * 0.45, color: AppColors.accent.withValues(alpha: 0.6)),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.overlay, Colors.transparent],
              ),
            ),
            child: Text(
              file.name,
              style: const TextStyle(fontSize: 8, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: AppColors.surface),
        Icon(Icons.movie_rounded, size: size * 0.45, color: AppColors.accent.withValues(alpha: 0.6)),
        Container(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.overlay,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.overlay, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    style: const TextStyle(fontSize: 8, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  file.sizeFormatted,
                  style: const TextStyle(fontSize: 7, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenericCard() {
    final icon = _iconForExtension(file.extension);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.card,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: size * 0.35, color: AppColors.accent.withValues(alpha: 0.7)),
          const SizedBox(height: 2),
          Text(
            file.extension.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.accent.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: Text(
              file.name,
              style: const TextStyle(fontSize: 8, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'doc': case 'docx': return Icons.description_rounded;
      case 'xls': case 'xlsx': return Icons.table_chart_rounded;
      case 'ppt': case 'pptx': return Icons.slideshow_rounded;
      case 'zip': case 'rar': case '7z': return Icons.folder_zip_rounded;
      case 'txt': return Icons.text_snippet_rounded;
      case 'json': case 'xml': return Icons.code_rounded;
      case 'mp3': case 'wav': case 'flac': return Icons.audio_file_rounded;
      case 'fig': return Icons.design_services_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }
}

class FloatingFileCards extends StatefulWidget {
  final List<AppFile> files;
  final double containerWidth;
  final double containerHeight;
  final double scale;
  final bool orbiting;

  const FloatingFileCards({
    super.key,
    required this.files,
    this.containerWidth = double.infinity,
    this.containerHeight = 200,
    this.scale = 1.0,
    this.orbiting = true,
  });

  @override
  State<FloatingFileCards> createState() => _FloatingFileCardsState();
}

class _FloatingFileCardsState extends State<FloatingFileCards>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayFiles = widget.files.take(8).toList();
    if (displayFiles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: widget.containerWidth,
      height: widget.containerHeight * widget.scale,
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, _) {
          final t = _orbitController.value * math.pi * 2;
          return Stack(
            alignment: Alignment.center,
            children: displayFiles.asMap().entries.map((entry) {
              final i = entry.key;
              final file = entry.value;
              final count = displayFiles.length;
              final baseAngle = (i / count) * math.pi * 2;
              final wobble = math.sin(t * 0.7 + i * 1.1) * 0.15;
              final angle = baseAngle + t * 0.2 + wobble;
              final dist = widget.containerHeight * 0.32;
              final x = math.cos(angle) * dist;
              final y = math.sin(angle) * dist * 0.8;
              final scale = 0.7 + (math.sin(t + i * 2.3) * 0.5 + 0.5) * 0.3;
              final rot = math.sin(t * 0.5 + i) * 0.1;

              return Positioned(
                left: widget.containerWidth / 2 + x - 32 * scale,
                top: widget.containerHeight * widget.scale / 2 + y - 38 * scale,
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedFileCard(
                    file: file,
                    size: 56 * scale,
                    rotation: rot,
                    elevation: scale,
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
