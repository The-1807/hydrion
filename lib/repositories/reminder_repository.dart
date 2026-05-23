import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';

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

    if (triggerTime == null || message.isEmpty || priority is! num) {
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

  final HydrionLocalStore _store;
  final List<ScheduledReminder> _reminders;

  ReminderRepository._(this._store, List<ScheduledReminder> reminders)
      : _reminders = reminders
          ..sort((a, b) => a.triggerTime.compareTo(b.triggerTime));

  ReminderRepository.memory()
      : this._(MemoryHydrionStore(), <ScheduledReminder>[]);

  static Future<ReminderRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final reminders = _decodeReminders(raw);
    return ReminderRepository._(store, reminders);
  }

  List<ScheduledReminder> get reminders =>
      List<ScheduledReminder>.unmodifiable(_reminders);

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

  static List<ScheduledReminder> _decodeReminders(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return <ScheduledReminder>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <ScheduledReminder>[];
      }
      return decoded
          .map(ScheduledReminder.fromJson)
          .whereType<ScheduledReminder>()
          .toList();
    } on FormatException {
      return <ScheduledReminder>[];
    }
  }
}
