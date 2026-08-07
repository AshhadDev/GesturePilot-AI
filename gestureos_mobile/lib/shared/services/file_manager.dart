import 'dart:convert';
import 'dart:io';

import 'package:gesture_os/core/utils/logger.dart';

class FileEntry {
  final String relativePath;
  final String fileName;
  final int fileSize;
  final DateTime lastModified;
  final String mimeType;
  final bool isDirectory;

  const FileEntry({
    required this.relativePath,
    required this.fileName,
    required this.fileSize,
    required this.lastModified,
    this.mimeType = 'application/octet-stream',
    this.isDirectory = false,
  });

  Map<String, dynamic> toJson() => {
    'relative_path': relativePath,
    'file_name': fileName,
    'file_size': fileSize,
    'last_modified': lastModified.toIso8601String(),
    'mime_type': mimeType,
    'is_directory': isDirectory,
  };

  factory FileEntry.fromJson(Map<String, dynamic> json) => FileEntry(
    relativePath: json['relative_path'] as String,
    fileName: json['file_name'] as String,
    fileSize: json['file_size'] as int,
    lastModified: DateTime.parse(json['last_modified'] as String),
    mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
    isDirectory: json['is_directory'] as bool? ?? false,
  );
}

class FileManager {
  FileManager._();
  static final FileManager instance = FileManager._();

  String get _baseDir {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/GestureOS';
    }
    final tmp = Platform.environment['TEMP'] ?? '/tmp';
    return '$tmp/GestureOS';
  }

  Directory get baseDirectory => Directory(_baseDir);

  Future<Directory> ensureBaseDir() async {
    final dir = baseDirectory;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<FileEntry>> scanDirectory(String rootPath, {String prefix = ''}) async {
    final entries = <FileEntry>[];
    final root = Directory(rootPath);
    if (!await root.exists()) return entries;

    try {
      await for (final entity in root.list(recursive: false, followLinks: false)) {
        final relativePath = prefix.isEmpty ? entity.path.split(Platform.pathSeparator).last : '$prefix/${entity.path.split(Platform.pathSeparator).last}';

        if (entity is File) {
          final stat = await entity.stat();
          entries.add(FileEntry(
            relativePath: relativePath,
            fileName: entity.path.split(Platform.pathSeparator).last,
            fileSize: stat.size,
            lastModified: stat.modified,
            mimeType: _guessMimeType(entity.path),
          ));
        } else if (entity is Directory) {
          entries.add(FileEntry(
            relativePath: relativePath,
            fileName: entity.path.split(Platform.pathSeparator).last,
            fileSize: 0,
            lastModified: DateTime.now(),
            isDirectory: true,
          ));
          final sub = await scanDirectory(entity.path, prefix: relativePath);
          entries.addAll(sub);
        }
      }
    } catch (e) {
      AppLogger.warning('[FileManager] scan error: $e');
    }

    return entries;
  }

  Future<List<FileEntry>> scanFiles(List<String> paths) async {
    final entries = <FileEntry>[];
    for (final path in paths) {
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.file) {
        final file = File(path);
        final stat = await file.stat();
        entries.add(FileEntry(
          relativePath: path.split(Platform.pathSeparator).last,
          fileName: path.split(Platform.pathSeparator).last,
          fileSize: stat.size,
          lastModified: stat.modified,
          mimeType: _guessMimeType(path),
        ));
      } else if (entity == FileSystemEntityType.directory) {
        final sub = await scanDirectory(path);
        entries.addAll(sub);
      }
    }
    return entries;
  }

  Future<File> createOutputFile(String relativePath) async {
    final base = await ensureBaseDir();
    final file = File('${base.path}/$relativePath');
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return file;
  }

  String _guessMimeType(String path) {
    final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'mp4': return 'video/mp4';
      case 'mov': return 'video/quicktime';
      case 'avi': return 'video/x-msvideo';
      case 'mkv': return 'video/x-matroska';
      case 'mp3': return 'audio/mpeg';
      case 'wav': return 'audio/wav';
      case 'pdf': return 'application/pdf';
      case 'zip': return 'application/zip';
      case 'tar': case 'gz': return 'application/gzip';
      case 'json': return 'application/json';
      case 'txt': return 'text/plain';
      case 'html': case 'htm': return 'text/html';
      default: return 'application/octet-stream';
    }
  }
}

class ResumeIndex {
  final String filePath;
  final int fileSize;
  final Set<int> receivedChunks;
  final String transferId;

  ResumeIndex({
    required this.filePath,
    required this.fileSize,
    required this.receivedChunks,
    required this.transferId,
  });

  String get indexFilePath => '$filePath.gidx';

  double get progress => fileSize > 0 ? receivedChunks.length / ((fileSize + 65535) ~/ 65536) : 0.0;

  Map<String, dynamic> toJson() => {
    'file_path': filePath,
    'file_size': fileSize,
    'received_chunks': receivedChunks.toList(),
    'transfer_id': transferId,
  };

  factory ResumeIndex.fromJson(Map<String, dynamic> json) => ResumeIndex(
    filePath: json['file_path'] as String,
    fileSize: json['file_size'] as int,
    receivedChunks: Set<int>.from(json['received_chunks'] as List),
    transferId: json['transfer_id'] as String,
  );

  Future<void> save() async {
    final file = File(indexFilePath);
    await file.writeAsString(json.encode(toJson()));
  }

  static Future<ResumeIndex?> load(String indexFilePath, String transferId) async {
    try {
      final file = File(indexFilePath);
      if (!await file.exists()) return null;
      final data = json.decode(await file.readAsString()) as Map<String, dynamic>;
      final idx = ResumeIndex.fromJson(data);
      if (idx.transferId != transferId) return null;
      return idx;
    } catch (e) {
      AppLogger.warning('[ResumeIndex] load error: $e');
      return null;
    }
  }

  static Future<void> remove(String indexFilePath) async {
    try {
      final file = File(indexFilePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
