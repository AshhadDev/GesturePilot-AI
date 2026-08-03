import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:gestureos_desktop/core/utils/logger.dart';
import 'package:gestureos_desktop/shared/models/device_model.dart';
import 'package:gestureos_desktop/shared/protocol/frame_parser.dart';
import 'package:gestureos_desktop/shared/protocol/protocol.dart';
import 'package:gestureos_desktop/shared/services/compression_service.dart';
import 'package:gestureos_desktop/shared/services/encryption_service.dart';
import 'package:gestureos_desktop/shared/services/file_manager.dart';
import 'package:gestureos_desktop/shared/services/network_service.dart';
import 'package:gestureos_desktop/shared/services/qr_pairing_service.dart';
import 'package:gestureos_desktop/shared/services/transfer_service.dart';
import 'package:gestureos_desktop/shared/services/trusted_device_manager.dart';

class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) {
    digest = data;
  }

  @override
  void close() {}
}

class _IncrementalHash {
  final _DigestSink _sink = _DigestSink();
  late final Sink<List<int>> _input;

  _IncrementalHash() {
    _input = sha256.startChunkedConversion(_sink);
  }

  void add(List<int> data) => _input.add(data);
  void close() => _input.close();
  Digest get digest => _sink.digest!;
}

class _ReceivedFile {
  final String fileName;
  final String relativePath;
  final int fileSize;
  final int totalChunks;
  final bool compressed;
  final bool encrypted;
  int chunksReceived = 0;
  int bytesReceived = 0;
  final RandomAccessFile outputFile;
  final _IncrementalHash hasher;

  _ReceivedFile({
    required this.fileName,
    required this.relativePath,
    required this.fileSize,
    required this.totalChunks,
    required this.compressed,
    required this.encrypted,
    required this.outputFile,
    required this.hasher,
  });
}

class TransferReceiver {
  static bool autoAcceptTrusted = false;

  final StreamController<TransferProgress> _progressController =
      StreamController<TransferProgress>.broadcast();

  Stream<TransferProgress> get progressStream => _progressController.stream;

