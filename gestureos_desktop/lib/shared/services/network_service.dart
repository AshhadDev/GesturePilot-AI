import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gestureos_desktop/core/utils/logger.dart';

class TcpConnection {
  final String id;
  final Socket socket;
  final String remoteHost;
  final int remotePort;
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();
  bool _isClosed = false;

  Stream<List<int>> get dataStream => _dataController.stream;
  bool get isConnected => !_isClosed;

  TcpConnection({
    required this.id,
    required this.socket,
    required this.remoteHost,
    required this.remotePort,
  }) {
    socket.listen(
      (data) {
        if (!_isClosed) _dataController.add(data);
      },
      onError: (error) {
        AppLogger.warning('TcpConnection error [$id]: $error');
        _dataController.addError(error);
        close();
      },
      onDone: () => close(),
      cancelOnError: false,
    );
  }

  void send(List<int> data) {
    if (!_isClosed) {
      try {
        socket.add(data);
      } catch (e) {
        AppLogger.warning('TcpConnection send error [$id]: $e');
      }
    }
  }

  void sendJson(Map<String, dynamic> message) {
    final bytes = utf8.encode(jsonEncode(message));
    final header = _uint32Bytes(bytes.length);
    send([...header, ...bytes]);
  }

  void sendBinary(List<int> data) {
    final header = _uint32Bytes(data.length);
    send([...header, ...data]);
  }

  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _dataController.close();
    try { await socket.close(); } catch (_) {}
  }

  static List<int> _uint32Bytes(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }
}

class NetworkService {
  NetworkService._();
  static final NetworkService instance = NetworkService._();

  static const int _dataPort = 48772;

  ServerSocket? _serverSocket;
  final Map<String, TcpConnection> _connections = {};
  final StreamController<TcpConnection> _incomingController =
      StreamController<TcpConnection>.broadcast();
  bool _isServerRunning = false;

  Stream<TcpConnection> get onIncomingConnection => _incomingController.stream;
  List<TcpConnection> get activeConnections => _connections.values.toList();
  bool get isServerRunning => _isServerRunning;
  int get dataPort => _dataPort;

  Future<void> startServer({int port = _dataPort}) async {
    if (_isServerRunning) return;
    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        port,
        shared: true,
      );
      _isServerRunning = true;
      _serverSocket!.listen(
        (socket) {
          final id = 'conn-${socket.remoteAddress.address}-${socket.remotePort}';
          final conn = TcpConnection(
            id: id,
            socket: socket,
            remoteHost: socket.remoteAddress.address,
            remotePort: socket.remotePort,
          );
          _connections[id] = conn;
          _incomingController.add(conn);
          AppLogger.info('TCP connection from ${socket.remoteAddress.address}');
        },
        onError: (e) => AppLogger.warning('ServerSocket error: $e'),
      );
      AppLogger.info('NetworkService server listening on port $port');
    } catch (e) {
      AppLogger.warning('NetworkService server failed: $e');
    }
  }

  Future<TcpConnection?> connect(String host, {int port = _dataPort}) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
      final id = 'conn-$host-$port';
      final conn = TcpConnection(
        id: id,
        socket: socket,
        remoteHost: host,
        remotePort: port,
      );
      _connections[id] = conn;
      AppLogger.info('Connected to $host:$port');
      return conn;
    } catch (e) {
      AppLogger.warning('Connection to $host:$port failed: $e');
      return null;
    }
  }

  void disconnect(String connectionId) {
    _connections.remove(connectionId)?.close();
  }

  TcpConnection? getConnection(String id) => _connections[id];

  Future<void> stopServer() async {
    _isServerRunning = false;
    for (final conn in _connections.values) {
      await conn.close();
    }
    _connections.clear();
    try { await _serverSocket?.close(); } catch (_) {}
    _serverSocket = null;
    AppLogger.info('NetworkService server stopped');
  }

  void notifyNameChange(String newName) {
    AppLogger.info('NetworkService notified of name change: $newName');
  }

  Future<void> dispose() async {
    await stopServer();
    await _incomingController.close();
  }
}
