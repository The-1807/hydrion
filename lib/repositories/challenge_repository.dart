import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../storage/local_store.dart';
import 'hydration_repository.dart';

class JoinedChallenge {
  final String id;
  final String name;
  final String description;
  final int targetMl;
  final int durationDays;
  final DateTime joinedAt;

  const JoinedChallenge({
    required this.id,
    required this.name,
    required this.description,
    required this.targetMl,
    required this.durationDays,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'targetMl': targetMl,
      'durationDays': durationDays,
      'joinedAt': joinedAt.toIso8601String(),
    };
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

    if (id.isEmpty ||
        name.isEmpty ||
        description.isEmpty ||
        targetMl is! num ||
        durationDays is! num ||
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
    );
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

  final HydrionLocalStore _store;
  JoinedChallenge? _activeChallenge;

  ChallengeRepository._(this._store, this._activeChallenge);

  ChallengeRepository.memory() : this._(MemoryHydrionStore(), null);

  static Future<ChallengeRepository> load(HydrionLocalStore store) async {
    final raw = await store.readString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return ChallengeRepository._(store, null);
    }

    try {
      return ChallengeRepository._(
        store,
        JoinedChallenge.fromJson(jsonDecode(raw)),
      );
    } on FormatException {
      return ChallengeRepository._(store, null);
    }
  }

  JoinedChallenge? get activeChallenge => _activeChallenge;

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

  ChallengeProgress progressFor(HydrationRepository hydrationRepository) {
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
    final todayMl = hydrationRepository.totalForDay(today);
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
      if (hydrationRepository.totalForDay(day) >= challenge.targetMl) {
        completedDays += 1;
      }
    }

    return ChallengeProgress(
      completedDays: completedDays,
      durationDays: challenge.durationDays,
      todayMl: todayMl,
      targetMl: challenge.targetMl,
    );
  }
}
