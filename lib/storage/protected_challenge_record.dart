import 'dart:convert';

import '../domain/challenge_catalog.dart';

import 'protected_app_store.dart';

/// Typed entry ownership. Parameter encodings have a closed, recursively
/// validated vocabulary below; maps returned to the legacy facade are copies.
final class ProtectedChallengeEntry {
  final String id;
  final int targetMl;
  final int durationDays;
  final DateTime joinedAt;
  final List<int> bottleBingoCompletedTiles;
  final List<String> completedActionIds;
  final String instanceId;
  final String lifecycleStatus;
  final DateTime? endedAt;
  final DateTime? pendingParametersEffectiveDate;
  final String _parameters;
  final String? _pendingParameters;

  ProtectedChallengeEntry._(Map<String, Object?> value)
      : id = value['id'] as String,
        targetMl = value['targetMl'] as int,
        durationDays = value['durationDays'] as int,
        joinedAt = DateTime.parse(value['joinedAt'] as String),
        bottleBingoCompletedTiles = List.unmodifiable(
            (value['bottleBingoCompletedTiles'] as List).cast<int>()),
        completedActionIds = List.unmodifiable(
            (value['completedActionIds'] as List).cast<String>()),
        instanceId = value['instanceId'] as String,
        lifecycleStatus = value['lifecycleStatus'] as String,
        endedAt = value['endedAt'] == null
            ? null
            : DateTime.parse(value['endedAt'] as String),
        pendingParametersEffectiveDate =
            value['pendingParametersEffectiveDate'] == null
                ? null
                : DateTime.parse(
                    value['pendingParametersEffectiveDate'] as String),
        _parameters = jsonEncode(value['parameters']),
        _pendingParameters = value['pendingParameters'] == null
            ? null
            : jsonEncode(value['pendingParameters']);

  Map<String, Object?> get parameters =>
      (jsonDecode(_parameters) as Map).cast<String, Object?>();
  Map<String, Object?> get pendingParameters => _pendingParameters == null
      ? const {}
      : (jsonDecode(_pendingParameters) as Map).cast<String, Object?>();

  Map<String, Object?> toJson() => {
        'schemaVersion': 6,
        'id': id,
        'targetMl': targetMl,
        'durationDays': durationDays,
        'joinedAt': joinedAt.toIso8601String(),
        'bottleBingoCompletedTiles': bottleBingoCompletedTiles,
        'parameters': parameters,
        'completedActionIds': completedActionIds,
        'instanceId': instanceId,
        'lifecycleStatus': lifecycleStatus,
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
        if (_pendingParameters != null) 'pendingParameters': pendingParameters,
        if (pendingParametersEffectiveDate != null)
          'pendingParametersEffectiveDate':
              pendingParametersEffectiveDate!.toIso8601String(),
      };
  @override
  String toString() => 'ProtectedChallengeEntry';
}

/// Closed I08 persistence contract. Unknown fields never become an encrypted
/// extension bag: the original source is retained for explicit recovery.
final class ProtectedChallengeRecord {
  static const schemaVersion = 1;
  final int revision;
  final ContextRecordPhase phase;
  final String _payload;

  ProtectedChallengeRecord({
    required this.revision,
    required this.phase,
    required Map<String, Object?> state,
  }) : _payload = _validateAndEncode(state) {
    if (revision < 1 ||
        (phase == ContextRecordPhase.deleted &&
            ((state['activeChallenges'] as List).isNotEmpty ||
                (state['challengeHistory'] as List).isNotEmpty))) {
      throw const FormatException('Invalid protected challenge revision');
    }
  }

  List<ProtectedChallengeEntry> _entries(String name) =>
      List.unmodifiable(((jsonDecode(_payload) as Map)[name] as List).map((e) =>
          ProtectedChallengeEntry._((e as Map).cast<String, Object?>())));
  List<ProtectedChallengeEntry> get activeChallenges =>
      _entries('activeChallenges');
  List<ProtectedChallengeEntry> get challengeHistory =>
      _entries('challengeHistory');
  Map<String, Object?> get state => {
        'schemaVersion': 6,
        'activeChallenges': activeChallenges.map((e) => e.toJson()).toList(),
        'challengeHistory': challengeHistory.map((e) => e.toJson()).toList(),
      };
  String encodePayload() => _payload;
  bool equivalentTo(ProtectedChallengeRecord other) =>
      revision == other.revision &&
      phase == other.phase &&
      _payload == other._payload;

