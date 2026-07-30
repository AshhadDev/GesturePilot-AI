import 'dart:io';

import 'package:gesture_os/core/utils/logger.dart';

/// Auto-compresses files before transfer.
///
/// Skips already-compressed formats (images, videos, audio, archives).
/// Compresses text-based formats (txt, json, pdf, csv, xml, logs, md, html, css, js).
/// Reports compression ratio and time saved.
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

  /// Compresses a file in-place using gzip.
  /// Returns compression stats or null if skipped.
  Future<CompressionResult?> compressFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final ext = filePath.contains('.')
        ? filePath.split('.').last
        : '';

    if (isAlreadyCompressed(ext)) return null;
    if (!isCompressible(ext)) return null;

    final originalSize = await file.length();
    if (originalSize == 0) return null;

    final stopwatch = Stopwatch()..start();
    final bytes = await file.readAsBytes();
    final compressed = gzip.encode(bytes);
    stopwatch.stop();

    // Only save if compression actually reduces size
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

  /// Returns decompressed bytes from a possibly-gzip file.
  Future<List<int>> decompressIfNeeded(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];

    final bytes = await file.readAsBytes();
    // Check gzip magic bytes
    if (bytes.length > 2 && bytes[0] == 0x1F && bytes[1] == 0x8B) {
      return gzip.decode(bytes);
    }
    return bytes;
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