  Future<void> handleConnection(
    TcpConnection conn, {
    void Function(TransferCompletionEvent)? onComplete,
  }) async {
    final parser = FrameParser(conn);
    parser.start();
    final startedAt = DateTime.now();

    String? transferId;
    String? remoteName = 'Unknown';
    List<FileEntry>? pendingFiles;
    int totalBytes = 0;
    int transferredBytes = 0;
    int fileIndex = 0;
    _ReceivedFile? currentFile;

    void emitProgress({
      double? progress,
      String status = 'transferring',
      String currentFileName = '',
      int currentFileIndex = 0,
      int totalFiles = 1,
      int? transferredBytes,
      int? totalBytes,
      String? error,
    }) {
      _progressController.add(TransferProgress(
        progress: progress ??
            ((totalBytes ?? 0) > 0
                ? (transferredBytes ?? 0) / (totalBytes ?? 1)
                : 0),
        status: status,
        currentFileName: currentFileName,
        currentFileIndex: currentFileIndex,
        totalFiles: totalFiles,
        transferredBytes: transferredBytes ?? 0,
        totalBytes: totalBytes ?? 0,
        error: error,
      ));
    }

    try {
      await for (final frame in parser.frames) {
        if (frame.messageType == MessageType.hello) {
          final payload = frame.jsonPayload;
          remoteName = payload?['device_name'] as String? ?? 'Unknown';
          parser.sendJson(MessageType.hello, frame.transferId, {
            'device_name': Platform.localHostname,
            'protocol_version': ProtocolConstants.version,
          });
          await _maybeHandleQrSession(payload, conn);
          AppLogger.info('[Receiver] Handshake with $remoteName');
        } else if (frame.messageType == MessageType.transferRequest) {
          final payload = frame.jsonPayload;
          transferId = payload?['transfer_id'] as String?;
          final filesRaw = payload?['files'] as List<dynamic>? ?? [];
          totalBytes = payload?['total_bytes'] as int? ?? 0;
          pendingFiles = filesRaw
              .map((e) => FileEntry.fromJson(e as Map<String, dynamic>))
              .toList();
          transferredBytes = 0;

          final isTrusted = TrustedDeviceManager.instance.isTrustedByAddress(
            conn.remoteHost,
          );

          final autoAccepted = autoAcceptTrusted && isTrusted;
          if (!autoAccepted && autoAcceptTrusted) {
            AppLogger.info(
                '[Receiver] Transfer from $remoteName requires user confirmation');
          }

          parser.sendJson(MessageType.transferAccept, frame.transferId, {
            'transfer_id': transferId,
            'status': 'accepted',
          });

          emitProgress(
            status: 'connecting',
            currentFileName: 'Receiving from $remoteName...',
            totalFiles: pendingFiles.length,
            totalBytes: totalBytes,
          );

          AppLogger.info(
              '[Receiver] Accept: $transferId from $remoteName (${pendingFiles.length} files)');
        } else if (frame.messageType == MessageType.cancel) {
          AppLogger.info('[Receiver] Cancelled by sender');
          final file = currentFile;
          if (file != null) await file.outputFile.close();
          currentFile = null;
          emitProgress(status: 'failed', error: 'Cancelled by sender');
          break;
        } else if (frame.messageType == MessageType.fileStart) {
          if (currentFile != null) {
            await currentFile.outputFile.close();
          }

          final payload = frame.jsonPayload;
          if (payload == null) continue;

          final fileName = payload['file_name'] as String? ?? 'unknown';
          final relativePath =
              payload['relative_path'] as String? ?? fileName;
          final fileSize = payload['file_size'] as int? ?? 0;
          final totalChunks = payload['total_chunks'] as int? ?? 1;
          final compressed = payload['compressed'] as bool? ?? false;
          final encrypted = payload['encrypted'] as bool? ?? false;

          final outFile =
              await FileManager.instance.createOutputFile(relativePath);
          final raf = await outFile.open(mode: FileMode.write);

          currentFile = _ReceivedFile(
            fileName: fileName,
            relativePath: relativePath,
            fileSize: fileSize,
            totalChunks: totalChunks,
            compressed: compressed,
            encrypted: encrypted,
            outputFile: raf,
            hasher: _IncrementalHash(),
          );

          emitProgress(
            currentFileName: fileName,
            currentFileIndex: pendingFiles
                    ?.indexWhere((f) => f.relativePath == relativePath) ??
                fileIndex,
            totalFiles: pendingFiles?.length ?? 1,
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
          );

          AppLogger.info(
              '[Receiver] Receiving: $fileName ($fileSize bytes, $totalChunks chunks)');
        } else if (frame.messageType == MessageType.fileChunk) {
          final file = currentFile;
          if (file == null) continue;

          try {
            await file.outputFile.writeFrom(frame.payload);
            file.hasher.add(frame.payload);
            file.chunksReceived++;
            file.bytesReceived += frame.payload.length;
            transferredBytes += frame.payload.length;

            if (file.chunksReceived % 10 == 0 ||
                file.chunksReceived == file.totalChunks) {
              emitProgress(
                currentFileName: file.fileName,
                currentFileIndex: pendingFiles
                        ?.indexWhere((f) => f.relativePath == file.relativePath) ??
                    fileIndex,
                totalFiles: pendingFiles?.length ?? 1,
                transferredBytes: transferredBytes,
                totalBytes: totalBytes,
              );
            }
          } catch (e) {
            AppLogger.warning(
                '[Receiver] Write error for ${file.fileName}: $e');
            parser.sendJson(MessageType.error, frame.transferId, {
              'error': 'Write failed: $e',
              'file_name': file.fileName,
            });
          }
        } else if (frame.messageType == MessageType.fileEnd) {
          final file = currentFile;
          if (file == null) continue;

          await file.outputFile.close();

          final outFile = File(file.outputFile.path);
          if (!await outFile.exists()) continue;

          List<int> fileBytes = await outFile.readAsBytes();

          if (file.encrypted) {
            try {
              fileBytes = EncryptionService.instance.decrypt(
                frame.transferId.toString(),
                Uint8List.fromList(fileBytes),
              );
              AppLogger.info('[Receiver] Decrypted: ${file.fileName}');
            } catch (e) {
              AppLogger.warning(
                  '[Receiver] Decryption failed for ${file.fileName}: $e');
              emitProgress(
                  status: 'failed', error: 'Decryption failed: $e');
              continue;
            }
          }

          if (file.compressed) {
            fileBytes = CompressionService.instance.decompressBytes(fileBytes);
            AppLogger.info(
                '[Receiver] Decompressed: ${file.fileName} (${(await outFile.length())}B -> ${fileBytes.length}B)');
          }

          await outFile.writeAsBytes(fileBytes);

          parser.sendJson(MessageType.ack, frame.transferId, {
            'status': 'ok',
            'file_name': file.fileName,
          });

          AppLogger.info(
              '[Receiver] File end: ${file.fileName} (${file.chunksReceived}/${file.totalChunks})');
        } else if (frame.messageType == MessageType.fileChecksum) {
          final file = currentFile;
          if (file == null) continue;

          final payload = frame.jsonPayload;
          final senderChecksum = payload?['checksum'] as String? ?? '';

          file.hasher.close();
          final computedHash =
              base64.encode(file.hasher.digest.bytes);

          if (senderChecksum == computedHash) {
            parser.sendJson(MessageType.ack, frame.transferId, {
              'status': 'verified',
              'file_name': file.fileName,
            });
            AppLogger.info('[Receiver] Checksum OK: ${file.fileName}');
          } else {
            parser.sendJson(MessageType.ack, frame.transferId, {
              'status': 'mismatch',
              'file_name': file.fileName,
              'expected': senderChecksum,
              'computed': computedHash,
            });
            AppLogger.warning(
                '[Receiver] Checksum MISMATCH: ${file.fileName}');
            emitProgress(
                status: 'failed',
                error: 'Checksum mismatch: ${file.fileName}');
          }

          currentFile = null;
          fileIndex++;
        } else if (frame.messageType == MessageType.complete) {
          parser.sendJson(MessageType.ack, frame.transferId, {
            'status': 'ok',
            'transfer_id': transferId,
          });

          emitProgress(
            progress: 1.0,
            status: 'completed',
            currentFileName: 'Transfer complete',
            transferredBytes: transferredBytes,
            totalBytes: totalBytes,
          );

          final files = pendingFiles ?? const <FileEntry>[];
          final duration = DateTime.now().difference(startedAt);
          final completed = TransferCompletionEvent(
            transferId: transferId ?? '',
            remoteName: remoteName ?? 'Unknown',
            files: files,
            totalBytes: totalBytes,
            transferredBytes: transferredBytes,
            duration: duration,
            baseDirectory: FileManager.instance.baseDirectory.path,
          );
          onComplete?.call(completed);

          AppLogger.info('[Receiver] Complete: $transferId');
          break;
        } else if (frame.messageType == MessageType.error) {
          final payload = frame.jsonPayload;
          final errMsg = payload?['error'] as String? ?? 'Unknown error';
          AppLogger.warning('[Receiver] Sender error: $errMsg');
          emitProgress(status: 'failed', error: 'Sender error: $errMsg');
          break;
        } else if (frame.messageType == MessageType.resumeRequest) {
          final payload = frame.jsonPayload;
          final resumeTransferId = payload?['transfer_id'] as String?;
          final files = pendingFiles;
          if (resumeTransferId != null && files != null) {
            _handleResumeRequest(
                parser, frame.transferId, resumeTransferId, files);
          }
        } else if (frame.messageType == MessageType.keepAlive) {
          parser.sendJson(
              MessageType.ack, frame.transferId, {'status': 'alive'});
        }
      }
    } catch (e) {
      AppLogger.error('[Receiver] Error', e);
      _progressController.add(TransferProgress(
        status: 'failed',
        error: 'Receiver error: $e',
      ));
    } finally {
      await currentFile?.outputFile.close();
      await conn.close();
      parser.close();
    }
  }

