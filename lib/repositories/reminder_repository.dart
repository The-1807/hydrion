import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/app_persistence.dart';
import '../storage/local_store.dart';
import '../storage/protected_app_store.dart';
import '../storage/protected_reminder_record.dart';
import 'reminder_protection.dart';
export 'reminder_protection.dart'
    show ReminderStorageStatus, ReminderStorageUnavailable;
import 'storage_recovery.dart';

enum ReminderScheduleState {
  pending,
  scheduledExactly,
  scheduledApproximately,
  permissionRequired,
  needsRescheduling,
  schedulingFailed,
  disabled,
  unsupported,
}

class ScheduledReminder {
  static const maxMessageLength = 160;
  static const minPriority = 0;
  static const maxPriority = 5;

  final String id;
  final DateTime triggerTime;
  final String message;
  final int priority;
  final bool enabled;
  final ReminderScheduleState scheduleState;
  final String? scheduleError;
  final DateTime? lastScheduledAt;
  final String? challengeId;

  const ScheduledReminder({
    required this.id,
    required this.triggerTime,
    required this.message,
    required this.priority,
    this.enabled = true,
    this.scheduleState = ReminderScheduleState.pending,
    this.scheduleError,
    this.lastScheduledAt,
    this.challengeId,
  });

  int get platformNotificationId => platformIdFor(id);

  /// Existing OS notification ID derivation, unchanged by I09.
  static int platformIdFor(String id) => id.hashCode & 0x7fffffff;

  static String? safeMessage(Object? value) {
    if (value is! String) {
      return null;
    }
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || text.length > maxMessageLength) {
      return null;
    }
    return text;
  }

  static int? safePriority(Object? value) {
    if (value is! num || !value.isFinite) {
      return null;
    }
    final priority = value.round();
    if (priority < minPriority || priority > maxPriority) {
      return null;
    }
    return priority;
  }

  ScheduledReminder copyWith({
    DateTime? triggerTime,
    String? message,
    int? priority,
    bool? enabled,
    ReminderScheduleState? scheduleState,
    String? scheduleError,
    bool clearScheduleError = false,
    DateTime? lastScheduledAt,
    bool clearLastScheduledAt = false,
  }) {
    return ScheduledReminder(
      id: id,
      triggerTime: triggerTime ?? this.triggerTime,
      message: message ?? this.message,
      priority: priority ?? this.priority,
      enabled: enabled ?? this.enabled,
      scheduleState: scheduleState ?? this.scheduleState,
      scheduleError:
          clearScheduleError ? null : scheduleError ?? this.scheduleError,
      lastScheduledAt:
          clearLastScheduledAt ? null : lastScheduledAt ?? this.lastScheduledAt,
      challengeId: challengeId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'triggerTime': triggerTime.toIso8601String(),
      'message': message,
      'priority': priority,
      'enabled': enabled,
      'scheduleState': scheduleState.name,
      'scheduleError': scheduleError,
      'lastScheduledAt': lastScheduledAt?.toIso8601String(),
      'challengeId': challengeId,
    };
  }

  /// Canonical protected entry; null optional fields are omitted.
  Map<String, Object?> toProtectedJson() => {
        'id': id,
        'triggerTime': triggerTime.toIso8601String(),
        'message': message,
        'priority': priority,
        'enabled': enabled,
        'scheduleState': scheduleState.name,
        if (scheduleError != null) 'scheduleError': scheduleError,
        if (lastScheduledAt != null)
          'lastScheduledAt': lastScheduledAt!.toIso8601String(),
        if (challengeId != null) 'challengeId': challengeId,
      };

  /// Decodes an entry already validated by [ProtectedReminderRecord].
  static ScheduledReminder fromProtectedJson(Map<String, Object?> value) =>
      ScheduledReminder(
        id: value['id'] as String,
        triggerTime: DateTime.parse(value['triggerTime'] as String),
        message: value['message'] as String,
        priority: value['priority'] as int,
        enabled: value['enabled'] as bool,
        scheduleState: ReminderScheduleState.values
            .byName(value['scheduleState'] as String),
        scheduleError: value['scheduleError'] as String?,
        lastScheduledAt: value['lastScheduledAt'] == null
            ? null
            : DateTime.parse(value['lastScheduledAt'] as String),
        challengeId: value['challengeId'] as String?,
      );

  /// Strict migration decoder for one legacy entry. Present user-authored or
  /// identity values that the tolerant loader would silently drop or rewrite
  /// are rejected so the source is quarantined, not converted.
  static Map<String, Object?> legacyToProtectedJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid legacy reminder entry');
    }
    const fields = {
      'id',
      'triggerTime',
      'message',
      'priority',
      'enabled',
      'scheduleState',
      'scheduleError',
      'lastScheduledAt',
      'challengeId',
    };
    if (value.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown legacy reminder fields');
    }
    final id = value['id'];
    final enabled = value['enabled'];
    final lastScheduledAt = value['lastScheduledAt'];
    final challengeId = value['challengeId'];
    final scheduleError = value['scheduleError'];
    if ((id != null && id is! String && id is! int) ||
        (enabled != null && enabled is! bool) ||
        (lastScheduledAt != null &&
            (lastScheduledAt is! String ||
                DateTime.tryParse(lastScheduledAt) == null)) ||
        (challengeId != null &&
            (challengeId is! String ||
                _safeShortText(challengeId) != challengeId)) ||
        (scheduleError != null && scheduleError is! String) ||
        (value['scheduleState'] != null && value['scheduleState'] is! String)) {
      throw const FormatException('Invalid legacy reminder fields');
    }
    final reminder = fromJson(value);
    if (reminder == null) {
      throw const FormatException('Invalid legacy reminder entry');
    }
    final safeError = _safeShortText(scheduleError);
    return reminder
        .copyWith(
          scheduleError: safeError == null
              ? null
              : ProtectedReminderRecord.scheduleErrors.contains(safeError)
                  ? safeError
                  : ProtectedReminderRecord.legacyUnclassifiedError,
          clearScheduleError: safeError == null,
        )
        .toProtectedJson();
  }

  static ScheduledReminder? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final triggerTime =
        DateTime.tryParse((value['triggerTime'] ?? '').toString());
    final message = safeMessage(value['message']);
    final priority = safePriority(value['priority']);

    if (triggerTime == null || message == null || priority == null) {
      return null;
    }

    return ScheduledReminder(
      id: (value['id'] ?? triggerTime.millisecondsSinceEpoch).toString(),
      triggerTime: triggerTime,
      message: message,
      priority: priority,
      enabled: value['enabled'] != false,
      scheduleState: _safeScheduleState(value['scheduleState']),
      scheduleError: _safeShortText(value['scheduleError']),
      lastScheduledAt:
          DateTime.tryParse((value['lastScheduledAt'] ?? '').toString()),
      challengeId: _safeShortText(value['challengeId']),
    );
  }

  static ReminderScheduleState _safeScheduleState(Object? value) {
    if (value == 'scheduled') {
      return ReminderScheduleState.scheduledApproximately;
    }
    if (value == 'permissionDenied' || value == 'permanentlyDenied') {
      return ReminderScheduleState.permissionRequired;
    }
    if (value == 'failed') {
      return ReminderScheduleState.schedulingFailed;
    }
    if (value is String) {
      for (final state in ReminderScheduleState.values) {
        if (state.name == value) {
          return state;
        }
      }
    }
    return ReminderScheduleState.pending;
  }

  static String? _safeShortText(Object? value) {
    if (value is! String) {
      return null;
    }
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty || text.length > 220) {
      return null;
    }
    return text;
  }
}

