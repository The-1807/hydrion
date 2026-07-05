import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';
import 'storage_recovery.dart';

enum ReminderScheduleState {
  pending,
  scheduled,
  disabled,
  permissionDenied,
  permanentlyDenied,
  unsupported,
  failed,
}

class ScheduledReminder {
  final String id;
  final DateTime triggerTime;
  final String message;
  final int priority;
  final bool enabled;
  final ReminderScheduleState scheduleState;
  final String? scheduleError;
  final DateTime? lastScheduledAt;

  const ScheduledReminder({
    required this.id,
    required this.triggerTime,
    required this.message,
    required this.priority,
    this.enabled = true,
    this.scheduleState = ReminderScheduleState.pending,
    this.scheduleError,
    this.lastScheduledAt,
  });

  int get platformNotificationId => id.hashCode & 0x7fffffff;

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
    };
  }

  static ScheduledReminder? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }
    final triggerTime =
        DateTime.tryParse((value['triggerTime'] ?? '').toString());
    final message = (value['message'] ?? '').toString().trim();
    final priority = value['priority'];

    if (triggerTime == null ||
        message.isEmpty ||
        priority is! num ||
        !priority.isFinite) {
      return null;
    }

    return ScheduledReminder(
      id: (value['id'] ?? triggerTime.millisecondsSinceEpoch).toString(),
      triggerTime: triggerTime,
      message: message,
      priority: priority.round(),
      enabled: value['enabled'] != false,
      scheduleState: _safeScheduleState(value['scheduleState']),
      scheduleError: _safeShortText(value['scheduleError']),
      lastScheduledAt:
          DateTime.tryParse((value['lastScheduledAt'] ?? '').toString()),
    );
  }

  static ReminderScheduleState _safeScheduleState(Object? value) {
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
  static const storageKey = 'hydrion.reminders.v1';
  static const _category = 'reminders';
  static const _currentSchemaVersion = 1;

  final HydrionLocalStore _store;
  final List<ScheduledReminder> _reminders;
  final List<StorageRecoveryEvent> _recoveryEvents;

  ReminderRepository._(
    this._store,
    List<ScheduledReminder> reminders, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ])  : _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        ),
        _reminders = List<ScheduledReminder>.of(reminders)
          ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));

  ReminderRepository.memory()
      : this._(MemoryHydrionStore(), <ScheduledReminder>[]);

  static Future<ReminderRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final result = _decodeReminders(raw);
    return ReminderRepository._(
      store,
      result.reminders,
      result.recoveryEvents,
    );
  }

  List<ScheduledReminder> get reminders =>
      List<ScheduledReminder>.unmodifiable(_reminders);

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  ScheduledReminder? byId(String id) {
    for (final reminder in _reminders) {
      if (reminder.id == id) {
        return reminder;
      }
    }
    return null;
  }

  Future<ScheduledReminder> save({
    required DateTime triggerTime,
    required String message,
    required int priority,
    bool enabled = true,
  }) async {
    final reminder = ScheduledReminder(
      id: 'reminder-${triggerTime.microsecondsSinceEpoch}',
      triggerTime: triggerTime,
      message: message,
      priority: priority,
      enabled: enabled,
    );
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    await _persist();
    notifyListeners();
    return reminder;
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
  }) async {
    final index = _reminders.indexWhere((reminder) => reminder.id == id);
    if (index == -1) {
      return null;
    }
    final nextMessage = message?.trim();
    if (nextMessage != null && nextMessage.isEmpty) {
      return null;
    }
    final nextPriority = priority ?? _reminders[index].priority;
    if (nextPriority < 0) {
      return null;
    }
    _reminders[index] = _reminders[index].copyWith(
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
    _reminders.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    await _persist();
    notifyListeners();
    return byId(id);
  }

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
      clearLastScheduledAt:
          scheduledAt == null && state != ReminderScheduleState.scheduled,
    );
  }

  Future<bool> delete(String id) async {
    final before = _reminders.length;
    _reminders.removeWhere((reminder) => reminder.id == id);
    if (_reminders.length == before) {
      return false;
    }
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> clear() async {
    _reminders.clear();
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    await _store.writeString(
      storageKey,
      jsonEncode(_reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  static _ReminderDecodeResult _decodeReminders(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _ReminderDecodeResult(<ScheduledReminder>[]);
    }

    try {
      final decoded = jsonDecode(raw);
      final schemaVersion = storageSchemaVersion(decoded);
      if (schemaVersion != null && schemaVersion > _currentSchemaVersion) {
        return _ReminderDecodeResult(
          const <ScheduledReminder>[],
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
        return const _ReminderDecodeResult(
          <ScheduledReminder>[],
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.fallbackEmpty,
            ),
          ],
        );
      }
      final reminders = <ScheduledReminder>[];
      var skippedRecords = 0;
      for (final record in decoded) {
        final reminder = ScheduledReminder.fromJson(record);
        if (reminder == null) {
          skippedRecords += 1;
          continue;
        }
        reminders.add(reminder);
      }
      return _ReminderDecodeResult(
        reminders,
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
      return const _ReminderDecodeResult(
        <ScheduledReminder>[],
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

class _ReminderDecodeResult {
  final List<ScheduledReminder> reminders;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _ReminderDecodeResult(
    this.reminders, {
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
