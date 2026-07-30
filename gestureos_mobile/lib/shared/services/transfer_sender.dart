import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:gesture_os/core/utils/logger.dart';
import 'package:gesture_os/shared/models/app_file.dart';
import 'package:gesture_os/shared/models/device_model.dart';
import 'package:gesture_os/shared/protocol/frame_parser.dart';
import 'package:gesture_os/shared/protocol/protocol.dart';
import 'package:gesture_os/shared/services/file_manager.dart';
import 'package:gesture_os/shared/services/network_service.dart';
import 'package:gesture_os/shared/services/transfer_service.dart';

class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

class TransferSender {
  FrameParser? _parser;
  int _transferId = 0;
  int _totalBytes = 0;
  int _transferredBytes = 0;
  bool _cancelled = false;

  void cancel() {
    _cancelled = true;
    try {
      _parser?.sendJson(MessageType.cancel, _transferId, {
        'transfer_id': _transferId.toString(),
      });
    } catch (_) {}
  }

  Future<SendResult> sendFiles({
    required List<AppFile> files,
    required Device target,
    required void Function(TransferProgress) onProgress,
  }) async {
    _cancelled = false;
    _transferId = DateTime.now().microsecondsSinceEpoch;
    _totalBytes = files.fold<int>(0, (s, f) => s + f.sizeBytes);
    _transferredBytes = 0;

    onProgress(TransferProgress(
        progress: 0,
        status: 'connecting',
        currentFileName: 'Connecting to ${target.name}...'));

    final conn =
        await NetworkService.instance.connect(target.ip, port: target.port);
    if (conn == null) {
      return SendResult(false, 'Could not connect to ${target.name}');
    }

    _parser = FrameParser(conn);
    _parser!.start();

    try {
      final handshakeOk = await _doHandshake(target, onProgress);
      if (!handshakeOk) return SendResult(false, 'Handshake failed');

      final fileEntries = await _collectFileEntries(files);

      final requestOk = await _sendTransferRequest(fileEntries, onProgress);
      if (!requestOk) return SendResult(false, 'Transfer rejected');

      for (int i = 0; i < fileEntries.length; i++) {
        if (_cancelled) return SendResult(false, 'Cancelled by user');

        final entry = fileEntries[i];
        final fileOk =
            await _sendFile(entry, i, fileEntries.length, onProgress);
        if (!fileOk) {
          return SendResult(false, 'Failed to send ${entry.fileName}');
        }
      }

      if (_cancelled) return SendResult(false, 'Cancelled by user');

      _parser!.sendJson(MessageType.complete, _transferId, {
        'transfer_id': _transferId,
        'total_files': fileEntries.length,
        'total_bytes': _totalBytes,
      });

      final ack =
          await _parser!.waitForAck(_transferId, timeout: const Duration(seconds: 15));
      if (ack == null) {
        return SendResult(false, 'No completion acknowledgment');
      }

      onProgress(TransferProgress(
        progress: 1.0,
        status: 'completed',
        currentFileName: 'Transfer complete',
        totalBytes: _totalBytes,
        transferredBytes: _totalBytes,
      ));

      return const SendResult(true);
    } catch (e) {
      AppLogger.error('[Sender] Error', e);
      return SendResult(false, 'Transfer failed: $e');
    } finally {
      NetworkService.instance.disconnect(conn.id);
      _parser?.close();
    }
  }

  Future<bool> _doHandshake(
      Device target, void Function(TransferProgress) onProgress) async {
    _parser!.sendJson(MessageType.hello, _transferId, {
      'device_name': Platform.localHostname,
      'protocol_version': ProtocolConstants.version,
    });

    final reply =
        await _parser!.waitForFrame(MessageType.hello, timeout: Duration(seconds: 10));
    return reply != null;
  }

  Future<List<FileEntry>> _collectFileEntries(List<AppFile> files) async {
    final entries = <FileEntry>[];
    for (final file in files) {
      final entityType = FileSystemEntity.typeSync(file.path);
      if (entityType == FileSystemEntityType.directory) {
        final sub = await FileManager.instance.scanDirectory(file.path);
        entries.addAll(sub);
      } else {
        final stat = await File(file.path).stat();
        entries.add(FileEntry(
          relativePath: file.name,
          fileName: file.name,
          fileSize: file.sizeBytes,
          lastModified: stat.modified,
          mimeType: 'application/octet-stream',
        ));
      }
    }
    return entries;
  }

  Future<bool> _sendTransferRequest(List<FileEntry> entries,
      void Function(TransferProgress) onProgress) async {
    onProgress(TransferProgress(
        progress: 0,
        status: 'handshaking',
        currentFileName: 'Sending file list...'));

    final fileMetas = entries.map((e) => e.toJson()).toList();

    _parser!.sendJson(MessageType.transferRequest, _transferId, {
      'transfer_id': _transferId.toString(),
      'device_name': Platform.localHostname,
      'total_files': entries.length,
      'total_bytes': _totalBytes,
      'files': fileMetas,
    });

    final accept =
        await _parser!.waitForFrame(MessageType.transferAccept, timeout: const Duration(seconds: 30));
    if (accept == null) {
      final reject =
          await _parser!.waitForFrame(MessageType.transferReject, timeout: Duration.zero);
      if (reject != null) {
        final msg = reject.jsonPayload?['reason'] ?? 'Rejected';
        AppLogger.warning('[Sender] Transfer rejected: $msg');
      }
      return false;
    }
    return true;
  }

