import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:gestureos_desktop/core/utils/logger.dart';
import 'package:gestureos_desktop/shared/models/app_models.dart';

class HistoryStore {
  HistoryStore._();
  static final HistoryStore instance = HistoryStore._();

  static const String _key = 'gestureos_history_v1';
  static const int _maxItems = 200;

  Future<List<TransferHistoryItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => TransferHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('[History] Load failed: $e');
      return [];
    }
  }

  Future<void> save(List<TransferHistoryItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = items.take(_maxItems).map((i) => i.toJson()).toList();
      await prefs.setString(_key, json.encode(list));
    } catch (e) {
      AppLogger.warning('[History] Save failed: $e');
    }
  }
}
