import 'dart:async';
import 'dart:typed_data';

import 'package:gestureos_desktop/core/utils/logger.dart';
import 'package:gestureos_desktop/shared/protocol/protocol.dart';
import 'package:gestureos_desktop/shared/services/network_service.dart';

class FrameParser {
  final TcpConnection _connection;
  final StreamController<Frame> _frameController = StreamController<Frame>.broadcast();
  StreamSubscription<List<int>>? _dataSub;
  final List<int> _buffer = [];
  int _nextSeq = 0;
  bool _started = false;

  FrameParser(this._connection);

  Stream<Frame> get frames => _frameController.stream;
  TcpConnection get connection => _connection;
  bool get isConnected => _connection.isConnected;

  void start() {
    if (_started) return;
    _started = true;
    _dataSub = _connection.dataStream.listen(_onData, onError: _onError, onDone: _onDone);
  }

  void sendFrame(Frame frame) {
    final encoded = frame.encode();
    _connection.send(encoded);
    AppLogger.debug('[Frame] >> ${MessageType.name(frame.messageType)} tid=${frame.transferId} seq=${frame.sequenceNumber} len=${frame.payloadLength}');
  }

  void sendJson(int type, int transferId, Map<String, dynamic> data, {int chunkIndex = 0}) {
    final seq = _nextSeq++;
    sendFrame(Frame.makeJson(type, transferId, seq, data, chunkIndex: chunkIndex));
  }

  void sendBinary(int type, int transferId, Uint8List data, {int chunkIndex = 0}) {
    final seq = _nextSeq++;
    sendFrame(Frame.makeBinary(type, transferId, seq, data, chunkIndex: chunkIndex));
  }

  void sendAck(int transferId, int ackForSeq, {String status = 'ok', String? message}) {
    sendJson(MessageType.ack, transferId, {
      'ack_seq': ackForSeq,
      'status': status,
      'message': ?message,
    });
  }

  void sendError(int transferId, String errorMessage, {int? code}) {
    sendJson(MessageType.error, transferId, {
      'error': errorMessage,
      'code': ?code,
    });
  }

  void _onData(List<int> chunk) {
    _buffer.addAll(chunk);
    _tryParseFrames();
  }

  void _onError(Object error) {
    AppLogger.warning('[FrameParser] Error: $error');
    _frameController.addError(error);
  }

  void _onDone() {
    _started = false;
    AppLogger.debug('[FrameParser] Connection closed');
  }

  void _tryParseFrames() {
    while (_buffer.length >= ProtocolConstants.minFrameSize) {
      final lenBytes = _buffer.sublist(0, 4);
      final totalLen = ByteData.sublistView(Uint8List.fromList(lenBytes), 0, 4).getUint32(0);

      if (totalLen < ProtocolConstants.minFrameSize || totalLen > ProtocolConstants.maxFrameSize) {
        AppLogger.warning('[FrameParser] Invalid frame length: $totalLen');
        _buffer.clear();
        _frameController.addError('Invalid frame length: $totalLen');
        return;
      }

      if (_buffer.length < totalLen) return;

      final frameData = Uint8List.fromList(_buffer.sublist(0, totalLen));
      _buffer.removeRange(0, totalLen);

      final frame = Frame.decode(frameData);
      if (frame == null) {
        AppLogger.warning('[FrameParser] Failed to decode frame');
        continue;
      }

      AppLogger.debug('[Frame] << ${MessageType.name(frame.messageType)} tid=${frame.transferId} seq=${frame.sequenceNumber} len=${frame.payloadLength}');
      _frameController.add(frame);
    }
  }

  Future<Frame?> waitForFrame(int messageType, {Duration? timeout}) async {
    final t = timeout ?? Duration(milliseconds: ProtocolConstants.ackTimeoutMs);
    try {
      final frame = await frames.firstWhere(
        (f) => f.messageType == messageType,
      ).timeout(t);
      return frame;
    } catch (_) {
      return null;
    }
  }

  Future<Frame?> waitForAck(int transferId, {Duration? timeout}) async {
    final t = timeout ?? Duration(milliseconds: ProtocolConstants.ackTimeoutMs);
    try {
      final frame = await frames.firstWhere(
        (f) => f.messageType == MessageType.ack && f.transferId == transferId,
      ).timeout(t);
      return frame;
    } catch (_) {
      return null;
    }
  }

  void close() {
    _dataSub?.cancel();
    _frameController.close();
    _buffer.clear();
    _started = false;
  }
}
