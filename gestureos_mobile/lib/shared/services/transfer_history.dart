import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TransferRecord {
  final String id;
  final DateTime timestamp;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final List<String> fileNames;
  final int totalBytes;
  final double speedBytesPerSec;
  final int durationMs;
  final String status; // completed, failed, cancelled
  final String checksum;
  final String? errorMessage;

  const TransferRecord({
    required this.id,
    required this.timestamp,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.fileNames,
    required this.totalBytes,
    required this.speedBytesPerSec,
    required this.durationMs,
    required this.status,
    required this.checksum,
    this.errorMessage,
  });

  String get durationLabel {
    final sec = durationMs ~/ 1000;
    if (sec < 60) return '${sec}s';
    if (sec < 3600) return '${sec ~/ 60}m ${sec % 60}s';
    return '${sec ~/ 3600}h ${(sec % 3600) ~/ 60}m';
  }

  String get sizeLabel {
    final b = totalBytes;
    if (b < 1024) return '$b B';
    if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
    return '${(b / 1073741824).toStringAsFixed(2)} GB';
  }

  String get speedLabel {
    final bps = speedBytesPerSec;
    if (bps < 1024) return '${bps.toStringAsFixed(0)} B/s';
    if (bps < 1048576) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / 1048576).toStringAsFixed(1)} MB/s';
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isSent => senderId.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'fileNames': fileNames,
        'totalBytes': totalBytes,
        'speedBytesPerSec': speedBytesPerSec,
        'durationMs': durationMs,
        'status': status,
        'checksum': checksum,
        'errorMessage': errorMessage,
      };

  factory TransferRecord.fromJson(Map<String, dynamic> json) =>
      TransferRecord(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        senderId: json['senderId'] as String? ?? '',
        senderName: json['senderName'] as String? ?? '',
        receiverId: json['receiverId'] as String? ?? '',
        receiverName: json['receiverName'] as String? ?? '',
        fileNames: (json['fileNames'] as List<dynamic>?)?.cast<String>() ?? [],
        totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
        speedBytesPerSec:
            (json['speedBytesPerSec'] as num?)?.toDouble() ?? 0,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'unknown',
        checksum: json['checksum'] as String? ?? '',
        errorMessage: json['errorMessage'] as String?,
      );
}

class TransferHistoryService {
  TransferHistoryService._();
  static final TransferHistoryService instance = TransferHistoryService._();

  static const String _storageKey = 'gestureos_history';
  List<TransferRecord> _records = [];
  bool _loaded = false;

  List<TransferRecord> get records =>
      List.unmodifiable(_records..sort((a, b) => b.timestamp.compareTo(a.timestamp)));

  bool get hasHistory => _records.isNotEmpty;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = json.decode(raw) as List<dynamic>;
      _records = list
          .map((e) => TransferRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _records = [];
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_records.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> addRecord(TransferRecord record) async {
    await load();
    _records.add(record);
    // Keep last 100 records max
    if (_records.length > 100) {
      _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _records = _records.sublist(0, 100);
    }
    await _persist();
  }

  List<TransferRecord> search(String query) {
    if (query.isEmpty) return records;
    final lower = query.toLowerCase();
    return records.where((r) {
      return r.senderName.toLowerCase().contains(lower) ||
          r.receiverName.toLowerCase().contains(lower) ||
          r.fileNames.any((f) => f.toLowerCase().contains(lower));
    }).toList();
  }

  List<TransferRecord> filterByStatus(String status) {
    if (status == 'all') return records;
    return records.where((r) => r.status == status).toList();
  }

  Future<void> clearHistory() async {
    _records.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> removeRecord(String id) async {
    _records.removeWhere((r) => r.id == id);
    await _persist();
  }
}