  Future<bool> _sendFile(FileEntry entry, int fileIndex, int totalFiles,
      void Function(TransferProgress) onProgress) async {
    if (entry.isDirectory) return true;

    final realPath = entry.relativePath;
    final file = File(realPath);
    if (!await file.exists()) {
      AppLogger.warning('[Sender] File not found: $realPath');
      return false;
    }

    final fileSize = await file.length();
    final totalChunks =
        (fileSize + ProtocolConstants.defaultChunkSize - 1) ~/ ProtocolConstants.defaultChunkSize;

    _parser!.sendJson(MessageType.fileStart, _transferId, {
      'file_index': fileIndex,
      'file_name': entry.fileName,
      'relative_path': entry.relativePath,
      'file_size': fileSize,
      'total_chunks': totalChunks,
      'last_modified': entry.lastModified.toIso8601String(),
      'mime_type': entry.mimeType,
    });

    onProgress(TransferProgress(
      progress: _totalBytes > 0 ? _transferredBytes / _totalBytes : 0,
      status: 'transferring',
      currentFileName: entry.fileName,
      currentFileIndex: fileIndex,
      totalFiles: totalFiles,
      totalBytes: _totalBytes,
      transferredBytes: _transferredBytes,
    ));

    final digestSink = _DigestSink();
    final digester = sha256.startChunkedConversion(digestSink);

    try {
      final stream = file.openRead();
      int chunkIndex = 0;
      int fileBytesRead = 0;
      final chunkBuffer = <int>[];

      await for (final data in stream) {
        digester.add(data);
        chunkBuffer.addAll(data);

        while (chunkBuffer.length >= ProtocolConstants.defaultChunkSize ||
            (chunkBuffer.isNotEmpty &&
                fileBytesRead + chunkBuffer.length >= fileSize &&
                chunkBuffer.length <= ProtocolConstants.defaultChunkSize)) {
          final take = chunkBuffer.length > ProtocolConstants.defaultChunkSize
              ? ProtocolConstants.defaultChunkSize
              : chunkBuffer.length;
          final chunk = Uint8List.fromList(chunkBuffer.sublist(0, take));
          chunkBuffer.removeRange(0, take);

          _parser!.sendBinary(MessageType.fileChunk, _transferId, chunk,
              chunkIndex: chunkIndex);

          _transferredBytes += take;
          fileBytesRead += take;

          onProgress(TransferProgress(
            progress: _totalBytes > 0 ? _transferredBytes / _totalBytes : 0,
            status: 'transferring',
            currentFileName: entry.fileName,
            currentFileIndex: fileIndex,
            totalFiles: totalFiles,
            totalBytes: _totalBytes,
            transferredBytes: _transferredBytes,
            currentChunk: chunkIndex,
            totalChunks: totalChunks,
          ));

          chunkIndex++;
        }
      }

      if (chunkBuffer.isNotEmpty) {
        final chunk = Uint8List.fromList(chunkBuffer);
        _parser!.sendBinary(MessageType.fileChunk, _transferId, chunk,
            chunkIndex: chunkIndex);
        _transferredBytes += chunk.length;
        chunkIndex++;
      }

      digester.close();
    } catch (e) {
      digester.close();
      AppLogger.warning('[Sender] Read error for ${entry.fileName}: $e');
      return false;
    }

    final hashB64 = base64.encode(digestSink.digest!.bytes);

    _parser!.sendJson(MessageType.fileEnd, _transferId, {
      'file_index': fileIndex,
      'total_chunks': totalChunks,
      'file_size': fileSize,
    });

    final ack =
        await _parser!.waitForAck(_transferId);
    if (ack == null) {
      AppLogger.warning('[Sender] No ACK for file end: ${entry.fileName}');
      return false;
    }

    _parser!.sendJson(MessageType.fileChecksum, _transferId, {
      'file_index': fileIndex,
      'checksum': hashB64,
      'file_name': entry.fileName,
    });

    final verify =
        await _parser!.waitForAck(_transferId, timeout: const Duration(seconds: 30));
    if (verify == null) {
      AppLogger.warning('[Sender] No verification ACK for ${entry.fileName}');
      return false;
    }

    final verifyPayload = verify.jsonPayload;
    if (verifyPayload?['status'] == 'mismatch') {
      AppLogger.warning('[Sender] Checksum mismatch for ${entry.fileName}');
      return false;
    }

    AppLogger.info('[Sender] File verified: ${entry.fileName}');
    return true;
  }
}

class SendResult {
  final bool success;
  final String? error;

  const SendResult(this.success, [this.error]);
}
