import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/daily_hydration_context.dart';
import '../storage/app_persistence.dart';
import '../storage/local_store.dart';
import '../storage/protected_app_store.dart';
import 'storage_recovery.dart';

enum DailyContextStatus {
  ready,
  cleanupPending,
  unavailable,
  corrupt,
  unsupported,
  deletionPending
}

final class DailyContextUnavailable implements Exception {
  const DailyContextUnavailable();
  @override
  String toString() => 'DailyContextUnavailable';
}

class DailyHydrationContextRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.daily_hydration_context.v1';
  static const deletionKey = 'hydrion.daily_hydration_context.deletion.v1';
  static const schemaVersion = 1;
  static const maxRetainedDays = 14;
  final HydrionLocalStore _legacy;
  final Future<ProtectedAppStore> Function()? _opener;
  ProtectedAppStore _protected;
  final bool _memory;
  Map<String, DailyHydrationContext> _contexts = {};
  int _revision = 0;
  DailyContextStatus _status = DailyContextStatus.unavailable;
  Future<void> _tail = Future.value();
  bool _closed = false;

  DailyHydrationContextRepository._(this._legacy, this._protected, this._opener)
      : _memory = false;

  DailyHydrationContextRepository.memory()
      : _legacy = MemoryHydrionStore(),
        _protected = const UnavailableProtectedAppStore(),
        _opener = null,
        _memory = true {
    _status = DailyContextStatus.ready;
  }

  static Future<DailyHydrationContextRepository> load(
    HydrionLocalStore store, {
    ProtectedAppStore? protectedStore,
    Future<ProtectedAppStore> Function()? opener,
  }) async {
    final open = opener ?? openProtectedAppStore;
    final repository = DailyHydrationContextRepository._(store,
        protectedStore ?? await open(), protectedStore == null ? open : null);
    await repository._reload();
    return repository;
  }

  DailyContextStatus get status => _status;
  bool get isKnown =>
      !_closed &&
      (_status == DailyContextStatus.ready ||
          _status == DailyContextStatus.cleanupPending);
  DailyHydrationContext? forDate(String key) => isKnown ? _contexts[key] : null;
  List<StorageRecoveryEvent> get recoveryEvents => const [];

  Future<T> _run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<bool> _removeAcknowledged(String key) async {
    final store = _legacy;
    final acknowledged = store is SharedPreferencesHydrionStore
        ? await store.removeAcknowledged(key)
        : store is MemoryHydrionStore
            ? await store.removeAcknowledged(key)
            : false;
    return acknowledged && await store.readString(key) == null;
  }

  void _publish(ProtectedContextRecord record) {
    _revision = record.revision;
    _contexts = {for (final item in record.contexts) item.localDateKey: item};
    _status = DailyContextStatus.ready;
  }

  Future<void> _reload() async {
    _contexts = {};
    _status = DailyContextStatus.unavailable;
    try {
      final intent = await _legacy.readString(deletionKey);
      if (intent != null) {
        final decoded = jsonDecode(intent);
        final validIntent = decoded is Map &&
            ((decoded['schemaVersion'] == 2 && decoded['pending'] == true) ||
                (decoded['schemaVersion'] == 1 &&
                    decoded['revision'] is int &&
                    (decoded['revision'] as int) > 0));
        if (!validIntent) {
          _status = DailyContextStatus.corrupt;
          return;
        }
        _status = DailyContextStatus.deletionPending;
        await _finishDeletion();
        return;
      }
      final read = await _protected.readDailyContext();
      if (read.status != ProtectedReadStatus.found &&
          read.status != ProtectedReadStatus.absent) {
        _status = switch (read.status) {
          ProtectedReadStatus.corrupt => DailyContextStatus.corrupt,
          ProtectedReadStatus.unsupported => DailyContextStatus.unsupported,
          _ => DailyContextStatus.unavailable,
        };
        return;
      }
      final record = read.record;
      if (record != null && record.phase != ContextRecordPhase.provisional) {
        _publish(record);
        await _cleanup();
        return;
      }
      final raw = await _legacy.readString(storageKey);
      final contexts = raw == null
          ? <DailyHydrationContext>[]
          : ProtectedContextRecord.decodePayload(raw, legacy: true);
      final candidate = ProtectedContextRecord(
          revision: 1,
          phase: ContextRecordPhase.provisional,
          contexts: contexts);
      if (record != null && !record.equivalentTo(candidate)) {
        _status = DailyContextStatus.corrupt;
        return;
      }
      if (record == null &&
          await _protected.writeDailyContext(candidate) !=
              ProtectedWriteStatus.committed) {
        return;
      }
      final active = ProtectedContextRecord(
          revision: candidate.revision,
          phase: ContextRecordPhase.active,
          contexts: contexts);
      // Cutover is a second acknowledged, verified commit. A provisional
      // destination can never authorize removal of the legacy source.
      if (await _protected.writeDailyContext(active) !=
          ProtectedWriteStatus.committed) {
        return;
      }
      _publish(active);
      await _cleanup();
    } on ProtectedContextSchemaUnsupported {
      _status = DailyContextStatus.unsupported;
    } on FormatException {
      _status = DailyContextStatus.corrupt;
    } catch (_) {
      _status = DailyContextStatus.unavailable;
    }
  }

  Future<void> _cleanup() async {
    try {
      if (await _legacy.readString(storageKey) != null &&
          !await _removeAcknowledged(storageKey)) {
        _status = DailyContextStatus.cleanupPending;
      } else {
        _status = DailyContextStatus.ready;
      }
    } catch (_) {
      _status = DailyContextStatus.cleanupPending;
    }
  }

  Future<void> retry() => _run(() async {
        if (_closed || _memory) return;
        if (_opener != null) {
          await _protected.close();
          _protected = await _opener();
        }
        await _reload();
        notifyListeners();
      });

  Future<bool> _saveAll(Iterable<DailyHydrationContext> values) async {
    if (!isKnown) return false;
    final ordered = values.toList()
      ..sort((a, b) => b.localDateKey.compareTo(a.localDateKey));
    final record = ProtectedContextRecord(
        revision: _revision + 1,
        phase: ContextRecordPhase.active,
        contexts: ordered.take(maxRetainedDays));
    if (!_memory) {
      final result = await _protected.writeDailyContext(record);
      if (result != ProtectedWriteStatus.committed) {
        // A failed verification may follow a committed write. Do not invent
        // rollback, permit stale writes, or continue recommending old context.
        _status = DailyContextStatus.unavailable;
        notifyListeners();
        return false;
      }
    }
    _publish(record);
    if (!_memory) await _cleanup();
    notifyListeners();
    return true;
  }

  Future<bool> save(DailyHydrationContext context) => _run(
      () => _saveAll({..._contexts, context.localDateKey: context}.values));

  Future<bool> remove(String key) => _run(() async {
        if (_status == DailyContextStatus.cleanupPending) await _cleanup();
        if (_status != DailyContextStatus.ready) return false;
        return _saveAll(({..._contexts}..remove(key)).values);
      });

  Future<void> clear() => _run(() async {
        if (_closed) throw const DailyContextUnavailable();
        _contexts = {};
        _status = DailyContextStatus.deletionPending;
        notifyListeners();
        if (_memory) {
          _status = DailyContextStatus.ready;
          notifyListeners();
          return;
        }
        try {
          // Intent must survive restart even when the protected revision
          // cannot yet be read. It contains no context or guessed revision.
          final acknowledged = await _legacy.writeString(
              deletionKey, jsonEncode({'schemaVersion': 2, 'pending': true}));
          if (!acknowledged || !await _finishDeletion()) {
            throw const DailyContextUnavailable();
          }
        } catch (_) {
          throw const DailyContextUnavailable();
        } finally {
          notifyListeners();
        }
      });

  Future<bool> _finishDeletion() async {
    try {
      final read = await _protected.readDailyContext();
      if (read.status != ProtectedReadStatus.found &&
          read.status != ProtectedReadStatus.absent) {
        return false;
      }
      final record = read.record;
      // Reuse a verified tombstone on cleanup retries; otherwise advance
      // from protected truth, not a possibly stale facade revision.
      final revision = record?.phase == ContextRecordPhase.deleted
          ? record!.revision
          : (record?.revision ?? 0) + 1;
      if (await _protected.deleteDailyContext(revision) !=
              ProtectedDeleteStatus.verifiedAbsent ||
          !await _removeAcknowledged(storageKey) ||
          !await _removeAcknowledged(deletionKey)) {
        return false;
      }
      _revision = revision;
    } catch (_) {
      return false;
    }
    _contexts = {};
    _status = DailyContextStatus.ready;
    return true;
  }

  Future<void> close() => _run(() async {
        if (_closed) return;
        _closed = true;
        await _protected.close();
      });
}
