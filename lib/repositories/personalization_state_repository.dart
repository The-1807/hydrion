import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../domain/hydration_recommendation.dart';
import '../domain/challenge_recommendation.dart';
import '../services/recommendation_input_token.dart';
import '../storage/local_store.dart';

class PersonalizationPersistenceIncomplete implements Exception {
  const PersonalizationPersistenceIncomplete();
  @override
  String toString() => 'PersonalizationPersistenceIncomplete';
}

class PersonalizationStateRepository extends ChangeNotifier {
  static const storageKey = 'hydrion.personalization_state.v1';
  static const schemaVersion = 3;

  final HydrionLocalStore _store;
  final RecommendationInputTokens _tokens;
  String? _lastInputFingerprint;
  HydrationRecommendation? _latestRecommendation;
  Map<String, Set<String>> _dismissedChallengesByDate = {};
  ChallengeRecommendationPreferences _challengePreferences =
      const ChallengeRecommendationPreferences();
  Map<String, String> _reviewedRecommendationsByDate = {};
  Future<void> _tail = Future.value();
  int _generation = 0;
  bool _resetPending = false;

  PersonalizationStateRepository._(this._store, this._tokens);

  PersonalizationStateRepository.memory()
      : this._(MemoryHydrionStore(), RecommendationInputTokens.memory());

