import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';
import 'storage_recovery.dart';

/// Context attached to one canonical hydration record. Challenge progress is
/// derived from this context; the volume itself is never copied per challenge.
class HydrationMetadata {
  final String? temperatureStyle;
  final String? infusionTheme;
  final bool? noAddedSugar;
  final bool? savedContainerUsed;
  final String? mealContext;
  final String? timeWindow;
  final String? challengeActionSource;
  final String? bingoTileSource;

  const HydrationMetadata({
    this.temperatureStyle,
    this.infusionTheme,
    this.noAddedSugar,
    this.savedContainerUsed,
    this.mealContext,
    this.timeWindow,
    this.challengeActionSource,
    this.bingoTileSource,
  });

  bool get isEmpty =>
      temperatureStyle == null &&
      infusionTheme == null &&
      noAddedSugar == null &&
      savedContainerUsed == null &&
      mealContext == null &&
      timeWindow == null &&
      challengeActionSource == null &&
      bingoTileSource == null;

  HydrationMetadata copyWith({
    String? temperatureStyle,
    String? infusionTheme,
    bool? noAddedSugar,
    bool? savedContainerUsed,
    String? mealContext,
    String? timeWindow,
    String? challengeActionSource,
    String? bingoTileSource,
    bool clearTemperatureStyle = false,
    bool clearInfusionTheme = false,
    bool clearNoAddedSugar = false,
    bool clearSavedContainerUsed = false,
    bool clearMealContext = false,
    bool clearTimeWindow = false,
    bool clearChallengeActionSource = false,
    bool clearBingoTileSource = false,
  }) {
    return HydrationMetadata(
      temperatureStyle: clearTemperatureStyle
          ? null
          : temperatureStyle ?? this.temperatureStyle,
      infusionTheme:
          clearInfusionTheme ? null : infusionTheme ?? this.infusionTheme,
      noAddedSugar:
          clearNoAddedSugar ? null : noAddedSugar ?? this.noAddedSugar,
      savedContainerUsed: clearSavedContainerUsed
          ? null
          : savedContainerUsed ?? this.savedContainerUsed,
      mealContext: clearMealContext ? null : mealContext ?? this.mealContext,
      timeWindow: clearTimeWindow ? null : timeWindow ?? this.timeWindow,
      challengeActionSource: clearChallengeActionSource
          ? null
          : challengeActionSource ?? this.challengeActionSource,
      bingoTileSource:
          clearBingoTileSource ? null : bingoTileSource ?? this.bingoTileSource,
    );
  }

  Map<String, dynamic> toJson() => {
        if (temperatureStyle != null) 'temperatureStyle': temperatureStyle,
        if (infusionTheme != null) 'infusionTheme': infusionTheme,
        if (noAddedSugar != null) 'noAddedSugar': noAddedSugar,
        if (savedContainerUsed != null)
          'savedContainerUsed': savedContainerUsed,
        if (mealContext != null) 'mealContext': mealContext,
        if (timeWindow != null) 'timeWindow': timeWindow,
        if (challengeActionSource != null)
          'challengeActionSource': challengeActionSource,
        if (bingoTileSource != null) 'bingoTileSource': bingoTileSource,
      };

  static HydrationMetadata fromJson(Object? value) {
    if (value is! Map) return const HydrationMetadata();
    String? text(String key) {
      final result = value[key]?.toString().trim();
      return result == null || result.isEmpty ? null : result;
    }

    return HydrationMetadata(
      temperatureStyle: text('temperatureStyle'),
      infusionTheme: text('infusionTheme'),
      noAddedSugar:
          value['noAddedSugar'] is bool ? value['noAddedSugar'] as bool : null,
      savedContainerUsed: value['savedContainerUsed'] is bool
          ? value['savedContainerUsed'] as bool
          : null,
      mealContext: text('mealContext'),
      timeWindow: text('timeWindow'),
      challengeActionSource: text('challengeActionSource'),
      bingoTileSource: text('bingoTileSource'),
    );
  }
}

class HydrationLog {
  final String id;
  final int volumeMl;
  final DateTime timestamp;
  final String source;
  final String? actionId;
  final HydrationMetadata metadata;

  const HydrationLog({
    required this.id,
    required this.volumeMl,
    required this.timestamp,
    required this.source,
    this.actionId,
    this.metadata = const HydrationMetadata(),
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'volumeMl': volumeMl,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
      if (actionId != null) 'actionId': actionId,
      if (!metadata.isEmpty) 'metadata': metadata.toJson(),
    };
  }

  static HydrationLog? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final volume = value['volumeMl'];
    final timestamp = DateTime.tryParse((value['timestamp'] ?? '').toString());
    final source = (value['source'] ?? 'local').toString();

    if (volume is! num ||
        !volume.isFinite ||
        timestamp == null ||
        volume <= 0) {
      return null;
    }

    return HydrationLog(
      id: (value['id'] ??
              'log-${timestamp.microsecondsSinceEpoch}-${volume.round()}')
          .toString(),
      volumeMl: volume.round(),
      timestamp: timestamp,
      source: source.trim().isEmpty ? 'local' : source,
      actionId: (value['actionId'] as Object?)?.toString(),
      metadata: HydrationMetadata.fromJson(value['metadata']),
    );
  }
}

class HydrationRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.hydration_logs.v1';
  static const _category = 'hydration_logs';
  static const _currentSchemaVersion = 1;

  final HydrionLocalStore _store;
  final List<HydrationLog> _logs;
  final List<StorageRecoveryEvent> _recoveryEvents;
  final Set<String> _inFlightActionIds = <String>{};

  HydrationRepository._(
    this._store,
    List<HydrationLog> logs, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ])  : _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        ),
        _logs = List<HydrationLog>.of(logs)
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  HydrationRepository.memory() : this._(MemoryHydrionStore(), <HydrationLog>[]);

  static Future<HydrationRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final result = _decodeLogs(raw);
    return HydrationRepository._(store, result.logs, result.recoveryEvents);
  }

  List<HydrationLog> get logs => List<HydrationLog>.unmodifiable(_logs);

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  Future<void> refreshFromStore() async {
    final raw = await _store.readString(storageKey);
    final refreshed = _decodeLogs(raw).logs;
    _logs
      ..clear()
      ..addAll(refreshed)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<HydrationLog?> addLog({
    required int volumeMl,
    required DateTime timestamp,
    String source = 'local',
    String? actionId,
    HydrationMetadata metadata = const HydrationMetadata(),
  }) async {
    if (volumeMl <= 0) {
      return null;
    }

    final normalizedActionId = actionId?.trim();
    if (normalizedActionId != null && normalizedActionId.isNotEmpty) {
      if (_inFlightActionIds.contains(normalizedActionId) ||
          _logs.any((log) => log.actionId == normalizedActionId)) {
        return null;
      }
      _inFlightActionIds.add(normalizedActionId);
    }

    final log = HydrationLog(
      id: normalizedActionId != null && normalizedActionId.isNotEmpty
          ? 'log-$normalizedActionId'
          : 'log-${timestamp.microsecondsSinceEpoch}-$volumeMl',
      volumeMl: volumeMl,
      timestamp: timestamp,
      source: source.trim().isEmpty ? 'local' : source,
      actionId: normalizedActionId?.isEmpty == true ? null : normalizedActionId,
      metadata: metadata,
    );
    try {
      _logs.add(log);
      _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      try {
        await _persist();
      } catch (_) {
        _logs.removeWhere((candidate) => candidate.id == log.id);
        rethrow;
      }
      notifyListeners();
      return log;
    } finally {
      if (normalizedActionId != null) {
        _inFlightActionIds.remove(normalizedActionId);
      }
    }
  }

  Future<bool> updateLog({
    required String id,
    int? volumeMl,
    DateTime? timestamp,
    String? source,
    HydrationMetadata? metadata,
  }) async {
    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) {
      return false;
    }

    final nextVolume = volumeMl ?? _logs[index].volumeMl;
    if (nextVolume <= 0) {
      return false;
    }

    final previous = List<HydrationLog>.of(_logs);
    _logs[index] = HydrationLog(
      id: _logs[index].id,
      volumeMl: nextVolume,
      timestamp: timestamp ?? _logs[index].timestamp,
      source: source ?? _logs[index].source,
      actionId: _logs[index].actionId,
      metadata: metadata ?? _logs[index].metadata,
    );
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    try {
      await _persist();
    } catch (_) {
      _logs
        ..clear()
        ..addAll(previous);
      rethrow;
    }
    notifyListeners();
    return true;
  }

  Future<bool> deleteLog(String id) async {
    final previous = List<HydrationLog>.of(_logs);
    final before = _logs.length;
    _logs.removeWhere((log) => log.id == id);
    if (_logs.length == before) {
      return false;
    }
    try {
      await _persist();
    } catch (_) {
      _logs
        ..clear()
        ..addAll(previous);
      rethrow;
    }
    notifyListeners();
    return true;
  }

  Future<bool> restoreLog(HydrationLog log) async {
    if (_logs.any((existing) => existing.id == log.id) || log.volumeMl <= 0) {
      return false;
    }
    _logs.add(log);
    _logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    try {
      await _persist();
    } catch (_) {
      _logs.removeWhere((existing) => existing.id == log.id);
      rethrow;
    }
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

  static _HydrationDecodeResult _decodeLogs(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _HydrationDecodeResult(<HydrationLog>[]);
    }

    try {
      final decoded = jsonDecode(raw);
      final schemaVersion = storageSchemaVersion(decoded);
      if (schemaVersion != null && schemaVersion > _currentSchemaVersion) {
        return _HydrationDecodeResult(
          const <HydrationLog>[],
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.unsupportedSchemaVersion,
              action: StorageRecoveryActions.preserveRawFallback,
              schemaVersion: schemaVersion,
            ),
          ],
        );
      }
      if (decoded is! List) {
        return const _HydrationDecodeResult(
          <HydrationLog>[],
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.fallbackEmpty,
            ),
          ],
        );
      }
      final logs = <HydrationLog>[];
      var skippedRecords = 0;
      for (final record in decoded) {
        final log = HydrationLog.fromJson(record);
        if (log == null) {
          skippedRecords += 1;
          continue;
        }
        logs.add(log);
      }
      return _HydrationDecodeResult(
        logs,
        recoveryEvents: skippedRecords == 0
            ? const <StorageRecoveryEvent>[]
            : <StorageRecoveryEvent>[
                StorageRecoveryEvent(
                  category: _category,
                  code: StorageRecoveryCodes.invalidRecord,
                  action: StorageRecoveryActions.skipInvalidRecords,
                  skippedRecords: skippedRecords,
                ),
              ],
      );
    } on FormatException {
      return const _HydrationDecodeResult(
        <HydrationLog>[],
        recoveryEvents: <StorageRecoveryEvent>[
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.malformedJson,
            action: StorageRecoveryActions.fallbackEmpty,
            errorType: 'FormatException',
          ),
        ],
      );
    }
  }
}

class _HydrationDecodeResult {
  final List<HydrationLog> logs;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _HydrationDecodeResult(
    this.logs, {
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
