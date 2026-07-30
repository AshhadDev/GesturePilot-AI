import 'dart:convert';
import 'dart:typed_data';

class ProtocolConstants {
  ProtocolConstants._();

  static const int version = 1;
  static const int headerSize = 22;
  static const int footerSize = 4;
  static const int minFrameSize = headerSize + footerSize;
  static const int defaultChunkSize = 65536;
  static const int maxFrameSize = 104857600;
  static const int maxPayloadSize = maxFrameSize - headerSize - footerSize;
  static const int connectionTimeoutMs = 30000;
  static const int ackTimeoutMs = 10000;
}

class MessageType {
  MessageType._();

  static const int hello = 0x0001;
  static const int deviceInfo = 0x0002;
  static const int transferRequest = 0x0003;
  static const int transferAccept = 0x0004;
  static const int transferReject = 0x0005;
  static const int fileStart = 0x0006;
  static const int fileChunk = 0x0007;
  static const int fileEnd = 0x0008;
  static const int fileChecksum = 0x0009;
  static const int progress = 0x000A;
  static const int cancel = 0x000B;
  static const int complete = 0x000C;
  static const int error = 0x000D;
  static const int ack = 0x000E;
  static const int resumeRequest = 0x000F;
  static const int resumeAccept = 0x0010;
  static const int chunkRequest = 0x0011;
  static const int chunkData = 0x0012;
  static const int keepAlive = 0x0013;

  static String name(int type) {
    switch (type) {
      case hello: return 'HELLO';
      case deviceInfo: return 'DEVICE_INFO';
      case transferRequest: return 'TRANSFER_REQUEST';
      case transferAccept: return 'TRANSFER_ACCEPT';
      case transferReject: return 'TRANSFER_REJECT';
      case fileStart: return 'FILE_START';
      case fileChunk: return 'FILE_CHUNK';
      case fileEnd: return 'FILE_END';
      case fileChecksum: return 'FILE_CHECKSUM';
      case progress: return 'PROGRESS';
      case cancel: return 'CANCEL';
      case complete: return 'COMPLETE';
      case error: return 'ERROR';
      case ack: return 'ACK';
      case resumeRequest: return 'RESUME_REQUEST';
      case resumeAccept: return 'RESUME_ACCEPT';
      case chunkRequest: return 'CHUNK_REQUEST';
      case chunkData: return 'CHUNK_DATA';
      case keepAlive: return 'KEEP_ALIVE';
      default: return 'UNKNOWN($type)';
    }
  }
}

class Frame {
  final int protocolVersion;
  final int messageType;
  final int payloadLength;
  final int transferId;
  final int sequenceNumber;
  final int chunkIndex;
  final Uint8List payload;
  final int crc32;

  const Frame({
    this.protocolVersion = ProtocolConstants.version,
    required this.messageType,
    required this.payloadLength,
    required this.transferId,
    required this.sequenceNumber,
    this.chunkIndex = 0,
    required this.payload,
    required this.crc32,
  });

  int get frameLength => ProtocolConstants.headerSize + payloadLength + ProtocolConstants.footerSize;

