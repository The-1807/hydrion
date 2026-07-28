import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/daily_hydration_context.dart';
import '../storage/local_store.dart';
import 'storage_recovery.dart';

class DailyHydrationContextRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.daily_hydration_context.v1';
  static const schemaVersion = 1;
  static const maxRetainedDays = 14;
  static const _category = 'daily_hydration_context';

  final HydrionLocalStore _store;
  Map<String, DailyHydrationContext> _contexts;
  final List<StorageRecoveryEvent> _recoveryEvents;

  DailyHydrationContextRepository._(
    this._store,
    this._contexts,
    this._recoveryEvents,
  );

  DailyHydrationContextRepository.memory()
      : this._(MemoryHydrionStore(), {}, const []);

  static Future<DailyHydrationContextRepository> load(
    HydrionLocalStore store,
  ) async {
    final result = _decode(await store.readString(storageKey));
    return DailyHydrationContextRepository._(
      store,
      result.contexts,
      result.recoveryEvents,
    );
  }

  DailyHydrationContext? forDate(String localDateKey) =>
      _contexts[localDateKey];
  List<StorageRecoveryEvent> get recoveryEvents =>
      List.unmodifiable(_recoveryEvents);

  Future<void> save(DailyHydrationContext context) async {
    _contexts = {..._contexts, context.localDateKey: context};
    final ordered = _contexts.values.toList()
      ..sort((a, b) => b.localDateKey.compareTo(a.localDateKey));
    _contexts = {
      for (final item in ordered.take(maxRetainedDays)) item.localDateKey: item,
    };
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String localDateKey) async {
    _contexts = {..._contexts}..remove(localDateKey);
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _contexts = {};
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _persist() => _store.writeString(
        storageKey,
        jsonEncode({
          'schemaVersion': schemaVersion,
          'contexts': _contexts.values.map((item) => item.toJson()).toList(),
        }),
      );

  static _DailyContextDecodeResult _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _DailyContextDecodeResult({});
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['contexts'] is! List) {
        return const _DailyContextDecodeResult(
          {},
          [
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.fallbackEmpty,
            ),
          ],
        );
      }
      final version = storageSchemaVersion(decoded) ?? 1;
      if (version > schemaVersion) {
        return _DailyContextDecodeResult(
          const {},
          [
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.unsupportedSchemaVersion,
              action: StorageRecoveryActions.preserveRawFallback,
              schemaVersion: version,
            ),
          ],
        );
      }
      final records = decoded['contexts'] as List;
      final valid = records
          .map(DailyHydrationContext.fromJson)
          .whereType<DailyHydrationContext>()
          .toList()
        ..sort((a, b) => b.localDateKey.compareTo(a.localDateKey));
      return _DailyContextDecodeResult(
        {
          for (final item in valid.take(maxRetainedDays))
            item.localDateKey: item,
        },
        valid.length == records.length
            ? const []
            : [
                StorageRecoveryEvent(
                  category: _category,
                  code: StorageRecoveryCodes.invalidRecord,
                  action: StorageRecoveryActions.skipInvalidRecords,
                  skippedRecords: records.length - valid.length,
                ),
              ],
      );
    } on FormatException {
      return const _DailyContextDecodeResult(
        {},
        [
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

class _DailyContextDecodeResult {
  final Map<String, DailyHydrationContext> contexts;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _DailyContextDecodeResult(
    this.contexts, [
    this.recoveryEvents = const [],
  ]);
}
