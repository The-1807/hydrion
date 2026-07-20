import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/bottle_bingo.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/domain/challenge_visual_registry.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  test('every current challenge has an explicit visual identity', () {
    expect(HydrionChallengeCatalog.challenges, hasLength(6));
    expect(
      HydrionChallengeCatalog.challenges.map((item) => item.id),
      isNot(contains('front-loader-challenge')),
    );
    for (final challenge in HydrionChallengeCatalog.challenges) {
      final visual = ChallengeVisualRegistry.forId(challenge.id);
      expect(visual.icon, isNotNull, reason: challenge.id);
      if (visual.cardAsset != null) {
        expect(File(visual.cardAsset!).existsSync(), isTrue,
            reason: visual.cardAsset);
      }
      final dashboardAsset = visual.dashboardAssetFor(null);
      expect(File(dashboardAsset).existsSync(), isTrue, reason: dashboardAsset);
    }
  });

  test('profile artwork uses explicit sex and neutral fallback rules', () {
    final temperature = ChallengeVisualRegistry.forId('temperature-roulette');
    expect(temperature.dashboardAssetFor(HydrionSex.male),
        endsWith('temp-roulette-man.png'));
    expect(temperature.dashboardAssetFor(HydrionSex.female),
        endsWith('temp-roulette-lady.png'));
    expect(temperature.dashboardAssetFor(HydrionSex.preferNotToSay),
        endsWith('temp-roulette.png'));
  });

  test('asset aliases resolve owner supplied filename stems', () {
    expect(ChallengeVisualRegistry.aliases['temp_roullete'],
        'temperature-roulette');
    expect(ChallengeVisualRegistry.aliases['arounddworld'],
        'around-the-world-infusion-week');
    expect(ChallengeVisualRegistry.aliases['pomo'], 'pomodoro-sip');
  });

  test('Bottle Bingo generation is stable and contains one free center', () {
    final first = BottleBingoBoard.forInstance(527);
    final again = BottleBingoBoard.forInstance(527);
    expect(first.tiles, hasLength(25));
    expect(first.tiles.map((tile) => tile.id),
        orderedEquals(again.tiles.map((tile) => tile.id)));
    expect(first.tiles[12].kind, BingoTileKind.free);
    expect(first.tiles.where((tile) => tile.kind == BingoTileKind.free),
        hasLength(1));
    expect(first.tiles.map((tile) => tile.id).toSet(), hasLength(25));
  });

  test('Bottle Bingo detects rows columns diagonals and multiple lines', () {
    final board = BottleBingoBoard.forInstance(1);
    expect(board.completedLines({0, 1, 2, 3, 4}), {0});
    expect(board.completedLines({0, 5, 10, 15, 20}), {5});
    expect(board.completedLines({0, 6, 18, 24}), {10});
    expect(
      board.completedLines({0, 1, 2, 3, 4, 5, 10, 15, 20}),
      {0, 5},
    );
  });

  test('legacy Front Loader state retires without touching other storage',
      () async {
    final store = MemoryHydrionStore();
    await store.writeString(
      ChallengeRepository.storageKey,
      jsonEncode({
        'schemaVersion': 3,
        'id': 'front-loader-challenge',
        'name': 'Front-Loader Challenge',
        'description': 'Retired challenge',
        'targetMl': 2200,
        'durationDays': 3,
        'joinedAt': DateTime(2026, 1, 1).toIso8601String(),
      }),
    );
    await store.writeString('unrelated-history', 'preserved');

    final repository = await ChallengeRepository.load(store);

    expect(repository.activeChallenge, isNull);
    expect(await store.readString(ChallengeRepository.storageKey), isNull);
    expect(await store.readString('unrelated-history'), 'preserved');
  });
}