  Map<String, dynamic>? get jsonPayload {
    try {
      return json.decode(utf8.decode(payload)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static int _crc32(Uint8List data) {
    int crc = 0xFFFFFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data[i];
      for (int j = 0; j < 8; j++) {
        crc = (crc >> 1) ^ (crc & 1) * 0xEDB88320;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  Uint8List encode() {
    final buf = ByteData(ProtocolConstants.headerSize + payloadLength + ProtocolConstants.footerSize);
    int offset = 0;

    buf.setUint32(offset, frameLength);
    offset += 4;
    buf.setUint16(offset, protocolVersion);
    offset += 2;
    buf.setUint16(offset, messageType);
    offset += 2;
    buf.setUint32(offset, payloadLength);
    offset += 4;
    buf.setUint64(offset, transferId);
    offset += 8;
    buf.setUint32(offset, sequenceNumber);
    offset += 4;
    buf.setUint32(offset, chunkIndex);
    offset += 4;

    if (payloadLength > 0) {
      buf.buffer.asUint8List().setRange(offset, offset + payloadLength, payload);
      offset += payloadLength;
    }

    final headerBytes = buf.buffer.asUint8List(0, offset);
    final computedCrc = _crc32(headerBytes);
    buf.setUint32(offset, computedCrc);

    return buf.buffer.asUint8List(0, buf.lengthInBytes);
  }

  static Frame? decode(Uint8List data) {
    if (data.length < ProtocolConstants.minFrameSize) return null;

    final buf = ByteData.view(data.buffer, data.offsetInBytes, data.length);
    int offset = 0;

    final totalLen = buf.getUint32(offset);
    offset += 4;
    if (totalLen != data.length) return null;

    final version = buf.getUint16(offset);
    offset += 2;
    final msgType = buf.getUint16(offset);
    offset += 2;
    final payloadLen = buf.getUint32(offset);
    offset += 4;
    final tid = buf.getUint64(offset);
    offset += 8;
    final seq = buf.getUint32(offset);
    offset += 4;
    final chunkIdx = buf.getUint32(offset);
    offset += 4;

    if (payloadLen < 0 || payloadLen > ProtocolConstants.maxPayloadSize) return null;
    if (data.length < ProtocolConstants.headerSize + payloadLen + ProtocolConstants.footerSize) return null;

    final payload = Uint8List(payloadLen);
    if (payloadLen > 0) {
      payload.setRange(0, payloadLen, data.sublist(offset, offset + payloadLen));
      offset += payloadLen;
    }

    final storedCrc = buf.getUint32(offset);

    final headerBytes = data.sublist(0, offset);
    final computedCrc = _crc32(Uint8List.fromList(headerBytes));
    if (computedCrc != storedCrc) return null;

    return Frame(
      protocolVersion: version,
      messageType: msgType,
      payloadLength: payloadLen,
      transferId: tid,
      sequenceNumber: seq,
      chunkIndex: chunkIdx,
      payload: payload,
      crc32: storedCrc,
    );
  }

  static Frame makeJson(int type, int transferId, int seqNum, Map<String, dynamic> jsonData,
      {int chunkIndex = 0}) {
    final payload = Uint8List.fromList(utf8.encode(json.encode(jsonData)));
    final dummyBuf = ByteData(ProtocolConstants.headerSize);
    _writeHeader(dummyBuf, ProtocolConstants.headerSize + payload.length + ProtocolConstants.footerSize,
        ProtocolConstants.version, type, payload.length, transferId, seqNum, chunkIndex);
    final headerBytes = dummyBuf.buffer.asUint8List(0, ProtocolConstants.headerSize);
    final crc = _crc32(Uint8List.fromList([...headerBytes, ...payload]));

    return Frame(
      messageType: type,
      payloadLength: payload.length,
      transferId: transferId,
      sequenceNumber: seqNum,
      chunkIndex: chunkIndex,
      payload: payload,
      crc32: crc,
    );
  }

  static Frame makeBinary(int type, int transferId, int seqNum, Uint8List data,
      {int chunkIndex = 0}) {
    final dummyBuf = ByteData(ProtocolConstants.headerSize);
    _writeHeader(dummyBuf, ProtocolConstants.headerSize + data.length + ProtocolConstants.footerSize,
        ProtocolConstants.version, type, data.length, transferId, seqNum, chunkIndex);
    final headerBytes = dummyBuf.buffer.asUint8List(0, ProtocolConstants.headerSize);
    final crc = _crc32(Uint8List.fromList([...headerBytes, ...data]));

    return Frame(
      messageType: type,
      payloadLength: data.length,
      transferId: transferId,
      sequenceNumber: seqNum,
      chunkIndex: chunkIndex,
      payload: data,
      crc32: crc,
    );
  }

  static void _writeHeader(ByteData buf, int totalLen, int version, int msgType, int payloadLen,
      int tid, int seq, int chunkIdx) {
    buf.setUint32(0, totalLen);
    buf.setUint16(4, version);
    buf.setUint16(6, msgType);
    buf.setUint32(8, payloadLen);
    buf.setUint64(12, tid);
    buf.setUint32(20, seq);
    buf.setUint32(24, chunkIdx);
  }

  @override
  String toString() => 'Frame(${MessageType.name(messageType)} tid=$transferId seq=$sequenceNumber len=$payloadLength)';
}