  static Future<PersonalizationStateRepository> load(
    HydrionLocalStore store, {
    RecommendationInputTokens? tokens,
  }) async {
    final repository = PersonalizationStateRepository._(
        store, tokens ?? RecommendationInputTokens());
    final raw = await store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) return repository;
    Map decoded;
    try {
      final value = jsonDecode(raw);
      decoded = value is Map ? value : {};
    } on FormatException {
      decoded = {};
    }
    final rawDismissals = decoded['dismissedChallengesByDate'];
    if (rawDismissals is Map) {
      for (final entry in rawDismissals.entries) {
        final key = entry.key.toString();
        if (!_validDate(key) || entry.value is! List) continue;
        repository._dismissedChallengesByDate[key] = (entry.value as List)
            .whereType<String>()
            .where((item) => item.isNotEmpty)
            .toSet();
      }
    }
    repository._challengePreferences =
        ChallengeRecommendationPreferences.fromJson(
            decoded['challengePreferences']);
    final mayRestore = decoded['schemaVersion'] == schemaVersion &&
        await repository._tokens.canPersist();
    if (mayRestore) {
      final last = decoded['lastInputFingerprint'];
      if (RecommendationInputTokens.isPersistable(last)) {
        repository._lastInputFingerprint = last as String;
      }
      final reviewed = decoded['reviewedRecommendationsByDate'];
      if (reviewed is Map) {
        for (final entry in reviewed.entries) {
          if (entry.key is String &&
              _validDate(entry.key as String) &&
              RecommendationInputTokens.isPersistable(entry.value)) {
            repository._reviewedRecommendationsByDate[entry.key as String] =
                entry.value as String;
          }
        }
      }
    }
    // Replace legacy/raw/unknown payloads before exposing a loaded repository.
    // Failed native acknowledgement is not masked by optimistic cache readback.
    if (raw != repository._encoded()) await repository._persist();
    return repository;
  }

  static bool _validDate(String value) =>
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);

  HydrationRecommendation? get latestRecommendation => _latestRecommendation;
  String? get lastInputFingerprint => _lastInputFingerprint;
  RecommendationTokenStatus get tokenStatus => _tokens.status;
  ChallengeRecommendationPreferences get challengePreferences =>
      _challengePreferences;

  // Local equality, not a remote authentication/MAC-verification boundary.
  bool isRecommendationReviewed({
    required String localDateKey,
    required String inputFingerprint,
  }) =>
      _reviewedRecommendationsByDate[localDateKey] == inputFingerprint;

  Future<void> _serial(Future<void> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _mutate(Future<void> Function() operation) {
    final generation = _generation;
    return _serial(() async {
      if (_resetPending || generation != _generation) {
        throw const PersonalizationPersistenceIncomplete();
      }
      final last = _lastInputFingerprint;
      final latest = _latestRecommendation;
      final reviewed = Map<String, String>.from(_reviewedRecommendationsByDate);
      final dismissed = _dismissedChallengesByDate;
      final preferences = _challengePreferences;
      try {
        await operation();
        if (generation != _generation) {
          throw const PersonalizationPersistenceIncomplete();
        }
      } catch (_) {
        if (generation == _generation) {
          _lastInputFingerprint = last;
          _latestRecommendation = latest;
          _reviewedRecommendationsByDate = reviewed;
          _dismissedChallengesByDate = dismissed;
          _challengePreferences = preferences;
        }
        throw const PersonalizationPersistenceIncomplete();
      }
    });
  }

  Future<void> markRecommendationReviewed({required String localDateKey}) =>
      _mutate(() async {
        if (!_validDate(localDateKey)) {
          throw const PersonalizationPersistenceIncomplete();
        }
        final fingerprint = _lastInputFingerprint;
        if (fingerprint == null) return;
        _reviewedRecommendationsByDate[localDateKey] = fingerprint;
        await _persist();
        notifyListeners();
      });

  Future<void> setChallengePreferences(
    ChallengeRecommendationPreferences value, {
    DateTime? now,
  }) =>
      _mutate(() async {
        _challengePreferences =
            value.copyWith(updatedAt: now ?? DateTime.now());
        await _persist();
        notifyListeners();
      });

  Set<String> dismissedForDate(String localDateKey) =>
      Set.unmodifiable(_dismissedChallengesByDate[localDateKey] ?? const {});

  Future<void> recordRecommendation({
    required String canonicalInput,
    required HydrationRecommendation recommendation,
  }) =>
      _mutate(() async {
        final generation = _generation;
        final token = await _tokens.create(canonicalInput);
        if (_resetPending || generation != _generation) {
          throw const PersonalizationPersistenceIncomplete();
        }
        if (_lastInputFingerprint == token &&
            _latestRecommendation?.roundedRecommendedGoalMl ==
                recommendation.roundedRecommendedGoalMl) {
          return;
        }
        _lastInputFingerprint = token;
        _latestRecommendation = recommendation;
        if (_tokens.status == RecommendationTokenStatus.memoryOnly) {
          _reviewedRecommendationsByDate.removeWhere(
              (_, value) => RecommendationInputTokens.isPersistable(value));
        }
        await _persist();
        notifyListeners();
      });

  Future<void> dismissChallenge({
    required String localDateKey,
    required String challengeId,
  }) =>
      _mutate(() async {
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
      });

  Future<void> clear() {
    _generation++;
    _resetPending = true;
    _lastInputFingerprint = null;
    _latestRecommendation = null;
    _reviewedRecommendationsByDate = {};
    _dismissedChallengesByDate = {};
    _challengePreferences = const ChallengeRecommendationPreferences();
    return _serial(() async {
      try {
        // First overwrite with acknowledged, verified token-free state. The
        // shared remove API has no native acknowledgement contract (DATA-005).
        await _persist();
        await _tokens.clear();
        await _store.remove(storageKey);
        _resetPending = false;
        notifyListeners();
      } catch (_) {
        throw const PersonalizationPersistenceIncomplete();
      }
    });
  }

  String _encoded() => jsonEncode({
        'schemaVersion': schemaVersion,
        'lastInputFingerprint':
            RecommendationInputTokens.isPersistable(_lastInputFingerprint)
                ? _lastInputFingerprint
                : null,
        'challengePreferences': _challengePreferences.toJson(),
        'reviewedRecommendationsByDate': {
          for (final entry in _reviewedRecommendationsByDate.entries)
            if (RecommendationInputTokens.isPersistable(entry.value))
              entry.key: entry.value,
        },
        'dismissedChallengesByDate': {
          for (final entry in _dismissedChallengesByDate.entries)
            entry.key: entry.value.toList()..sort(),
        },
      });

  Future<void> _persist() async {
    final value = _encoded();
    try {
      if (!await _store.writeString(storageKey, value) ||
          await _store.readString(storageKey) != value) {
        throw const PersonalizationPersistenceIncomplete();
      }
    } catch (_) {
      throw const PersonalizationPersistenceIncomplete();
    }
  }
}
