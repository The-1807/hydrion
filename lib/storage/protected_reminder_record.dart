import 'dart:convert';

import 'protected_app_store.dart';

/// Closed I09 persistence contract: reminder definitions and the outstanding
/// OS-cancellation set share one protected authority. Unknown fields are
/// rejected rather than carried as an encrypted extension bag.
final class ProtectedReminderRecord {
  static const schemaVersion = 1;
  static const maxMessageLength = 160;
  static const maxPlatformId = 0x7fffffff;

  /// Closed diagnostic vocabulary. Earlier builds persisted free-form text;
  /// migration maps any such value to [legacyUnclassifiedError].
  static const legacyUnclassifiedError = 'legacy_unclassified';
  static const scheduleErrors = <String>{
    'duplicate_notification',
    'time_passed',
    'scheduling_unavailable',
    'permission_check_failed',
    'notification_permission_required',
    'android_schedule_failed',
    'schedule_failed',
    legacyUnclassifiedError,
  };
  static const scheduleStates = <String>{
    'pending',
    'scheduledExactly',
    'scheduledApproximately',
    'permissionRequired',
    'needsRescheduling',
    'schedulingFailed',
    'disabled',
    'unsupported',
  };

  final int revision;
  final ContextRecordPhase phase;
  final String _payload;

  ProtectedReminderRecord({
    required this.revision,
    required this.phase,
    required Map<String, Object?> state,
  }) : _payload = _validateAndEncode(state) {
    if (revision < 1 ||
        (phase == ContextRecordPhase.deleted &&
            (state['reminders'] as List).isNotEmpty)) {
      throw const FormatException('Invalid protected reminder revision');
    }
  }

  /// Defensive decoded copies of each canonical reminder entry.
  List<Map<String, Object?>> get reminders =>
      List.unmodifiable(((jsonDecode(_payload) as Map)['reminders'] as List)
          .map((e) => Map<String, Object?>.unmodifiable(
              (e as Map).cast<String, Object?>())));

  /// Outstanding OS cancellations. Independent of [reminders]: an empty
  /// reminder collection never implies an empty cleanup set.
  Set<int> get orphanNotificationIds => Set.unmodifiable(
      ((jsonDecode(_payload) as Map)['orphanNotificationIds'] as List)
          .cast<int>());

  Map<String, Object?> get state =>
      (jsonDecode(_payload) as Map).cast<String, Object?>();
  String encodePayload() => _payload;
  bool equivalentTo(ProtectedReminderRecord other) =>
      revision == other.revision &&
      phase == other.phase &&
      _payload == other._payload;

  static Map<String, Object?> canonicalState({
    required Iterable<Map<String, Object?>> reminders,
    required Iterable<int> orphanNotificationIds,
  }) =>
      {
        'schemaVersion': schemaVersion,
        'reminders': reminders.toList(),
        'orphanNotificationIds': orphanNotificationIds.toSet().toList()..sort(),
      };

  static String _validateAndEncode(Map<String, Object?> state) {
    if (state['schemaVersion'] is num &&
        (state['schemaVersion'] as num) > schemaVersion) {
      throw const ProtectedContextSchemaUnsupported();
    }
    _fields(
        state, const {'schemaVersion', 'reminders', 'orphanNotificationIds'});
    final reminders = state['reminders'];
    final orphans = state['orphanNotificationIds'];
    if (state['schemaVersion'] != schemaVersion ||
        reminders is! List ||
        orphans is! List) {
      throw const FormatException('Invalid reminder collection');
    }
    final ids = <String>{};
    for (final value in reminders) {
      if (value is! Map) throw const FormatException('Invalid reminder entry');
      _fields(value, const {
        'id',
        'triggerTime',
        'message',
        'priority',
        'enabled',
        'scheduleState',
        'scheduleError',
        'lastScheduledAt',
        'challengeId',
      });
      final id = value['id'];
      final message = value['message'];
      final priority = value['priority'];
      if (id is! String ||
          !_isIdentifier(id, 128) ||
          !ids.add(id) ||
          message is! String ||
          !_isNormalizedMessage(message) ||
          priority is! int ||
          priority < 0 ||
          priority > 5 ||
          value['enabled'] is! bool ||
          !scheduleStates.contains(value['scheduleState'])) {
        throw const FormatException('Invalid reminder fields');
      }
      _date(value['triggerTime']);
      final error = value['scheduleError'];
      if (error != null && !scheduleErrors.contains(error)) {
        throw const FormatException('Unclassified reminder diagnostic');
      }
      if (value['lastScheduledAt'] != null) _date(value['lastScheduledAt']);
      final challengeId = value['challengeId'];
      if (challengeId != null &&
          (challengeId is! String || !_isIdentifier(challengeId, 64))) {
        throw const FormatException('Invalid reminder challenge link');
      }
    }
    final seen = <int>{};
    for (final value in orphans) {
      if (value is! int ||
          value < 0 ||
          value > maxPlatformId ||
          !seen.add(value)) {
        throw const FormatException('Invalid orphan notification ID');
      }
    }
    final ordered = {
      'schemaVersion': schemaVersion,
      'reminders': [
        for (final value in reminders)
          {
            for (final key
                in ((value as Map).keys.cast<String>().toList()..sort()))
              if (value[key] != null) key: value[key],
          }
      ]..sort((a, b) {
          final byTime = DateTime.parse(a['triggerTime'] as String)
              .compareTo(DateTime.parse(b['triggerTime'] as String));
          return byTime != 0
              ? byTime
              : (a['id'] as String).compareTo(b['id'] as String);
        }),
      'orphanNotificationIds': (orphans.cast<int>().toList()..sort()),
    };
    return jsonEncode(ordered);
  }

  static bool _isIdentifier(String value, int maxLength) =>
      value.isNotEmpty &&
      value.length <= maxLength &&
      RegExp(r'^[A-Za-z0-9._:-]+$').hasMatch(value);

  static bool _isNormalizedMessage(String value) =>
      value.isNotEmpty &&
      value.length <= maxMessageLength &&
      value == value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static void _fields(Map value, Set<String> fields) {
    if (value.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown reminder fields');
    }
  }

  static void _date(Object? value) {
    if (value is! String || DateTime.tryParse(value) == null) {
      throw const FormatException('Invalid reminder date');
    }
  }

  @override
  String toString() => 'ProtectedReminderRecord(${phase.name})';
}

final class ProtectedReminderRead {
  final ProtectedReadStatus status;
  final ProtectedReminderRecord? record;
  const ProtectedReminderRead(this.status, [this.record]);
  @override
  String toString() => 'ProtectedReminderRead(${status.name})';
}

abstract interface class ProtectedReminderStore {
  Future<ProtectedReminderRead> readReminders();
  Future<ProtectedWriteStatus> writeReminders(ProtectedReminderRecord record);
}
