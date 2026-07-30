import 'dart:io';

import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/app_file.dart';

/// Service for querying real device files using dart:io.
/// Scans common Android directories for images, videos, and documents.
class FileService {
  const FileService._();

  static Future<List<AppFile>> getFiles(FileCategory category) async {
    try {
      final dirs = await _getDirectoriesForCategory(category);
      final files = <AppFile>[];

      for (final dir in dirs) {
        if (await dir.exists()) {
          final entities = dir.listSync(followLinks: false);
          for (final entity in entities) {
            if (entity is! File) continue;
            final file = _fileFromPath(entity.path);
            if (file == null) continue;
            if (category != FileCategory.all && file.category != category) {
              continue;
            }
            files.add(file);
          }
        }
      }

      files.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      return files;
    } catch (e, st) {
      AppLogger.error('Failed to get files', e, st);
      return [];
    }
  }

  static Future<List<Directory>> _getDirectoriesForCategory(
    FileCategory category,
  ) async {
    final dirs = <Directory>[];

    if (Platform.isAndroid) {
      final storage = '/storage/emulated/0';

      switch (category) {
        case FileCategory.all:
          dirs.addAll([
            Directory('$storage/DCIM'),
            Directory('$storage/Pictures'),
            Directory('$storage/Download'),
            Directory('$storage/Documents'),
            Directory('$storage/Movies'),
          ]);
        case FileCategory.images:
          dirs.addAll([
            Directory('$storage/DCIM'),
            Directory('$storage/Pictures'),
            Directory('$storage/Download'),
          ]);
        case FileCategory.videos:
          dirs.addAll([
            Directory('$storage/DCIM'),
            Directory('$storage/Movies'),
            Directory('$storage/Download'),
          ]);
        case FileCategory.documents:
          dirs.addAll([
            Directory('$storage/Documents'),
            Directory('$storage/Download'),
          ]);
        case FileCategory.downloads:
          dirs.add(Directory('$storage/Download'));
      }
    } else {
      dirs.add(Directory('/tmp'));
    }

    return dirs;
  }

  static AppFile? _fileFromPath(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;

      final stat = file.statSync();
      final name = path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) return null;

      final ext = name.contains('.')
          ? name.split('.').last.toLowerCase()
          : '';

      return AppFile(
        path: path,
        name: name,
        sizeBytes: stat.size,
        extension: ext,
        category: AppFile.categoryFromExtension(ext),
        lastModified: stat.modified,
      );
    } catch (_) {
      return null;
    }
  }

  static List<AppFile> searchFiles(List<AppFile> files, String query) {
    if (query.isEmpty) return files;
    final lower = query.toLowerCase();
    return files.where((f) {
      return f.name.toLowerCase().contains(lower) ||
          f.extension.toLowerCase().contains(lower);
    }).toList();
  }

  static List<AppFile> filterByCategory(
    List<AppFile> files,
    FileCategory category,
  ) {
    if (category == FileCategory.all) return files;
    return files.where((f) => f.category == category).toList();
  }
}
