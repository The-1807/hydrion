import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';

class HydrationLog {
  final String id;
  final int volumeMl;
  final DateTime timestamp;
  final String source;

  const HydrationLog({
    required this.id,
    required this.volumeMl,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volumeMl': volumeMl,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  static HydrationLog? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final volume = value['volumeMl'];
    final timestamp = DateTime.tryParse((value['timestamp'] ?? '').toString());
    final source = (value['source'] ?? 'local').toString();

    if (volume is! num || timestamp == null || volume <= 0) {
      return null;
    }

    return HydrationLog(
      id: (value['id'] ??
              'log-${timestamp.microsecondsSinceEpoch}-${volume.round()}')
          .toString(),
      volumeMl: volume.round(),
      timestamp: timestamp,
      source: source.trim().isEmpty ? 'local' : source,
    );
  }
}

class HydrationRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.hydration_logs.v1';

  final HydrionLocalStore _store;
  final List<HydrationLog> _logs;

  HydrationRepository._(this._store, List<HydrationLog> logs)
      : _logs = logs..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  HydrationRepository.memory() : this._(MemoryHydrionStore(), <HydrationLog>[]);

  static Future<HydrationRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final logs = _decodeLogs(raw);
    return HydrationRepository._(store, logs);
  }

  List<HydrationLog> get logs => List<HydrationLog>.unmodifiable(_logs);

  Future<HydrationLog?> addLog({
    required int volumeMl,
    required DateTime timestamp,
    String source = 'local',
  }) async {
    if (volumeMl <= 0) {
      return null;
    }

    final log = HydrationLog(
      id: 'log-${timestamp.microsecondsSinceEpoch}-$volumeMl',
      volumeMl: volumeMl,
      timestamp: timestamp,
      source: source.trim().isEmpty ? 'local' : source,
    );
    _logs.add(log);
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _persist();
    notifyListeners();
    return log;
  }

  Future<bool> updateLog({
    required String id,
    int? volumeMl,
    DateTime? timestamp,
    String? source,
  }) async {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) {
      return false;
    }

    final nextVolume = volumeMl ?? _logs[index].volumeMl;
    if (nextVolume <= 0) {
      return false;
    }

    _logs[index] = HydrationLog(
      id: _logs[index].id,
      volumeMl: nextVolume,
      timestamp: timestamp ?? _logs[index].timestamp,
      source: source ?? _logs[index].source,
    );
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> deleteLog(String id) async {
    final before = _logs.length;
    _logs.removeWhere((log) => log.id == id);
    if (_logs.length == before) {
      return false;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  List<HydrationLog> fetch(DateTime start, DateTime end) {
    return _logs.where((log) {
      return !log.timestamp.isBefore(start) && !log.timestamp.isAfter(end);
    }).toList(growable: false);
  }

  int totalBetween(DateTime start, DateTime end) {
    return fetch(start, end).fold<int>(0, (sum, log) => sum + log.volumeMl);
  }

  int totalForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return _logs
        .where((log) =>
            !log.timestamp.isBefore(start) && log.timestamp.isBefore(end))
        .fold<int>(0, (sum, log) => sum + log.volumeMl);
  }

  int get totalMl {
    return _logs.fold<int>(0, (sum, log) => sum + log.volumeMl);
  }

  int get eventCount => _logs.length;

  Future<void> clear() async {
    _logs.clear();
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_logs.map((log) => log.toJson()).toList());
    await _store.writeString(storageKey, encoded);
  }

  static List<HydrationLog> _decodeLogs(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <HydrationLog>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <HydrationLog>[];
      }
      return decoded
          .map(HydrationLog.fromJson)
          .whereType<HydrationLog>()
          .toList();
    } on FormatException {
      return <HydrationLog>[];
    }
  }
}
