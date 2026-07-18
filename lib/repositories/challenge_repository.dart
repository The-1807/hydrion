import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/challenge_catalog.dart';
import '../domain/challenge_experience.dart';
import '../domain/hydration_contracts.dart';
import '../storage/local_store.dart';
import 'hydration_repository.dart';
import 'storage_recovery.dart';

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
  });

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
    };
  }

  JoinedChallenge copyWith({
    Set<int>? bottleBingoCompletedTiles,
    Map<String, Object?>? parameters,
    Set<String>? completedActionIds,
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
  static const _currentSchemaVersion = 4;

  final HydrionLocalStore _store;
  final List<StorageRecoveryEvent> _recoveryEvents;
  List<JoinedChallenge> _activeChallenges;
  final Set<String> _inFlightHydrationActions = <String>{};

  ChallengeRepository._(
    this._store,
    List<JoinedChallenge> activeChallenges, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ])  : _activeChallenges = List<JoinedChallenge>.unmodifiable(
          activeChallenges.take(maxActiveChallenges),
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
      result.recoveryEvents,
    );
  }

  JoinedChallenge? get activeChallenge =>
      _activeChallenges.isEmpty ? null : _activeChallenges.first;

  List<JoinedChallenge> get activeChallenges => _activeChallenges;

  bool get hasRoomForAnotherChallenge =>
      _activeChallenges.length < maxActiveChallenges;

  JoinedChallenge? activeChallengeFor(String challengeId) {
    for (final challenge in _activeChallenges) {
      if (challenge.id == challengeId) return challenge;
    }
    return null;
  }

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  Future<void> refreshFromStore() async {
    final raw = await _store.readString(storageKey);
    _activeChallenges = _decodeChallenge(raw).challenges;
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
    final joined = JoinedChallenge(
      id: id,
      name: name,
      description: description,
      targetMl: targetMl,
      durationDays: durationDays,
      joinedAt: joinedAt ?? DateTime.now(),
      parameters: Map<String, Object?>.unmodifiable(parameters),
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
    final next = _activeChallenges
        .where((challenge) => challenge.id != challengeId)
        .toList(growable: false);
    if (next.length == _activeChallenges.length) return false;
    await _replaceActiveChallenges(next);
    return true;
  }

  Future<void> leaveChallenge(String challengeId) async {
    await pauseOrLeave(challengeId);
  }

  Future<void> leave() async {
    _activeChallenges = const [];
    await _store.remove(storageKey);
    notifyListeners();
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
  }) async {
    final challenge =
        challengeId == null ? activeChallenge : activeChallengeFor(challengeId);
    if (challenge == null || challenge.needsSetup || volumeMl <= 0) return null;
    final time = timestamp ?? DateTime.now();
    final day = '${time.year}-${time.month}-${time.day}';
    final instance = challenge.joinedAt.microsecondsSinceEpoch;
    final actionId = '${challenge.id}:$instance:$day:$actionKey';
    if (!_inFlightHydrationActions.add(actionId)) return null;
    try {
      final log = await hydrationRepository.addLog(
        volumeMl: volumeMl,
        timestamp: time,
        source: 'challenge:${challenge.id}:$actionKey',
        actionId: actionId,
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

  Future<void> _persistActiveChallenges() async {
    if (_activeChallenges.isEmpty) {
      await _store.remove(storageKey);
      return;
    }
    await _store.writeString(
      storageKey,
      jsonEncode({
        'schemaVersion': _currentSchemaVersion,
        'activeChallenges': [
          for (final challenge in _activeChallenges) challenge.toJson(),
        ],
      }),
    );
  }

  ChallengeProgress progressFor(
    HydrationRepository hydrationRepository, {
    int? targetMlOverride,
    String? challengeId,
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

    final today = DateTime.now();
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
      return _challengeHydrationLogsForDay(
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
      return _challengeHydrationLogsForDay(
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
      ChallengeObjectiveType.dailyGoalFromLogs ||
      ChallengeObjectiveType.manualCheckIn =>
        hydrationRepository.totalForDay(day),
    };
  }

  bool _usesChallengeHydrationEvidence(String challengeId) => const {
        'around-the-world-infusion-week',
        'temperature-roulette',
        'pomodoro-sip',
      }.contains(challengeId);

  List<HydrationLog> _challengeHydrationLogsForDay(
    JoinedChallenge challenge,
    HydrationRepository hydrationRepository,
    DateTime day,
  ) {
    final sourcePrefix = 'challenge:${challenge.id}:';
    return hydrationRepository.logs
        .where((log) =>
            log.source.startsWith(sourcePrefix) &&
            !log.timestamp.isBefore(challenge.joinedAt) &&
            log.timestamp.year == day.year &&
            log.timestamp.month == day.month &&
            log.timestamp.day == day.day)
        .toList(growable: false);
  }

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
        _challengeHydrationLogsForDay(
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
      final filtered = challenges
          .where((challenge) => challenge.id != 'front-loader-challenge')
          .take(maxActiveChallenges)
          .toList(growable: false);
      if (filtered.isEmpty) {
        return const _ChallengeDecodeResult(shouldClearStorage: true);
      }
      if (filtered.length != challenges.length) {
        return _ChallengeDecodeResult(challenges: filtered);
      }
      return _ChallengeDecodeResult(challenges: filtered);
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
}

class _ChallengeDecodeResult {
  final List<JoinedChallenge> challenges;
  final bool shouldClearStorage;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _ChallengeDecodeResult({
    this.challenges = const <JoinedChallenge>[],
    this.shouldClearStorage = false,
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
