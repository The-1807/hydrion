import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/challenge_catalog.dart';
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

  const JoinedChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
    required this.joinedAt,
    this.bottleBingoCompletedTiles = const <int>{},
  });

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
    };
  }

  JoinedChallenge copyWith({
    Set<int>? bottleBingoCompletedTiles,
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
      if (index >= 1 && index <= 5) {
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
}

class ChallengeRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.joined_challenge.v1';
  static const bottleBingoHydrationTileIndexes = <int>{1, 4};
  static const _category = 'active_challenge';
  static const _currentSchemaVersion = 2;

  final HydrionLocalStore _store;
  final List<StorageRecoveryEvent> _recoveryEvents;
  JoinedChallenge? _activeChallenge;
  final Set<String> _inFlightHydrationActions = <String>{};

  ChallengeRepository._(
    this._store,
    this._activeChallenge, [
    List<StorageRecoveryEvent> recoveryEvents = const <StorageRecoveryEvent>[],
  ]) : _recoveryEvents = List<StorageRecoveryEvent>.unmodifiable(
          recoveryEvents,
        );

  ChallengeRepository.memory() : this._(MemoryHydrionStore(), null);

  static Future<ChallengeRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    final result = _decodeChallenge(raw);
    if (result.shouldClearStorage) {
      await store.remove(storageKey);
    }
    return ChallengeRepository._(
      store,
      result.challenge,
      result.recoveryEvents,
    );
  }

  JoinedChallenge? get activeChallenge => _activeChallenge;

  List<StorageRecoveryEvent> get recoveryEvents => _recoveryEvents;

  bool isJoined(String challengeId) {
    return _activeChallenge?.id == challengeId;
  }

  Future<void> join({
    required String id,
    required String name,
    required String description,
    required int targetMl,
    required int durationDays,
    DateTime? joinedAt,
  }) async {
    _activeChallenge = JoinedChallenge(
      id: id,
      name: name,
      description: description,
      targetMl: targetMl,
      durationDays: durationDays,
      joinedAt: joinedAt ?? DateTime.now(),
    );
    await _store.writeString(
        storageKey, jsonEncode(_activeChallenge!.toJson()));
    notifyListeners();
  }

  Future<void> leave() async {
    _activeChallenge = null;
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<bool> toggleBottleBingoTile(int index) async {
    if (!_canPersistBottleBingoTile(index) ||
        bottleBingoHydrationTileIndexes.contains(index)) {
      return false;
    }
    final tiles = <int>{..._activeChallenge!.bottleBingoCompletedTiles};
    if (!tiles.add(index)) {
      tiles.remove(index);
    }
    await _updateActiveChallenge(
      _activeChallenge!.copyWith(
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
    final challenge = _activeChallenge!;
    if (challenge.bottleBingoCompletedTiles.contains(index)) {
      return null;
    }

    final actionId = '${challenge.id}:tile-$index';
    if (!_inFlightHydrationActions.add(actionId)) {
      return null;
    }

    try {
      final log = await hydrationRepository.addLog(
        volumeMl: volumeMl,
        timestamp: timestamp ?? DateTime.now(),
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
    if (_activeChallenge?.id != 'bottle-bingo') {
      return false;
    }
    final retainedHydrationTiles = _activeChallenge!.bottleBingoCompletedTiles
        .where(bottleBingoHydrationTileIndexes.contains)
        .toSet();
    await _updateActiveChallenge(
      _activeChallenge!.copyWith(
        bottleBingoCompletedTiles: Set<int>.unmodifiable(
          retainedHydrationTiles,
        ),
      ),
    );
    return true;
  }

  bool isBottleBingoTileManuallyComplete(int index) {
    return _activeChallenge?.bottleBingoCompletedTiles.contains(index) == true;
  }

  bool _canPersistBottleBingoTile(int index) {
    return _activeChallenge?.id == 'bottle-bingo' && index >= 1 && index <= 5;
  }

  Future<void> _updateActiveChallenge(JoinedChallenge challenge) async {
    final previous = _activeChallenge;
    _activeChallenge = challenge;
    try {
      await _store.writeString(storageKey, jsonEncode(challenge.toJson()));
    } catch (_) {
      _activeChallenge = previous;
      rethrow;
    }
    notifyListeners();
  }

  ChallengeProgress progressFor(
    HydrationRepository hydrationRepository, {
    int? targetMlOverride,
  }) {
    final challenge = _activeChallenge;
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
    final todayMl = _objectiveTodayValue(
      hydrationRepository,
      today,
      objectiveType,
    );
    final targetMl = targetMlOverride ?? challenge.targetMl;
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
    HydrationRepository hydrationRepository,
    DateTime day,
    ChallengeObjectiveType objectiveType,
    int targetMl,
  ) {
    return switch (objectiveType) {
      ChallengeObjectiveType.dailyGoalFromLogs =>
        hydrationRepository.totalForDay(day) >= targetMl,
      ChallengeObjectiveType.loggedWaterBeforeLunch =>
        _waterBeforeLunchMl(hydrationRepository, day) > 0,
      ChallengeObjectiveType.manualCheckIn => false,
    };
  }

  int _objectiveTodayValue(
    HydrationRepository hydrationRepository,
    DateTime day,
    ChallengeObjectiveType objectiveType,
  ) {
    return switch (objectiveType) {
      ChallengeObjectiveType.loggedWaterBeforeLunch =>
        _waterBeforeLunchMl(hydrationRepository, day),
      ChallengeObjectiveType.dailyGoalFromLogs ||
      ChallengeObjectiveType.manualCheckIn =>
        hydrationRepository.totalForDay(day),
    };
  }

  int _waterBeforeLunchMl(
    HydrationRepository hydrationRepository,
    DateTime day,
  ) {
    final start = DateTime(day.year, day.month, day.day);
    final lunch = DateTime(day.year, day.month, day.day, 12);
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
      final challenge = JoinedChallenge.fromJson(decoded);
      if (challenge == null) {
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
      return _ChallengeDecodeResult(challenge: challenge);
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
}

class _ChallengeDecodeResult {
  final JoinedChallenge? challenge;
  final bool shouldClearStorage;
  final List<StorageRecoveryEvent> recoveryEvents;

  const _ChallengeDecodeResult({
    this.challenge,
    this.shouldClearStorage = false,
    this.recoveryEvents = const <StorageRecoveryEvent>[],
  });
}
