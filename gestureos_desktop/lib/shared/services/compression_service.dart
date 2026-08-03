import 'dart:io';

import 'package:gestureos_desktop/core/utils/logger.dart';

class CompressionService {
  CompressionService._();
  static final CompressionService instance = CompressionService._();

  static const _compressibleExtensions = {
    'txt', 'json', 'pdf', 'csv', 'xml', 'log', 'logs',
    'md', 'html', 'htm', 'css', 'js', 'ts', 'dart', 'py',
    'yaml', 'yml', 'toml', 'ini', 'cfg', 'conf',
    'sql', 'sh', 'bat', 'ps1', 'rb', 'go', 'rs',
    'tex', 'rst', 'org',
  };

  static const _alreadyCompressed = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'tiff', 'ico',
    'mp4', 'avi', 'mkv', 'mov', 'wmv', 'flv', 'webm',
    'mp3', 'aac', 'wav', 'flac', 'ogg', 'wma', 'm4a',
    'zip', 'gz', 'bz2', 'xz', '7z', 'rar', 'tar',
    'pdf', 'docx', 'xlsx', 'pptx',
  };

  bool isCompressible(String extension) {
    final ext = extension.toLowerCase().trim();
    return _compressibleExtensions.contains(ext);
  }

  bool isAlreadyCompressed(String extension) {
    final ext = extension.toLowerCase().trim();
    return _alreadyCompressed.contains(ext);
  }

  String? _ext(String path) {
    return path.contains('.') ? path.split('.').last : null;
  }

  List<int>? compressBytes(String filePath, List<int> bytes) {
    final ext = _ext(filePath);
    if (ext == null) return null;
    if (isAlreadyCompressed(ext)) return null;
    if (!isCompressible(ext)) return null;
    if (bytes.isEmpty) return null;

    final compressed = gzip.encode(bytes);
    if (compressed.length >= bytes.length) return null;

    final savings = ((bytes.length - compressed.length) / bytes.length * 100);
    AppLogger.info(
      'Compressed $filePath: ${bytes.length}B -> ${compressed.length}B (${savings.toStringAsFixed(1)}% saved)',
    );
    return compressed;
  }

  List<int> decompressBytes(List<int> bytes) {
    if (bytes.length > 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return gzip.decode(bytes);
    }
    return bytes;
  }

  Future<CompressionResult?> compressFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final ext = _ext(filePath);
    if (ext == null) return null;
    if (isAlreadyCompressed(ext)) return null;
    if (!isCompressible(ext)) return null;

    final originalSize = await file.length();
    if (originalSize == 0) return null;

    final stopwatch = Stopwatch()..start();
    final bytes = await file.readAsBytes();
    final compressed = gzip.encode(bytes);
    stopwatch.stop();

    if (compressed.length >= originalSize) return null;

    await file.writeAsBytes(compressed);

    final savings = originalSize - compressed.length;
    final savingsPercent = (savings / originalSize * 100);
    final timeMs = stopwatch.elapsedMilliseconds;

    AppLogger.info(
      'Compressed $filePath: '
      '${(originalSize / 1024).toStringAsFixed(1)}KB -> '
      '${(compressed.length / 1024).toStringAsFixed(1)}KB '
      '(${savingsPercent.toStringAsFixed(1)}% saved in ${timeMs}ms)',
    );

    return CompressionResult(
      originalSize: originalSize,
      compressedSize: compressed.length,
      savingsPercent: savingsPercent,
      timeMs: timeMs,
    );
  }

  Future<List<int>> decompressIfNeeded(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    final bytes = await file.readAsBytes();
    return decompressBytes(bytes);
  }
}

class CompressionResult {
  final int originalSize;
  final int compressedSize;
  final double savingsPercent;
  final int timeMs;

  const CompressionResult({
    required this.originalSize,
    required this.compressedSize,
    required this.savingsPercent,
    required this.timeMs,
  });

  String get savingsLabel =>
      '${savingsPercent.toStringAsFixed(1)}% saved';
}
