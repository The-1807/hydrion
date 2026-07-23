import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/challenge_catalog.dart';
import '../domain/challenge_experience.dart';
import '../domain/bottle_bingo.dart';
import '../domain/hydration_contracts.dart';
import '../storage/local_store.dart';
import 'hydration_repository.dart';
import 'storage_recovery.dart';

enum ChallengeLifecycleStatus { active, paused, completed, left, archived }

enum ChallengeEditEffect {
  immediate,
  nextLocalDay,
  restartRequired,
  notEditableWhileActive,
}

class ChallengeEditPolicy {
  static const immediateKeys = <String>{
    'reminderEnabled',
    'reminderTime',
    'notifications',
    'autoStartNext',
    'optionalNote',
    'displayPreference',
  };
  static const nextDayKeys = <String>{
    'weatherOrdering',
    'temperatureSchedulePreference',
    'infusionThemeSchedule',
    'sessionMinutes',
    'sessionsPerDay',
    'meal',
    'food',
    'amountMl',
    'cutoffHour',
    'reminderPreference',
  };
  static const restartRequiredKeys = <String>{
    'difficulty',
    'challengeDurationDays',
    'durationDays',
    'bingoBoardVersion',
    'startDate',
    'coreMode',
    'completionRule',
  };

  static ChallengeEditEffect effectFor(String key) {
    if (immediateKeys.contains(key)) return ChallengeEditEffect.immediate;
    if (nextDayKeys.contains(key)) return ChallengeEditEffect.nextLocalDay;
    if (restartRequiredKeys.contains(key)) {
      return ChallengeEditEffect.restartRequired;
    }
    return ChallengeEditEffect.notEditableWhileActive;
  }
}

class ChallengeLifecycleChange {
  final bool changed;
  final JoinedChallenge? challenge;
  final List<String> obsoleteReminderIds;

  const ChallengeLifecycleChange({
    required this.changed,
    this.challenge,
    this.obsoleteReminderIds = const <String>[],
  });
}

class ChallengeEditResult {
  final bool changed;
  final ChallengeEditEffect effect;
  final JoinedChallenge? challenge;
  final String message;

  const ChallengeEditResult({
    required this.changed,
    required this.effect,
    required this.message,
    this.challenge,
  });
}

class JoinedChallenge {
  final String id;
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;
  final DateTime joinedAt;
  final Set<int> bottleBingoCompletedTiles;
  final Map<String, Object?> parameters;
  final Set<String> completedActionIds;
  final String? storedInstanceId;
  final ChallengeLifecycleStatus lifecycleStatus;
  final DateTime? endedAt;
  final Map<String, Object?> pendingParameters;
  final DateTime? pendingParametersEffectiveDate;

  const JoinedChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
    required this.joinedAt,
    this.bottleBingoCompletedTiles = const <int>{},
    this.parameters = const <String, Object?>{},
    this.completedActionIds = const <String>{},
    this.storedInstanceId,
    this.lifecycleStatus = ChallengeLifecycleStatus.active,
    this.endedAt,
    this.pendingParameters = const <String, Object?>{},
    this.pendingParametersEffectiveDate,
  });

  String get instanceId =>
      storedInstanceId ?? '$id-${joinedAt.microsecondsSinceEpoch}';

  bool get needsSetup {
    final definition = HydrionChallengeExperiences.findById(id);
    if (definition == null) return true;
    final required = definition.requiredParameters;
    return required.any((key) {
      final value = parameters[key];
      return value == null || value.toString().trim().isEmpty;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': ChallengeRepository._currentSchemaVersion,
      'id': id,
      'name': name,
      'description': description,
      'targetMl': targetMl,
      'durationDays': durationDays,
      'joinedAt': joinedAt.toIso8601String(),
      'bottleBingoCompletedTiles': bottleBingoCompletedTiles.toList()..sort(),
      'parameters': parameters,
      'completedActionIds': completedActionIds.toList()..sort(),
      'instanceId': instanceId,
      'lifecycleStatus': lifecycleStatus.name,
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      if (pendingParameters.isNotEmpty) 'pendingParameters': pendingParameters,
      if (pendingParametersEffectiveDate != null)
        'pendingParametersEffectiveDate':
            pendingParametersEffectiveDate!.toIso8601String(),
    };
  }

  JoinedChallenge copyWith({
    Set<int>? bottleBingoCompletedTiles,
    Map<String, Object?>? parameters,
    Set<String>? completedActionIds,
    String? storedInstanceId,
    ChallengeLifecycleStatus? lifecycleStatus,
    DateTime? endedAt,
    Map<String, Object?>? pendingParameters,
    DateTime? pendingParametersEffectiveDate,
    bool clearEndedAt = false,
    bool clearPendingParametersEffectiveDate = false,
  }) {
    return JoinedChallenge(
      id: id,
      name: name,
      description: description,
      targetMl: targetMl,
      durationDays: durationDays,
      joinedAt: joinedAt,
      bottleBingoCompletedTiles:
          bottleBingoCompletedTiles ?? this.bottleBingoCompletedTiles,
      parameters: parameters ?? this.parameters,
      completedActionIds: completedActionIds ?? this.completedActionIds,
      storedInstanceId: storedInstanceId ?? this.storedInstanceId,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      endedAt: clearEndedAt ? null : endedAt ?? this.endedAt,
      pendingParameters: pendingParameters ?? this.pendingParameters,
      pendingParametersEffectiveDate: clearPendingParametersEffectiveDate
          ? null
          : pendingParametersEffectiveDate ??
              this.pendingParametersEffectiveDate,
    );
  }

  static JoinedChallenge? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final id = (value['id'] ?? '').toString().trim();
    final name = (value['name'] ?? '').toString().trim();
    final description = (value['description'] ?? '').toString().trim();
    final targetMl = value['targetMl'];
    final durationDays = value['durationDays'];
    final joinedAt = DateTime.tryParse((value['joinedAt'] ?? '').toString());
    final bottleBingoCompletedTiles =
        _safeBottleBingoCompletedTiles(value['bottleBingoCompletedTiles']);
    final parameters = value['parameters'] is Map
        ? Map<String, Object?>.from(value['parameters'] as Map)
        : const <String, Object?>{};
    final completedActionIds = value['completedActionIds'] is List
        ? (value['completedActionIds'] as List)
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toSet()
        : const <String>{};
    final lifecycleName = value['lifecycleStatus']?.toString();
    final lifecycleStatus = ChallengeLifecycleStatus.values.firstWhere(
      (status) => status.name == lifecycleName,
      orElse: () => ChallengeLifecycleStatus.active,
    );
    final pendingParameters = value['pendingParameters'] is Map
        ? Map<String, Object?>.from(value['pendingParameters'] as Map)
        : const <String, Object?>{};

    if (id.isEmpty ||
        name.isEmpty ||
        description.isEmpty ||
        targetMl is! num ||
        !targetMl.isFinite ||
        targetMl <= 0 ||
        durationDays is! num ||
        !durationDays.isFinite ||
        durationDays <= 0 ||
        joinedAt == null) {
      return null;
    }

    return JoinedChallenge(
      id: id,
      name: name,
      description: description,
      targetMl: targetMl.round(),
      durationDays: durationDays.round(),
      joinedAt: joinedAt,
      bottleBingoCompletedTiles: bottleBingoCompletedTiles,
      parameters: Map<String, Object?>.unmodifiable(parameters),
      completedActionIds: Set<String>.unmodifiable(completedActionIds),
      storedInstanceId: value['instanceId']?.toString(),
      lifecycleStatus: lifecycleStatus,
      endedAt: DateTime.tryParse((value['endedAt'] ?? '').toString()),
      pendingParameters: Map<String, Object?>.unmodifiable(pendingParameters),
      pendingParametersEffectiveDate: DateTime.tryParse(
        (value['pendingParametersEffectiveDate'] ?? '').toString(),
      ),
    );
  }

  static Set<int> _safeBottleBingoCompletedTiles(Object? value) {
    if (value is! List) {
      return const <int>{};
    }
    final tiles = <int>{};
    for (final item in value) {
      if (item is! num || !item.isFinite) {
        continue;
      }
      final index = item.round();
      if (index >= 0 && index < 25 && index != 12) {
        tiles.add(index);
      }
    }
    return Set<int>.unmodifiable(tiles);
  }
}