class ReminderRepository extends ChangeNotifier {
  static const storageKey = ReminderProtection.storageKey;
  static const orphanCleanupStorageKey = ReminderProtection.orphanStorageKey;
  static const _currentSchemaVersion = 1;

  final HydrionLocalStore _store;
  ReminderProtection? _protection;
  Future<ProtectedAppStore> Function()? _opener;
  List<ScheduledReminder> _reminders;
  Set<int> _orphanNotificationIds;
  final List<StorageRecoveryEvent> _recoveryEvents;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  ReminderRepository._(
    this._store,
    List<ScheduledReminder> reminders, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
    Set<int> orphanNotificationIds = const <int>{},
  ])  : _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        ),
        _orphanNotificationIds = Set<int>.of(orphanNotificationIds),
        _reminders = _sorted(reminders);

  /// Explicit unprotected test/preview facility, never a production fallback.
  ReminderRepository.memory()
      : this._(MemoryHydrionStore(), <ScheduledReminder>[]);

  /// Production loader: the protected I09 authority is the only destination.
  /// Unsupported or unavailable protection is reported, never replaced by
  /// plaintext preferences or memory.
  static Future<ReminderRepository> load(
    HydrionLocalStore store, {
    ProtectedAppStore? protectedStore,
    Future<ProtectedAppStore> Function()? opener,
  }) async {
    final repository = ReminderRepository._(store, const <ScheduledReminder>[]);
    repository._protection = ReminderProtection(
      store,
      protectedStore ?? await (opener ?? openProtectedAppStore)(),
      platformIdOf: ScheduledReminder.platformIdFor,
    );
    await repository.refreshFromStore();
    repository._opener =
        protectedStore == null ? opener ?? openProtectedAppStore : null;
    return repository;
  }

  ReminderStorageStatus get storageStatus =>
      _protection?.status ?? ReminderStorageStatus.ready;

  /// False while reminder storage is unavailable, corrupt, unsupported or
  /// deletion-pending. Consumers must not treat an unknown store as empty.
  bool get isKnown => !_closed && (_protection?.isKnown ?? true);

  List<ScheduledReminder> get reminders => isKnown
      ? List<ScheduledReminder>.unmodifiable(_reminders)
      : const <ScheduledReminder>[];

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  Set<int> get orphanNotificationIds =>
      isKnown ? Set<int>.unmodifiable(_orphanNotificationIds) : const <int>{};

  ScheduledReminder? byId(String id) {
    if (!isKnown) return null;
    for (final reminder in _reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }

  /// Serializes every load/mutation through one per-instance queue.
  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> refreshFromStore() => _serial(() async {
        if (_closed) throw const ReminderStorageUnavailable();
        var protection = _protection;
        if (protection == null) return;
        if (_opener != null && !protection.isKnown) {
          await protection.store.close();
          protection = ReminderProtection(_store, await _opener!(),
              platformIdOf: ScheduledReminder.platformIdFor);
          _protection = protection;
        }
        await protection.load(decodeLegacyForMigration);
        _publishFromProtection();
        notifyListeners();
      });

  void _publishFromProtection() {
    final protection = _protection;
    final record = protection?.record;
    if (protection == null || !protection.isKnown || record == null) {
      _reminders = const <ScheduledReminder>[];
      _orphanNotificationIds = <int>{};
      return;
    }
    _reminders =
        _sorted(record.reminders.map(ScheduledReminder.fromProtectedJson));
    _orphanNotificationIds = Set<int>.of(record.orphanNotificationIds);
  }

  Future<void> close() => _serial(() async {
        _closed = true;
        await _protection?.store.close();
      });

  /// Commits the complete next state, then publishes it. Nothing is
  /// published or notified before the protected write is verified.
  Future<void> _commit(
    List<ScheduledReminder> next,
    Set<int> nextOrphans,
  ) async {
    if (_closed) throw const ReminderStorageUnavailable();
    final protection = _protection;
    if (protection == null) {
      await _persistUnprotected(next, nextOrphans);
    } else {
      if (!protection.isKnown) throw const ReminderStorageUnavailable();
      try {
        await protection.save(ProtectedReminderRecord.canonicalState(
          reminders: next.map((reminder) => reminder.toProtectedJson()),
          orphanNotificationIds: nextOrphans,
        ));
      } on ReminderStorageUnavailable {
        notifyListeners();
        rethrow;
      }
    }
    _reminders = _sorted(next);
    _orphanNotificationIds = Set<int>.of(nextOrphans);
    notifyListeners();
  }

  void _requireKnown() {
    if (!isKnown) throw const ReminderStorageUnavailable();
  }

  Future<ScheduledReminder> save({
    required DateTime triggerTime,
    required String message,
    required int priority,
    bool enabled = true,
    String? challengeId,
  }) async {
    final safeMessage = ScheduledReminder.safeMessage(message);
    final safePriority = ScheduledReminder.safePriority(priority);
    if (safeMessage == null || safePriority == null) {
      throw ArgumentError.value(
        safeMessage == null ? message : priority,
        safeMessage == null ? 'message' : 'priority',
        'Reminder details are outside Hydrion limits.',
      );
    }
    return _serial(() async {
      _requireKnown();
      final base = 'reminder-${triggerTime.microsecondsSinceEpoch}';
      var id = base;
      for (var suffix = 1; _reminders.any((e) => e.id == id); suffix++) {
        id = '$base-$suffix';
      }
      final reminder = ScheduledReminder(
        id: id,
        triggerTime: triggerTime,
        message: safeMessage,
        priority: safePriority,
        enabled: enabled,
        challengeId: challengeId,
      );
      await _commit([..._reminders, reminder], _orphanNotificationIds);
      return reminder;
    });
  }

  Future<ScheduledReminder?> update({
    required String id,
    DateTime? triggerTime,
    String? message,
    int? priority,
    bool? enabled,
    ReminderScheduleState? scheduleState,
    String? scheduleError,
    bool clearScheduleError = false,
    DateTime? lastScheduledAt,
    bool clearLastScheduledAt = false,
  }) =>
      _serial(() async {
        _requireKnown();
        final index = _reminders.indexWhere((reminder) => reminder.id == id);
        if (index == -1) {
          return null;
        }
        final nextMessage =
            message == null ? null : ScheduledReminder.safeMessage(message);
        if (message != null && nextMessage == null) {
          return null;
        }
        final nextPriority = priority == null
            ? _reminders[index].priority
            : ScheduledReminder.safePriority(priority);
        if (nextPriority == null) {
          return null;
        }
        final next = List<ScheduledReminder>.of(_reminders);
        next[index] = next[index].copyWith(
          triggerTime: triggerTime,
          message: nextMessage,
          priority: nextPriority,
          enabled: enabled,
          scheduleState: scheduleState,
          scheduleError: scheduleError,
          clearScheduleError: clearScheduleError,
          lastScheduledAt: lastScheduledAt,
          clearLastScheduledAt: clearLastScheduledAt,
        );
        await _commit(next, _orphanNotificationIds);
        return next[index];
      });

  Future<ScheduledReminder?> setScheduleState({
    required String id,
    required ReminderScheduleState state,
    String? error,
    DateTime? scheduledAt,
  }) {
    return update(
      id: id,
      scheduleState: state,
      scheduleError: error,
      clearScheduleError: error == null,
      lastScheduledAt: scheduledAt,
      clearLastScheduledAt: scheduledAt == null &&
          state != ReminderScheduleState.scheduledExactly &&
          state != ReminderScheduleState.scheduledApproximately,
    );
  }

  Future<bool> delete(String id) => _serial(() async {
        _requireKnown();
        final next = _reminders.where((reminder) => reminder.id != id).toList();
        if (next.length == _reminders.length) {
          return false;
        }
        await _commit(next, _orphanNotificationIds);
        return true;
      });

  /// Deletes reminder definitions through the I09 deletion protocol. The
  /// outstanding OS-cancellation set is retained, never erased by deletion.
  Future<void> clear() => _serial(() async {
        if (_closed) throw const ReminderStorageUnavailable();
        final protection = _protection;
        if (protection == null) {
          _reminders = const <ScheduledReminder>[];
          await _store.remove(storageKey);
          notifyListeners();
          return;
        }
        try {
          await protection.clear();
        } finally {
          _publishFromProtection();
          notifyListeners();
        }
      });

  Future<void> recordOrphanNotificationIds(Iterable<int> ids) =>
      _serial(() async {
        _requireKnown();
        final next = {..._orphanNotificationIds, ...ids.where((id) => id >= 0)};
        if (next.length == _orphanNotificationIds.length) return;
        await _commit(_reminders, next);
      });

  Future<void> resolveOrphanNotificationId(int id) => _serial(() async {
        _requireKnown();
        if (!_orphanNotificationIds.contains(id)) {
          return;
        }
        await _commit(_reminders, {..._orphanNotificationIds}..remove(id));
      });

  Future<void> _persistUnprotected(
    List<ScheduledReminder> reminders,
    Set<int> orphans,
  ) async {
    await _store.writeString(
      storageKey,
      jsonEncode(reminders.map((reminder) => reminder.toJson()).toList()),
    );
    if (orphans.isEmpty) {
      await _store.remove(orphanCleanupStorageKey);
    } else {
      await _store.writeString(
          orphanCleanupStorageKey, jsonEncode(orphans.toList()..sort()));
    }
  }

  static List<ScheduledReminder> _sorted(Iterable<ScheduledReminder> values) =>
      List<ScheduledReminder>.of(values)
        ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));

  /// Strict legacy migration: both preference keys form one I09 source.
  /// Malformed, future, partially invalid or wrongly shaped input throws,
  /// leaving the source preserved for explicit recovery.
  static Map<String, Object?> decodeLegacyForMigration(
    String? remindersRaw,
    String? orphansRaw,
  ) {
    final reminders = <Map<String, Object?>>[];
    if (remindersRaw != null && remindersRaw.trim().isNotEmpty) {
      final Object? decoded;
      try {
        decoded = jsonDecode(remindersRaw);
      } catch (_) {
        throw const FormatException('Malformed legacy reminders');
      }
      final schemaVersion = storageSchemaVersion(decoded);
      if (schemaVersion != null && schemaVersion > _currentSchemaVersion) {
        throw const ProtectedContextSchemaUnsupported();
      }
      if (decoded is! List) {
        throw const FormatException('Invalid legacy reminder collection');
      }
      for (final record in decoded) {
        reminders.add(ScheduledReminder.legacyToProtectedJson(record));
      }
    }
    final orphans = <int>{};
    if (orphansRaw != null && orphansRaw.trim().isNotEmpty) {
      final Object? decoded;
      try {
        decoded = jsonDecode(orphansRaw);
      } catch (_) {
        throw const FormatException('Malformed legacy orphan IDs');
      }
      if (decoded is! List) {
        throw const FormatException('Invalid legacy orphan IDs');
      }
      for (final value in decoded) {
        if (value is! int ||
            value < 0 ||
            value > ProtectedReminderRecord.maxPlatformId) {
          throw const FormatException('Invalid legacy orphan ID');
        }
        orphans.add(value);
      }
    }
    final state = ProtectedReminderRecord.canonicalState(
        reminders: reminders, orphanNotificationIds: orphans);
    // Validates identity uniqueness and the closed schema before migration.
    ProtectedReminderRecord(
        revision: 1, phase: ContextRecordPhase.provisional, state: state);
    return state;
  }
}
