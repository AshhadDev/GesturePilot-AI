class AppFile {
  const AppFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.extension,
    required this.category,
    required this.lastModified,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String extension;
  final FileCategory category;
  final DateTime lastModified;

  String get sizeFormatted => _formatBytes(sizeBytes);

  bool get isImage =>
      category == FileCategory.images;
  bool get isVideo =>
      category == FileCategory.videos;

  AppFile copyWith({bool? isSelected}) {
    return AppFile(
      path: path,
      name: name,
      sizeBytes: sizeBytes,
      extension: extension,
      category: category,
      lastModified: lastModified,
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  static FileCategory categoryFromExtension(String ext) {
    final lower = ext.toLowerCase();
    const imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg', 'heic', 'heif'};
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'flv', 'wmv', '3gp'};
    const docExts = {
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'txt', 'csv', 'json', 'xml', 'zip', 'rar', '7z', 'fig',
    };

    if (imageExts.contains(lower)) return FileCategory.images;
    if (videoExts.contains(lower)) return FileCategory.videos;
    if (docExts.contains(lower)) return FileCategory.documents;
    return FileCategory.documents;
  }
}

enum FileCategory {
  all,
  images,
  videos,
  documents,
  downloads,
}