class ChallengeProgress {
  final int completedDays;
  final int durationDays;
  final int todayMl;
  final int targetMl;

  const ChallengeProgress({
    required this.completedDays,
    required this.durationDays,
    required this.todayMl,
    required this.targetMl,
  });

  double get percent =>
      durationDays <= 0 ? 0 : (completedDays / durationDays).clamp(0.0, 1.0);

  double get dailyHydrationPercent =>
      targetMl <= 0 ? 0 : (todayMl / targetMl).clamp(0.0, 1.0).toDouble();
}

class ChallengeRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.joined_challenge.v1';
  static const maxActiveChallenges = 2;
  static const bottleBingoHydrationTileIndexes = <int>{1, 4};
  static const _category = 'active_challenge';
  static const _currentSchemaVersion = 5;

  final HydrionLocalStore _store;
  final List<StorageRecoveryEvent> _recoveryEvents;
  List<JoinedChallenge> _activeChallenges;
  List<JoinedChallenge> _challengeHistory;
  final Set<String> _inFlightHydrationActions = <String>{};
  HydrationRepository? _boundHydrationRepository;
  Map<String, Set<String>> _qualifiedChallengeInstancesByLogId = const {};

  ChallengeRepository._(
    this._store,
    List<JoinedChallenge> activeChallenges, [
    List<JoinedChallenge> challengeHistory = const <JoinedChallenge>[],
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ])  : _activeChallenges = List<JoinedChallenge>.unmodifiable(
          activeChallenges.take(maxActiveChallenges),
        ),
        _challengeHistory = List<JoinedChallenge>.unmodifiable(
          challengeHistory,
        ),
        _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        );

  ChallengeRepository.memory() : this._(MemoryHydrionStore(), const []);

  static Future<ChallengeRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final result = _decodeChallenge(raw);
    if (result.shouldClearStorage) {
      await store.remove(storageKey);
    }
    return ChallengeRepository._(
      store,
      result.challenges,
      result.history,
      result.recoveryEvents,
    );
  }

  JoinedChallenge? get activeChallenge =>
      _activeChallenges.isEmpty ? null : _activeChallenges.first;

  List<JoinedChallenge> get activeChallenges => _activeChallenges;

  List<JoinedChallenge> get challengeHistory => _challengeHistory;

  List<JoinedChallenge> get pausedChallenges => _challengeHistory
      .where((challenge) =>
          challenge.lifecycleStatus == ChallengeLifecycleStatus.paused)
      .toList(growable: false);

  List<JoinedChallenge> get completedChallenges => _challengeHistory
      .where((challenge) =>
          challenge.lifecycleStatus == ChallengeLifecycleStatus.completed ||
          challenge.lifecycleStatus == ChallengeLifecycleStatus.archived)
      .toList(growable: false);

  bool get hasRoomForAnotherChallenge =>
      _activeChallenges.length < maxActiveChallenges;

  JoinedChallenge? activeChallengeFor(String challengeId) {
    for (final challenge in _activeChallenges) {
      if (challenge.id == challengeId) return challenge;
    }
    return null;
  }

  JoinedChallenge? challengeInstanceFor(String instanceId) {
    for (final challenge in [..._activeChallenges, ..._challengeHistory]) {
      if (challenge.instanceId == instanceId) return challenge;
    }
    return null;
  }

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  @override
  void dispose() {
    _boundHydrationRepository?.removeListener(_onHydrationChanged);
    super.dispose();
  }

  void bindHydrationRepository(HydrationRepository repository) {
    if (identical(_boundHydrationRepository, repository)) return;
    _boundHydrationRepository?.removeListener(_onHydrationChanged);
    _boundHydrationRepository = repository;
    repository.addListener(_onHydrationChanged);
    _recalculateHydrationQualifications(repository);
  }

  Set<String> qualificationsForLogId(String logId) =>
      _qualifiedChallengeInstancesByLogId[logId] ?? const <String>{};

  void _onHydrationChanged() {
    final repository = _boundHydrationRepository;
    if (repository == null) return;
    _recalculateHydrationQualifications(repository);
    notifyListeners();
  }

  void _recalculateHydrationQualifications(HydrationRepository repository) {
    _qualifiedChallengeInstancesByLogId =
        Map<String, Set<String>>.unmodifiable({
      for (final log in repository.logs)
        log.id: Set<String>.unmodifiable(
          qualifiedChallengeInstanceIdsForLog(log),
        ),
    });
  }

  Future<void> refreshFromStore() async {
    final raw = await _store.readString(storageKey);
    final result = _decodeChallenge(raw);
    _activeChallenges = result.challenges;
    _challengeHistory = result.history;
    notifyListeners();
  }

  bool isJoined(String challengeId) {
    return activeChallengeFor(challengeId) != null;
  }

  Future<bool> join({
    required String id,
    required String name,
    required String description,
    required int targetMl,
    required int durationDays,
    DateTime? joinedAt,
    Map<String, Object?> parameters = const <String, Object?>{},
  }) async {
    final startedAt = joinedAt ?? DateTime.now();
    final joined = JoinedChallenge(
      id: id,
      name: name,
      description: description,
      targetMl: targetMl,
      durationDays: durationDays,
      joinedAt: startedAt,
      parameters: Map<String, Object?>.unmodifiable(parameters),
      storedInstanceId: '$id-${startedAt.microsecondsSinceEpoch}',
    );
    final existingIndex =
        _activeChallenges.indexWhere((challenge) => challenge.id == id);
    if (existingIndex == -1 &&
        _activeChallenges.length >= maxActiveChallenges) {
      return false;
    }
    final next = <JoinedChallenge>[..._activeChallenges];
    if (existingIndex == -1) {
      next.add(joined);
    } else {
      next[existingIndex] = joined;
    }
    await _replaceActiveChallenges(next);
    return true;
  }

  Future<bool> pauseOrLeave(String challengeId) async {
    return (await pauseChallenge(challengeId)).changed;
  }

  Future<void> leaveChallenge(String challengeId) async {
    await leaveChallengeWithHistory(challengeId);
  }

  Future<void> leave() async {
    final leaving = List<JoinedChallenge>.of(_activeChallenges);
    for (final challenge in leaving) {
      await leaveChallengeWithHistory(challenge.id);
    }
  }

  Future<ChallengeLifecycleChange> pauseChallenge(
    String challengeId, {
    DateTime? pausedAt,
  }) {
    return _deactivateChallenge(
      challengeId,
      status: ChallengeLifecycleStatus.paused,
      endedAt: pausedAt ?? DateTime.now(),
    );
  }

  Future<ChallengeLifecycleChange> leaveChallengeWithHistory(
    String challengeId, {
    DateTime? leftAt,
  }) {
    return _deactivateChallenge(
      challengeId,
      status: ChallengeLifecycleStatus.left,
      endedAt: leftAt ?? DateTime.now(),
    );
  }

  Future<ChallengeLifecycleChange> completeChallenge(
    String challengeId, {
    DateTime? completedAt,
  }) {
    return _deactivateChallenge(
      challengeId,
      status: ChallengeLifecycleStatus.completed,
      endedAt: completedAt ?? DateTime.now(),
    );
  }

  Future<ChallengeLifecycleChange> _deactivateChallenge(
    String challengeId, {
    required ChallengeLifecycleStatus status,
    required DateTime endedAt,
  }) async {
    final challenge = activeChallengeFor(challengeId);
    if (challenge == null) {
      return const ChallengeLifecycleChange(changed: false);
    }
    final reminderIds = _reminderIdsFor(challenge);
    final stopped = challenge.copyWith(
      lifecycleStatus: status,
      endedAt: endedAt,
      parameters: _stoppedTimerParameters(challenge.parameters),
    );
    final previousActive = _activeChallenges;
    final previousHistory = _challengeHistory;
    _activeChallenges = List<JoinedChallenge>.unmodifiable(
      _activeChallenges
          .where((item) => item.instanceId != challenge.instanceId),
    );
    _challengeHistory = List<JoinedChallenge>.unmodifiable([
      stopped,
      ..._challengeHistory.where(
        (item) => item.instanceId != challenge.instanceId,
      ),
    ]);
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _activeChallenges = previousActive;
      _challengeHistory = previousHistory;
      rethrow;
    }
    notifyListeners();
    return ChallengeLifecycleChange(
      changed: true,
      challenge: stopped,
      obsoleteReminderIds: reminderIds,
    );
  }

  Future<ChallengeLifecycleChange> resumeChallenge(
    String challengeOrInstanceId, {
    DateTime? resumedAt,
  }) async {
    if (!hasRoomForAnotherChallenge) {
      return const ChallengeLifecycleChange(changed: false);
    }
    final index = _challengeHistory.indexWhere((challenge) =>
        challenge.lifecycleStatus == ChallengeLifecycleStatus.paused &&
        (challenge.id == challengeOrInstanceId ||
            challenge.instanceId == challengeOrInstanceId));
    if (index == -1) {
      return const ChallengeLifecycleChange(changed: false);
    }
    var challenge = _challengeHistory[index];
    if (activeChallengeFor(challenge.id) != null) {
      return const ChallengeLifecycleChange(changed: false);
    }
    challenge = _applyPendingParametersIfDue(
      challenge,
      resumedAt ?? DateTime.now(),
    ).copyWith(
      lifecycleStatus: ChallengeLifecycleStatus.active,
      clearEndedAt: true,
    );
    final previousActive = _activeChallenges;
    final previousHistory = _challengeHistory;
    _activeChallenges = List<JoinedChallenge>.unmodifiable([
      ..._activeChallenges,
      challenge,
    ]);
    _challengeHistory = List<JoinedChallenge>.unmodifiable([
      ..._challengeHistory.take(index),
      ..._challengeHistory.skip(index + 1),
    ]);
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _activeChallenges = previousActive;
      _challengeHistory = previousHistory;
      rethrow;
    }
    notifyListeners();
    return ChallengeLifecycleChange(changed: true, challenge: challenge);
  }

  Future<bool> archiveChallenge(String instanceId) async {
    final index = _challengeHistory
        .indexWhere((challenge) => challenge.instanceId == instanceId);
    if (index == -1) return false;
    final challenge = _challengeHistory[index];
    if (challenge.lifecycleStatus != ChallengeLifecycleStatus.completed &&
        challenge.lifecycleStatus != ChallengeLifecycleStatus.left) {
      return false;
    }
    final next = <JoinedChallenge>[..._challengeHistory];
    next[index] = challenge.copyWith(
      lifecycleStatus: ChallengeLifecycleStatus.archived,
    );
    final previous = _challengeHistory;
    _challengeHistory = List<JoinedChallenge>.unmodifiable(next);
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _challengeHistory = previous;
      rethrow;
    }
    notifyListeners();
    return true;
  }

  Future<bool> leavePausedChallenge(
    String instanceId, {
    DateTime? leftAt,
  }) async {
    final index = _challengeHistory.indexWhere((challenge) =>
        challenge.instanceId == instanceId &&
        challenge.lifecycleStatus == ChallengeLifecycleStatus.paused);
    if (index == -1) return false;
    final next = <JoinedChallenge>[..._challengeHistory];
    next[index] = next[index].copyWith(
      lifecycleStatus: ChallengeLifecycleStatus.left,
      endedAt: leftAt ?? DateTime.now(),
    );
    final previous = _challengeHistory;
    _challengeHistory = List<JoinedChallenge>.unmodifiable(next);
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _challengeHistory = previous;
      rethrow;
    }
    notifyListeners();
    return true;
  }

  Future<JoinedChallenge?> repeatChallenge(
    String challengeOrInstanceId, {
    DateTime? startedAt,
    Map<String, Object?>? parameterOverrides,
  }) async {
    JoinedChallenge? previous = activeChallengeFor(challengeOrInstanceId);
    if (previous == null) {
      for (final challenge in _activeChallenges) {
        if (challenge.instanceId == challengeOrInstanceId) {
          previous = challenge;
          break;
        }
      }
    }
    if (previous == null) {
      for (final challenge in _challengeHistory) {
        if (challenge.id == challengeOrInstanceId ||
            challenge.instanceId == challengeOrInstanceId) {
          previous = challenge;
          break;
        }
      }
    }
    if (previous == null) return null;
    final replacingActive = activeChallengeFor(previous.id) != null;
    if (!replacingActive && !hasRoomForAnotherChallenge) return null;
    if (replacingActive) {
      await completeChallenge(previous.id);
    }
    final start = startedAt ?? DateTime.now();
    final parameters = <String, Object?>{
      ...previous.parameters,
      ...?parameterOverrides,
    }..removeWhere((key, _) => key.startsWith('timer'));
    if (previous.id == 'bottle-bingo') {
      parameters['bingoBoardVersion'] = 2;
    }
    final repeated = JoinedChallenge(
      id: previous.id,
      name: previous.name,
      description: previous.description,
      targetMl: previous.targetMl,
      durationDays: ((parameterOverrides?['challengeDurationDays'] as num?) ??
              (parameterOverrides?['durationDays'] as num?) ??
              previous.durationDays)
          .round(),
      joinedAt: start,
      storedInstanceId: '${previous.id}-${start.microsecondsSinceEpoch}',
      parameters: Map<String, Object?>.unmodifiable(parameters),
    );
    await _replaceActiveChallenges([..._activeChallenges, repeated]);
    return repeated;
  }

  Future<void> updateParameters(
    Map<String, Object?> parameters, {
    String? challengeId,
  }) async {
    final challenge =
        challengeId == null ? activeChallenge : activeChallengeFor(challengeId);
    if (challenge == null) return;
    await _updateActiveChallenge(
      challenge.copyWith(
        parameters: Map<String, Object?>.unmodifiable(parameters),
      ),
    );
  }

  Future<ChallengeEditResult> editParameter({
    required String challengeId,
    required String key,
    required Object? value,
    DateTime? now,
    bool confirmRestart = false,
  }) async {
    final challenge = activeChallengeFor(challengeId);
    final effect = ChallengeEditPolicy.effectFor(key);
    if (challenge == null || !_isValidParameterValue(key, value)) {
      return ChallengeEditResult(
        changed: false,
        effect: effect,
        challenge: challenge,
        message: 'That change could not be saved.',
      );
    }
    switch (effect) {
      case ChallengeEditEffect.immediate:
        final updated = challenge.copyWith(
          parameters: Map<String, Object?>.unmodifiable({
            ...challenge.parameters,
            key: value,
          }),
        );
        await _updateActiveChallenge(updated);
        return ChallengeEditResult(
          changed: true,
          effect: effect,
          challenge: updated,
          message: 'Change applied.',
        );
      case ChallengeEditEffect.nextLocalDay:
        final localNow = now ?? DateTime.now();
        final effective = DateTime(
          localNow.year,
          localNow.month,
          localNow.day + 1,
        );
        final updated = challenge.copyWith(
          pendingParameters: Map<String, Object?>.unmodifiable({
            ...challenge.pendingParameters,
            key: value,
          }),
          pendingParametersEffectiveDate: effective,
        );
        await _updateActiveChallenge(updated);
        return ChallengeEditResult(
          changed: true,
          effect: effect,
          challenge: updated,
          message:
              'This change starts tomorrow. Today\u2019s progress will stay the same.',
        );
      case ChallengeEditEffect.restartRequired:
        if (!confirmRestart) {
          return ChallengeEditResult(
            changed: false,
            effect: effect,
            challenge: challenge,
            message:
                'Restarting creates a new challenge attempt. Your hydration history will remain, but this challenge\u2019s progress will begin again.',
          );
        }
        final repeated = await repeatChallenge(
          challenge.instanceId,
          startedAt: now,
          parameterOverrides: {key: value},
        );
        return ChallengeEditResult(
          changed: repeated != null,
          effect: effect,
          challenge: repeated,
          message: repeated == null
              ? 'The challenge could not be restarted.'
              : 'A new challenge attempt has started.',
        );
      case ChallengeEditEffect.notEditableWhileActive:
        return ChallengeEditResult(
          changed: false,
          effect: effect,
          challenge: challenge,
          message:
              'This setting cannot be changed while the challenge is active.',
        );
    }
  }

  Future<void> reconcileLocalDay([DateTime? now]) async {
    final localNow = now ?? DateTime.now();
    var changed = false;
    final nextActive = <JoinedChallenge>[];
    for (final challenge in _activeChallenges) {
      final next = _applyPendingParametersIfDue(challenge, localNow);
      changed = changed || !identical(next, challenge);
      nextActive.add(next);
    }
    final nextHistory = <JoinedChallenge>[];
    for (final challenge in _challengeHistory) {
      final next = _applyPendingParametersIfDue(challenge, localNow);
      changed = changed || !identical(next, challenge);
      nextHistory.add(next);
    }
    if (!changed) return;
    _activeChallenges = List<JoinedChallenge>.unmodifiable(nextActive);
    _challengeHistory = List<JoinedChallenge>.unmodifiable(nextHistory);
    await _persistActiveChallenges();
    notifyListeners();
  }

  Future<bool> completeCheckIn(String actionId, {String? challengeId}) async {
    final challenge =
        challengeId == null ? activeChallenge : activeChallengeFor(challengeId);
    if (challenge == null || actionId.trim().isEmpty) return false;
    if (challenge.completedActionIds.contains(actionId)) return false;
    await _updateActiveChallenge(
      challenge.copyWith(
        completedActionIds: Set<String>.unmodifiable({
          ...challenge.completedActionIds,
          actionId,
        }),
      ),
    );
    return true;
  }

  Future<HydrationLog?> completeHydrationAction({
    required HydrationRepository hydrationRepository,
    required int volumeMl,
    required String actionKey,
    DateTime? timestamp,
    String? challengeId,
    HydrationMetadata metadata = const HydrationMetadata(),
  }) async {
    final challenge =
        challengeId == null ? activeChallenge : activeChallengeFor(challengeId);
    if (challenge == null || challenge.needsSetup || volumeMl <= 0) return null;
    final time = timestamp ?? DateTime.now();
    final day = _localDayToken(time);
    final actionId = '${challenge.instanceId}:$day:$actionKey';
    if (!_inFlightHydrationActions.add(actionId)) return null;
    try {
      final log = await hydrationRepository.addLog(
        volumeMl: volumeMl,
        timestamp: time,
        source: 'challenge:${challenge.id}:$actionKey',
        actionId: actionId,
        metadata: metadata.copyWith(
          challengeActionSource: challenge.id,
        ),
      );
      if (log == null) return null;
      try {
        await _updateActiveChallenge(
          challenge.copyWith(
            completedActionIds: Set<String>.unmodifiable({
              ...challenge.completedActionIds,
              actionId,
            }),
          ),
        );
      } catch (_) {
        await hydrationRepository.deleteLog(log.id);
        rethrow;
      }
      return log;
    } finally {
      _inFlightHydrationActions.remove(actionId);
    }
  }

  Future<bool> toggleBottleBingoTile(int index) async {
    if (!_canPersistBottleBingoTile(index) ||
        bottleBingoHydrationTileIndexes.contains(index)) {
      return false;
    }
    final challenge = activeChallengeFor('bottle-bingo')!;
    final tiles = <int>{...challenge.bottleBingoCompletedTiles};
    if (!tiles.add(index)) {
      tiles.remove(index);
    }
    await _updateActiveChallenge(
      challenge.copyWith(
        bottleBingoCompletedTiles: Set<int>.unmodifiable(tiles),
      ),
    );
    return true;
  }

  Future<HydrationLog?> completeBottleBingoHydrationTile({
    required int index,
    required HydrationRepository hydrationRepository,
    required int volumeMl,
    DateTime? timestamp,
  }) async {
    if (!_canPersistBottleBingoTile(index) || volumeMl <= 0) {
      return null;
    }
    final challenge = activeChallengeFor('bottle-bingo')!;
    final actionTime = timestamp ?? DateTime.now();
    final localDay = '${actionTime.year.toString().padLeft(4, '0')}-'
        '${actionTime.month.toString().padLeft(2, '0')}-'
        '${actionTime.day.toString().padLeft(2, '0')}';
    final challengeInstance = challenge.joinedAt.microsecondsSinceEpoch;
    final actionId = '${challenge.id}:$challengeInstance:$localDay:tile-$index';
    if (!_inFlightHydrationActions.add(actionId)) {
      return null;
    }

    try {
      final log = await hydrationRepository.addLog(
        volumeMl: volumeMl,
        timestamp: actionTime,
        source: 'challenge:${challenge.id}:tile-$index',
        actionId: actionId,
        metadata: HydrationMetadata(
          challengeActionSource: challenge.id,
          bingoTileSource: 'legacy-tile-$index',
        ),
      );
      if (log == null) {
        return null;
      }

      try {
        await _updateActiveChallenge(
          challenge.copyWith(
            bottleBingoCompletedTiles: Set<int>.unmodifiable({
              ...challenge.bottleBingoCompletedTiles,
              index,
            }),
          ),
        );
      } catch (_) {
        await hydrationRepository.deleteLog(log.id);
        rethrow;
      }
      return log;
    } finally {
      _inFlightHydrationActions.remove(actionId);
    }
  }

  Future<bool> resetBottleBingoTiles() async {
    final challenge = activeChallengeFor('bottle-bingo');
    if (challenge == null) {
      return false;
    }
    final usesLiveBoard =
        (challenge.parameters['bingoBoardVersion'] as num?) == 2;
    final retainedLegacyHydrationTiles = usesLiveBoard
        ? const <int>{}
        : challenge.bottleBingoCompletedTiles
            .where(bottleBingoHydrationTileIndexes.contains)
            .toSet();
    await _updateActiveChallenge(
      challenge.copyWith(
        bottleBingoCompletedTiles:
            Set<int>.unmodifiable(retainedLegacyHydrationTiles),
      ),
    );
    return true;
  }

  bool isBottleBingoTileManuallyComplete(int index) {
    return activeChallengeFor('bottle-bingo')
            ?.bottleBingoCompletedTiles
            .contains(index) ==
        true;
  }

  bool isBottleBingoHydrationTileCompleteForDay(
    int index,
    HydrationRepository hydrationRepository,
    DateTime day,
  ) {
    final challenge = activeChallengeFor('bottle-bingo');
    if (challenge?.id != 'bottle-bingo' ||
        !bottleBingoHydrationTileIndexes.contains(index)) {
      return false;
    }
    final source = 'challenge:${challenge!.id}:tile-$index';
    return hydrationRepository.logs.any((log) =>
        log.source == source &&
        !log.timestamp.isBefore(challenge.joinedAt) &&
        log.timestamp.year == day.year &&
        log.timestamp.month == day.month &&
        log.timestamp.day == day.day);
  }

  bool _canPersistBottleBingoTile(int index) {
    return activeChallengeFor('bottle-bingo') != null &&
        index >= 0 &&
        index < 25 &&
        index != 12;
  }

  Future<void> _updateActiveChallenge(JoinedChallenge challenge) async {
    final previous = _activeChallenges;
    final index =
        _activeChallenges.indexWhere((item) => item.id == challenge.id);
    if (index == -1) return;
    final next = <JoinedChallenge>[..._activeChallenges];
    next[index] = challenge;
    _activeChallenges = List<JoinedChallenge>.unmodifiable(next);
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _activeChallenges = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _replaceActiveChallenges(
      List<JoinedChallenge> challenges) async {
    final previous = _activeChallenges;
    _activeChallenges = List<JoinedChallenge>.unmodifiable(
      challenges.take(maxActiveChallenges),
    );
    try {
      await _persistActiveChallenges();
    } catch (_) {
      _activeChallenges = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> clear() async {
    final previousActive = _activeChallenges;
    final previousHistory = _challengeHistory;
    _activeChallenges = const <JoinedChallenge>[];
    _challengeHistory = const <JoinedChallenge>[];
    try {
      await _store.remove(storageKey);
    } catch (_) {
      _activeChallenges = previousActive;
      _challengeHistory = previousHistory;
      rethrow;
    }
    final hydration = _boundHydrationRepository;
    if (hydration != null) {
      _recalculateHydrationQualifications(hydration);
    }
    notifyListeners();
  }

  Future<void> _persistActiveChallenges() async {
    if (_activeChallenges.isEmpty && _challengeHistory.isEmpty) {
      await _store.remove(storageKey);
      final hydration = _boundHydrationRepository;
      if (hydration != null) _recalculateHydrationQualifications(hydration);
      return;
    }
    await _store.writeString(
      storageKey,
      jsonEncode({
        'schemaVersion': _currentSchemaVersion,
        'activeChallenges': [
          for (final challenge in _activeChallenges) challenge.toJson(),
        ],
        'challengeHistory': [
          for (final challenge in _challengeHistory) challenge.toJson(),
        ],
      }),
    );
    final hydration = _boundHydrationRepository;
    if (hydration != null) _recalculateHydrationQualifications(hydration);
  }

  Map<String, Object?> _stoppedTimerParameters(
    Map<String, Object?> parameters,
  ) {
    final next = <String, Object?>{...parameters};
    final endsAt = DateTime.tryParse(next['timerEndsAt']?.toString() ?? '');
    if (next['timerStatus'] == 'running' && endsAt != null) {
      next['timerPausedSeconds'] =
          endsAt.difference(DateTime.now()).inSeconds.clamp(0, 86400);
    }
    next['timerStatus'] = 'paused';
    next['timerEndsAt'] = '';
    next['timerReminderId'] = '';
    return Map<String, Object?>.unmodifiable(next);
  }

  List<String> _reminderIdsFor(JoinedChallenge challenge) {
    return {
      for (final key in const [
        'timerReminderId',
        'challengeReminderId',
        'dailyReminderId',
      ])
        if ((challenge.parameters[key]?.toString().trim() ?? '').isNotEmpty)
          challenge.parameters[key]!.toString().trim(),
    }.toList(growable: false);
  }

  JoinedChallenge _applyPendingParametersIfDue(
    JoinedChallenge challenge,
    DateTime now,
  ) {
    final effective = challenge.pendingParametersEffectiveDate;
    if (effective == null ||
        challenge.pendingParameters.isEmpty ||
        DateTime(now.year, now.month, now.day).isBefore(
          DateTime(effective.year, effective.month, effective.day),
        )) {
      return challenge;
    }
    return challenge.copyWith(
      parameters: Map<String, Object?>.unmodifiable({
        ...challenge.parameters,
        ...challenge.pendingParameters,
      }),
      pendingParameters: const <String, Object?>{},
      clearPendingParametersEffectiveDate: true,
    );
  }

  bool _isValidParameterValue(String key, Object? value) {
    if (value == null) return false;
    if (const {
      'amountMl',
      'sessionMinutes',
      'sessionsPerDay',
      'challengeDurationDays',
      'durationDays',
      'cutoffHour',
    }.contains(key)) {
      return value is num && value.isFinite && value > 0;
    }
    return value.toString().trim().isNotEmpty;
  }

  ChallengeProgress progressFor(
    HydrationRepository hydrationRepository, {
    int? targetMlOverride,
    String? challengeId,
    DateTime? now,
  }) {
    final challenge =
        challengeId == null ? activeChallenge : activeChallengeFor(challengeId);
    if (challenge == null) {
      return const ChallengeProgress(
        completedDays: 0,
        durationDays: 0,
        todayMl: 0,
        targetMl: 0,
      );
    }

    final today = now ?? DateTime.now();
    final catalogChallenge = HydrionChallengeCatalog.byId(challenge.id);
    final objectiveType = catalogChallenge.objectiveType;
    final mainGoalMl = targetMlOverride ?? challenge.targetMl;
    final targetMl = mainGoalMl;
    final todayMl = _qualifiedValueForChallenge(
      challenge,
      hydrationRepository,
      today,
      objectiveType,
    );
    var completedDays = 0;

    for (var offset = 0; offset < challenge.durationDays; offset += 1) {
      final day = DateTime(
        challenge.joinedAt.year,
        challenge.joinedAt.month,
        challenge.joinedAt.day + offset,
      );
      if (day.isAfter(today)) {
        break;
      }
      if (_objectiveCompleteForDay(
        challenge,
        hydrationRepository,
        day,
        objectiveType,
        targetMl,
      )) {
        completedDays += 1;
      }
    }

    return ChallengeProgress(
      completedDays: completedDays,
      durationDays: challenge.durationDays,
      todayMl: todayMl,
      targetMl: targetMl,
    );
  }

  bool _objectiveCompleteForDay(
    JoinedChallenge challenge,
    HydrationRepository hydrationRepository,
    DateTime day,
    ChallengeObjectiveType objectiveType,
    int targetMl,
  ) {
    if (_usesChallengeHydrationEvidence(challenge.id)) {
      final requiredActions = challenge.id == 'pomodoro-sip'
          ? ((challenge.parameters['sessionsPerDay'] as num?) ?? 1).round()
          : 1;
      if (challenge.id == 'pomodoro-sip') {
        return _pomodoroEvidenceForDay(
              challenge,
              hydrationRepository,
              day,
            ) >=
            requiredActions;
      }
      return _qualifiedHydrationLogsForDay(
            challenge,
            hydrationRepository,
            day,
          ).length >=
          requiredActions;
    }
    if (objectiveType == ChallengeObjectiveType.manualCheckIn) {
      final dayToken = _localDayToken(day);
      return challenge.completedActionIds.any(
        (action) =>
            action.contains(':$dayToken:') || action.startsWith('$dayToken:'),
      );
    }
    return switch (objectiveType) {
      ChallengeObjectiveType.dailyGoalFromLogs => _qualifiedValueForChallenge(
            challenge,
            hydrationRepository,
            day,
            objectiveType,
          ) >=
          targetMl,
      ChallengeObjectiveType.loggedWaterBeforeLunch =>
        _qualifiedValueForChallenge(
              challenge,
              hydrationRepository,
              day,
              objectiveType,
            ) >
            0,
      ChallengeObjectiveType.manualCheckIn => false,
    };
  }

  int _qualifiedValueForChallenge(
    JoinedChallenge challenge,
    HydrationRepository hydrationRepository,
    DateTime day,
    ChallengeObjectiveType objectiveType,
  ) {
    if (_usesChallengeHydrationEvidence(challenge.id)) {
      return _qualifiedHydrationLogsForDay(
        challenge,
        hydrationRepository,
        day,
      ).fold(0, (total, log) => total + log.volumeMl);
    }
    return switch (objectiveType) {
      ChallengeObjectiveType.loggedWaterBeforeLunch => _waterBeforeCutoffMl(
          hydrationRepository,
          day,
          ((challenge.parameters['cutoffHour'] as num?) ?? 12).round(),
        ),
      ChallengeObjectiveType.dailyGoalFromLogs =>
        hydrationRepository.totalForDay(day),
      ChallengeObjectiveType.manualCheckIn => 0,
    };
  }

  bool _usesChallengeHydrationEvidence(String challengeId) => const {
        'around-the-world-infusion-week',
        'temperature-roulette',
        'pomodoro-sip',
      }.contains(challengeId);

  List<HydrationLog> _qualifiedHydrationLogsForDay(
    JoinedChallenge challenge,
    HydrationRepository hydrationRepository,
    DateTime day,
  ) {
    return hydrationRepository.logs
        .where((log) =>
            !log.timestamp.isBefore(challenge.joinedAt) &&
            log.timestamp.year == day.year &&
            log.timestamp.month == day.month &&
            log.timestamp.day == day.day &&
            hydrationLogQualifies(challenge, log))
        .toList(growable: false);
  }

  bool hydrationLogQualifies(JoinedChallenge challenge, HydrationLog log) {
    if (log.timestamp.isBefore(challenge.joinedAt)) return false;
    final metadata = log.metadata;
    switch (challenge.id) {
      case 'temperature-roulette':
        final assigned = _temperatureForDay(challenge, log.timestamp);
        return _sameFriendlyValue(metadata.temperatureStyle, assigned) ||
            _legacyChallengeSource(log, challenge.id);
      case 'around-the-world-infusion-week':
        final theme = _infusionThemeForDay(challenge, log.timestamp);
        return metadata.noAddedSugar == true &&
                _sameFriendlyValue(metadata.infusionTheme, theme) ||
            _legacyChallengeSource(log, challenge.id);
      case 'pomodoro-sip':
        return metadata.challengeActionSource == challenge.id ||
            _legacyChallengeSource(log, challenge.id);
      default:
        return false;
    }
  }

  Set<String> qualifiedChallengeInstanceIdsForLog(HydrationLog log) {
    return {
      for (final challenge in _activeChallenges)
        if (hydrationLogQualifies(challenge, log)) challenge.instanceId,
    };
  }

  Set<int> bottleBingoCompletedIndexes(
    HydrationRepository hydrationRepository, {
    JoinedChallenge? challenge,
    DateTime? now,
    int? dailyGoalMl,
  }) {
    final bingo = challenge ?? activeChallengeFor('bottle-bingo');
    if (bingo == null || bingo.id != 'bottle-bingo') return const <int>{};
    final today = now ?? DateTime.now();
    final logs = hydrationRepository.logs
        .where((log) =>
            !log.timestamp.isBefore(bingo.joinedAt) &&
            log.timestamp.year == today.year &&
            log.timestamp.month == today.month &&
            log.timestamp.day == today.day)
        .toList(growable: false);
    final total = logs.fold<int>(0, (sum, log) => sum + log.volumeMl);
    final board = BottleBingoBoard.forInstance(
      bingo.joinedAt.microsecondsSinceEpoch,
    );
    final complete = <int>{BottleBingoBoard.centerIndex};
    for (var index = 0; index < board.tiles.length; index++) {
      final tile = board.tiles[index];
      final done = switch (tile.kind) {
        BingoTileKind.free => true,
        BingoTileKind.checkIn =>
          bingo.bottleBingoCompletedTiles.contains(index),
        BingoTileKind.hydrationAction => logs.any(
            (log) => log.metadata.bingoTileSource == tile.id,
          ),
        BingoTileKind.automatic => tile.goalFraction != null
            ? total >=
                ((dailyGoalMl ?? bingo.targetMl) * tile.goalFraction!).round()
            : tile.logCount != null
                ? logs.length >= tile.logCount!
                : tile.id == 'afternoon-water'
                    ? logs.any((log) =>
                        log.timestamp.hour >= 12 && log.timestamp.hour < 17)
                    : logs.any((log) =>
                        log.timestamp.hour <
                        ((bingo.parameters['cutoffHour'] as num?) ?? 12)
                            .round()),
      };
      if (done) complete.add(index);
    }
    return Set<int>.unmodifiable(complete);
  }

  bool isChallengeComplete(
    String challengeId,
    HydrationRepository hydrationRepository, {
    DateTime? now,
    int? dailyGoalMl,
  }) {
    final challenge = activeChallengeFor(challengeId);
    if (challenge == null) return false;
    if (challenge.id == 'bottle-bingo') {
      final board = BottleBingoBoard.forInstance(
        challenge.joinedAt.microsecondsSinceEpoch,
      );
      return board
          .completedLines(
            bottleBingoCompletedIndexes(
              hydrationRepository,
              challenge: challenge,
              now: now,
              dailyGoalMl: dailyGoalMl,
            ),
          )
          .isNotEmpty;
    }
    final progress = progressFor(
      hydrationRepository,
      challengeId: challengeId,
      targetMlOverride: dailyGoalMl,
      now: now,
    );
    return progress.durationDays > 0 &&
        progress.completedDays >= progress.durationDays;
  }

  String? _temperatureForDay(JoinedChallenge challenge, DateTime day) {
    final stored = challenge.parameters['temperatureSchedule'];
    final schedule = stored is List && stored.isNotEmpty
        ? stored.map((item) => item.toString()).toList(growable: false)
        : HydrionChallengeExperiences.byId(challenge.id).schedule;
    if (schedule.isEmpty) return null;
    final offset = DateTime(day.year, day.month, day.day)
        .difference(DateTime(
          challenge.joinedAt.year,
          challenge.joinedAt.month,
          challenge.joinedAt.day,
        ))
        .inDays;
    if (offset < 0) return null;
    return schedule[offset % schedule.length];
  }

  String? temperatureForDay(String challengeId, DateTime day) {
    final challenge = activeChallengeFor(challengeId);
    return challenge == null ? null : _temperatureForDay(challenge, day);
  }

  String? _infusionThemeForDay(JoinedChallenge challenge, DateTime day) {
    final stored = challenge.parameters['infusionThemeSchedule'];
    final schedule = stored is List && stored.isNotEmpty
        ? stored.map((item) => item.toString()).toList(growable: false)
        : HydrionChallengeExperiences.byId(challenge.id).schedule;
    if (schedule.isEmpty) return null;
    final offset = DateTime(day.year, day.month, day.day)
        .difference(DateTime(
          challenge.joinedAt.year,
          challenge.joinedAt.month,
          challenge.joinedAt.day,
        ))
        .inDays;
    if (offset < 0) return null;
    return schedule[offset % schedule.length];
  }

  String? infusionThemeForDay(String challengeId, DateTime day) {
    final challenge = activeChallengeFor(challengeId);
    return challenge == null ? null : _infusionThemeForDay(challenge, day);
  }

  bool _sameFriendlyValue(String? left, String? right) =>
      left != null &&
      right != null &&
      left.trim().toLowerCase() == right.trim().toLowerCase();

  bool _legacyChallengeSource(HydrationLog log, String challengeId) =>
      log.source.startsWith('challenge:$challengeId:');

  int _pomodoroEvidenceForDay(
    JoinedChallenge challenge,
    HydrationRepository hydrationRepository,
    DateTime day,
  ) {
    final dayToken = _localDayToken(day);
    final checkIns = challenge.completedActionIds.where(
      (action) =>
          action.contains(':$dayToken:') || action.startsWith('$dayToken:'),
    );
    return checkIns.length +
        _qualifiedHydrationLogsForDay(
          challenge,
          hydrationRepository,
          day,
        ).length;
  }

  String _localDayToken(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  int _waterBeforeCutoffMl(
    HydrationRepository hydrationRepository,
    DateTime day,
    int cutoffHour,
  ) {
    final start = DateTime(day.year, day.month, day.day);
    final lunch = DateTime(day.year, day.month, day.day, cutoffHour);
    return hydrationRepository.totalBetween(start, lunch);
  }

  static _ChallengeDecodeResult _decodeChallenge(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const _ChallengeDecodeResult();
    }

    try {
      final decoded = jsonDecode(raw);
      final schemaVersion = storageSchemaVersion(decoded);
      if (schemaVersion != null && schemaVersion > _currentSchemaVersion) {
        return _ChallengeDecodeResult(
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
      if (decoded is! Map) {
        return const _ChallengeDecodeResult(
          shouldClearStorage: true,
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.wrongTopLevelType,
              action: StorageRecoveryActions.clearCategory,
            ),
          ],
        );
      }
      final challenges = _activeChallengesFrom(decoded);
      if (challenges == null) {
        return const _ChallengeDecodeResult(
          shouldClearStorage: true,
          recoveryEvents: <StorageRecoveryEvent>[
            StorageRecoveryEvent(
              category: _category,
              code: StorageRecoveryCodes.invalidValue,
              action: StorageRecoveryActions.clearCategory,
            ),
          ],
        );
      }
      final eligible = challenges
          .where((challenge) => challenge.id != 'front-loader-challenge')
          .where((challenge) =>
              challenge.lifecycleStatus == ChallengeLifecycleStatus.active)
          .toList(growable: false);
      final filtered =
          eligible.take(maxActiveChallenges).toList(growable: false);
      final overflow = eligible
          .skip(maxActiveChallenges)
          .map((challenge) => challenge.copyWith(
                lifecycleStatus: ChallengeLifecycleStatus.paused,
                endedAt: challenge.joinedAt,
              ))
          .toList(growable: false);
      final history = [
        ...overflow,
        ..._challengeHistoryFrom(decoded),
      ]
          .where((challenge) => challenge.id != 'front-loader-challenge')
          .where((challenge) =>
              challenge.lifecycleStatus != ChallengeLifecycleStatus.active)
          .toList(growable: false);
      if (filtered.isEmpty && history.isEmpty) {
        return const _ChallengeDecodeResult(shouldClearStorage: true);
      }
      if (filtered.length != challenges.length) {
        return _ChallengeDecodeResult(challenges: filtered, history: history);
      }
      return _ChallengeDecodeResult(challenges: filtered, history: history);
    } on FormatException {
      return const _ChallengeDecodeResult(
        shouldClearStorage: true,
        recoveryEvents: <StorageRecoveryEvent>[
          StorageRecoveryEvent(
            category: _category,
            code: StorageRecoveryCodes.malformedJson,
            action: StorageRecoveryActions.clearCategory,
            errorType: 'FormatException',
          ),
        ],
      );
    }
  }

  static List<JoinedChallenge>? _activeChallengesFrom(Map decoded) {
    final rawChallenges = decoded['activeChallenges'];
    if (rawChallenges is List) {
      final challenges = rawChallenges
          .map(JoinedChallenge.fromJson)
          .whereType<JoinedChallenge>()
          .toList(growable: false);
      if (challenges.isEmpty && rawChallenges.isNotEmpty) return null;
      return challenges;
    }
    final legacy = JoinedChallenge.fromJson(decoded);
    return legacy == null ? null : <JoinedChallenge>[legacy];
  }

  static List<JoinedChallenge> _challengeHistoryFrom(Map decoded) {
    final rawHistory = decoded['challengeHistory'];
    if (rawHistory is! List) return const <JoinedChallenge>[];
    return rawHistory
        .map(JoinedChallenge.fromJson)
        .whereType<JoinedChallenge>()
        .toList(growable: false);
  }
}

class _ChallengeDecodeResult {
  final List<JoinedChallenge> challenges;
  final List<JoinedChallenge> history;
  final bool shouldClearStorage;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _ChallengeDecodeResult({
    this.challenges = const <JoinedChallenge>[],
    this.history = const <JoinedChallenge>[],
    this.shouldClearStorage = false,
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