  Future<void> _maybeHandleQrSession(
      Map<String, dynamic>? payload, TcpConnection conn) async {
    try {
      final sessionToken = payload?['session_token'] as String?;
      final deviceId = payload?['device_id'] as String?;
      if (sessionToken == null || deviceId == null) return;

      if (!QrPairingService.instance.isSessionTokenValid(sessionToken)) {
        AppLogger.warning('[Receiver] Invalid QR session token from $deviceId');
        return;
      }

      await TrustedDeviceManager.instance.addOrUpdate(
        uuid: deviceId,
        publicKey: QrPairingService.instance.activeSessionToken,
        nickname: payload?['device_name'] as String? ?? deviceId,
        platform: DevicePlatform.unknown,
        ip: conn.remoteHost,
        trusted: true,
      );
      AppLogger.info('[Receiver] Device $deviceId paired via QR session');
    } catch (e) {
      AppLogger.warning('[Receiver] QR session handling failed: $e');
    }
  }

  Future<void> _handleResumeRequest(FrameParser parser, int transferId,
      String resumeTransferId, List<FileEntry> files) async {
    try {
      final resumeInfo = <Map<String, dynamic>>[];
      for (final file in files) {
        final partialFile =
            await FileManager.instance.createOutputFile(file.relativePath);
        final indexPath = '${partialFile.path}.gidx';
        final index =
            await ResumeIndex.load(indexPath, resumeTransferId);
        if (index != null) {
          resumeInfo.add(index.toJson());
        }
      }

      parser.sendJson(MessageType.resumeAccept, transferId, {
        'transfer_id': resumeTransferId,
        'resume_info': resumeInfo,
      });
    } catch (e) {
      parser.sendJson(MessageType.error, transferId, {
        'error': 'Resume check failed: $e',
      });
    }
  }
}
