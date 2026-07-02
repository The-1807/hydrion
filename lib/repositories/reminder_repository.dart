import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';
import 'storage_recovery.dart';

class ScheduledReminder {
  final String id;
  final DateTime triggerTime;
  final String message;
  final int priority;

  const ScheduledReminder({
    required this.id,
    required this.triggerTime,
    required this.message,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'triggerTime': triggerTime.toIso8601String(),
      'message': message,
      'priority': priority,
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
    );
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

  Future<ScheduledReminder> save({
    required DateTime triggerTime,
    required String message,
    required int priority,
  }) async {
    final reminder = ScheduledReminder(
      id: 'reminder-${triggerTime.microsecondsSinceEpoch}',
      triggerTime: triggerTime,
      message: message,
      priority: priority,
    );
    _reminders.add(reminder);
    _reminders.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    await _persist();
    notifyListeners();
    return reminder;
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
