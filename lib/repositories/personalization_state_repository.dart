import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/hydration_recommendation.dart';
import '../storage/local_store.dart';

class PersonalizationStateRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.personalization_state.v1';
  static const schemaVersion = 1;

  final HydrionLocalStore _store;
  String? _lastInputFingerprint;
  HydrationRecommendation? _latestRecommendation;
  Map<String, Set<String>> _dismissedChallengesByDate;

  PersonalizationStateRepository._(
    this._store,
    this._lastInputFingerprint,
    this._dismissedChallengesByDate,
  );

  PersonalizationStateRepository.memory()
      : this._(MemoryHydrionStore(), null, {});

  static Future<PersonalizationStateRepository> load(
    HydrionLocalStore store,
  ) async {
    final raw = await store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return PersonalizationStateRepository._(store, null, {});
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return PersonalizationStateRepository._(store, null, {});
      }
      final rawDismissals = decoded['dismissedChallengesByDate'];
      final dismissals = <String, Set<String>>{};
      if (rawDismissals is Map) {
        for (final entry in rawDismissals.entries) {
          final key = entry.key.toString();
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) ||
              entry.value is! List) {
            continue;
          }
          dismissals[key] = (entry.value as List)
              .map((item) => item.toString())
              .where((item) => item.isNotEmpty)
              .toSet();
        }
      }
      return PersonalizationStateRepository._(
        store,
        decoded['lastInputFingerprint']?.toString(),
        dismissals,
      );
    } on FormatException {
      return PersonalizationStateRepository._(store, null, {});
    }
  }

  HydrationRecommendation? get latestRecommendation => _latestRecommendation;
  String? get lastInputFingerprint => _lastInputFingerprint;

  Set<String> dismissedForDate(String localDateKey) =>
      Set.unmodifiable(_dismissedChallengesByDate[localDateKey] ?? const {});

  Future<void> recordRecommendation({
    required String inputFingerprint,
    required HydrationRecommendation recommendation,
  }) async {
    if (_lastInputFingerprint == inputFingerprint &&
        _latestRecommendation?.roundedRecommendedGoalMl ==
            recommendation.roundedRecommendedGoalMl) {
      return;
    }
    _lastInputFingerprint = inputFingerprint;
    _latestRecommendation = recommendation;
    await _persist();
    notifyListeners();
  }

  Future<void> dismissChallenge({
    required String localDateKey,
    required String challengeId,
  }) async {
    final next = {
      for (final entry in _dismissedChallengesByDate.entries)
        entry.key: Set<String>.from(entry.value),
    };
    next.putIfAbsent(localDateKey, () => <String>{}).add(challengeId);
    final ordered = next.keys.toList()..sort((a, b) => b.compareTo(a));
    _dismissedChallengesByDate = {
      for (final key in ordered.take(14)) key: next[key]!,
    };
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _lastInputFingerprint = null;
    _latestRecommendation = null;
    _dismissedChallengesByDate = {};
    await _store.remove(storageKey);
    notifyListeners();
  }

  Future<void> _persist() => _store.writeString(
        storageKey,
        jsonEncode({
          'schemaVersion': schemaVersion,
          'lastInputFingerprint': _lastInputFingerprint,
          'dismissedChallengesByDate': {
            for (final entry in _dismissedChallengesByDate.entries)
              entry.key: entry.value.toList()..sort(),
          },
        }),
      );
}