  static String _validateAndEncode(Map<String, Object?> state) {
    if (state['schemaVersion'] is num && (state['schemaVersion'] as num) > 6) {
      throw const ProtectedContextSchemaUnsupported();
    }
    _fields(
        state, const {'schemaVersion', 'activeChallenges', 'challengeHistory'});
    if (state['schemaVersion'] != 6 ||
        state['activeChallenges'] is! List ||
        state['challengeHistory'] is! List) {
      throw const FormatException('Invalid challenge collection');
    }
    final active = state['activeChallenges'] as List;
    final history = state['challengeHistory'] as List;
    if (active.length > 2 ||
        active.any((e) => e is! Map || e['lifecycleStatus'] != 'active') ||
        history.any((e) => e is! Map || e['lifecycleStatus'] == 'active')) {
      throw const FormatException('Invalid challenge lifecycle collection');
    }
    final instances = <String>{};
    for (final value in [
      ...state['activeChallenges'] as List,
      ...state['challengeHistory'] as List,
    ]) {
      if (value is! Map) throw const FormatException('Invalid challenge entry');
      _fields(value, const {
        'schemaVersion',
        'id',
        'targetMl',
        'durationDays',
        'joinedAt',
        'bottleBingoCompletedTiles',
        'parameters',
        'completedActionIds',
        'instanceId',
        'lifecycleStatus',
        'endedAt',
        'pendingParameters',
        'pendingParametersEffectiveDate',
      });
      if (value['schemaVersion'] != 6 ||
          value['id'] is! String ||
          value['instanceId'] is! String ||
          value['targetMl'] is! int ||
          value['durationDays'] is! int ||
          (value['targetMl'] as int) <= 0 ||
          (value['durationDays'] as int) <= 0 ||
          !const {'active', 'paused', 'completed', 'left', 'archived'}
              .contains(value['lifecycleStatus'])) {
        throw const FormatException('Invalid challenge fields');
      }
      if (!HydrionChallengeCatalog.challenges.any((e) => e.id == value['id']) ||
          (value['instanceId'] as String).isEmpty ||
          !instances.add(value['instanceId'] as String)) {
        throw const FormatException('Invalid challenge identity');
      }
      _date(value['joinedAt']);
      if (value['endedAt'] != null) _date(value['endedAt']);
      if (value['pendingParametersEffectiveDate'] != null) {
        _date(value['pendingParametersEffectiveDate']);
      }
      final tiles = value['bottleBingoCompletedTiles'];
      if (tiles is! List ||
          tiles.any((e) => e is! int || e < 0 || e >= 25 || e == 12)) {
        throw const FormatException('Invalid challenge tiles');
      }
      _strings(value['completedActionIds']);
      _parameters(value['parameters']);
      if (value['pendingParameters'] != null) {
        _parameters(value['pendingParameters']);
      }
    }
    return jsonEncode(_ordered(state));
  }

  static void _parameters(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid challenge parameters');
    }
    const numbers = {
      'amountMl',
      'sessionMinutes',
      'sessionsPerDay',
      'shortBreakMinutes',
      'challengeDurationDays',
      'durationDays',
      'cutoffHour',
      'bingoBoardVersion',
      'windowStartHour',
      'preparationHour',
      'blockMinutes',
      'resetFrequencyMinutes',
      'shiftStartMinutes',
      'shiftDurationMinutes',
      'travelStartHour',
      'reviewHour',
      'timerSession',
      'timerPausedSeconds',
      'activityElapsedSeconds',
    };
    const strings = {
      'noAddedSugar',
      'weatherOrdering',
      'meal',
      'food',
      'notifications',
      'autoStartNext',
      'difficulty',
      'reminderPreference',
      'cue',
      'reminderEnabled',
      'checkpointPattern',
      'reminderTime',
      'optionalNote',
      'displayPreference',
      'temperatureSchedulePreference',
      'startDate',
      'coreMode',
      'completionRule',
      'timerStatus',
      'timerSessionId',
      'timerStartedAt',
      'timerEndsAt',
      'timerReminderId',
      'challengeReminderId',
      'dailyReminderId',
      'lunchReminderId',
      'shiftStartReminderId',
      'shiftMidpointReminderId',
      'shiftEndReminderId',
      'reviewReminderId',
      'activitySessionStatus',
      'activitySessionStartedAt',
      'temperatureAssignmentSource',
      'weatherContext',
      'bottleStatus',
      'lastActivityAt',
      'lastActivityOutcome',
    };
    for (final entry in value.entries) {
      final key = entry.key;
      final item = entry.value;
      if (numbers.contains(key)) {
        if (item is! num || !item.isFinite) {
          throw const FormatException('Invalid numeric challenge parameter');
        }
      } else if (strings.contains(key)) {
        final legacyBoolean = const {
              'reminderEnabled',
              'notifications',
              'autoStartNext',
              'noAddedSugar',
              'weatherOrdering'
            }.contains(key) &&
            item is bool;
        if (item != null && item is! String && !legacyBoolean) {
          throw const FormatException('Invalid text challenge parameter');
        }
      } else if (const {
        'temperatureSchedule',
        'infusionThemeSchedule',
        'pomodoroConsumedSessionIds'
      }.contains(key)) {
        _strings(item);
      } else if (key == 'pomodoroPendingDrink') {
        if (item == null) continue;
        if (item is! Map) throw const FormatException('Invalid pending drink');
        _fields(item, const {'sessionId', 'actionKey', 'eventAt', 'amountMl'});
        if (item['sessionId'] is! String ||
            item['actionKey'] is! String ||
            item['amountMl'] is! int ||
            (item['amountMl'] as int) <= 0) {
          throw const FormatException('Invalid pending drink fields');
        }
        _date(item['eventAt']);
      } else if (key == 'pomodoroSessionHistory') {
        _history(item);
      } else if (key == 'pomodoroSession') {
        if (item is! Map) throw const FormatException('Invalid Pomodoro state');
        _fields(item, const {
          'schemaVersion',
          'challengeInstanceId',
          'sessionId',
          'sessionNumber',
          'totalSeconds',
          'startedAt',
          'completionAt',
          'pausedRemainingSeconds',
          'lifecycle',
          'completionCommitted',
          'reminderId',
          'reminderSchedulingMode',
          'completionActionId',
          'updatedAt',
          'history'
        });
        if (item['schemaVersion'] != 1 ||
            item['challengeInstanceId'] is! String ||
            item['sessionNumber'] is! int ||
            item['totalSeconds'] is! int ||
            item['pausedRemainingSeconds'] is! int ||
            item['completionCommitted'] is! bool ||
            item['lifecycle'] is! String) {
          throw const FormatException('Invalid Pomodoro fields');
        }
        for (final field in const [
          'sessionId',
          'reminderId',
          'reminderSchedulingMode',
          'completionActionId'
        ]) {
          if (item[field] != null && item[field] is! String) {
            throw const FormatException('Invalid Pomodoro identifier');
          }
        }
        _date(item['updatedAt']);
        for (final field in const ['startedAt', 'completionAt']) {
          if (item[field] != null) _date(item[field]);
        }
        _history(item['history']);
      } else {
        throw const FormatException('Unclassified challenge parameter');
      }
    }
  }

  static void _history(Object? value) {
    if (value is! List) throw const FormatException('Invalid session history');
    for (final entry in value) {
      if (entry is! Map) throw const FormatException('Invalid history entry');
      _fields(entry, const {
        'sessionId',
        'sessionNumber',
        'completedAt',
        'hasAuthenticTime',
        'endedEarly'
      });
      if (entry['sessionId'] is! String ||
          entry['sessionNumber'] is! int ||
          (entry['hasAuthenticTime'] != null &&
              entry['hasAuthenticTime'] is! bool) ||
          entry['endedEarly'] is! bool) {
        throw const FormatException('Invalid history fields');
      }
      _date(entry['completedAt']);
    }
  }

  static void _fields(Map value, Set<String> fields) {
    if (value.keys.any((key) => !fields.contains(key))) {
      throw const FormatException('Unknown challenge fields');
    }
  }

  static void _date(Object? value) {
    if (value is! String || DateTime.tryParse(value) == null) {
      throw const FormatException('Invalid challenge date');
    }
  }

  static void _strings(Object? value) {
    if (value is! List || value.any((e) => e is! String)) {
      throw const FormatException('Invalid challenge string collection');
    }
  }

  static Object? _ordered(Object? value) {
    if (value is Map) {
      final keys = value.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: _ordered(value[key])};
    }
    if (value is List) return value.map(_ordered).toList();
    return value;
  }

  @override
  String toString() => 'ProtectedChallengeRecord(${phase.name})';
}

final class ProtectedChallengeRead {
  final ProtectedReadStatus status;
  final ProtectedChallengeRecord? record;
  const ProtectedChallengeRead(this.status, [this.record]);
  @override
  String toString() => 'ProtectedChallengeRead(${status.name})';
}

abstract interface class ProtectedChallengeStore {
  Future<ProtectedChallengeRead> readChallenges();
  Future<ProtectedWriteStatus> writeChallenges(ProtectedChallengeRecord record);
}
