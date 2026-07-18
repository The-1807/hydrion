import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/bottle_bingo.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/presentation/challenge_history_presenter.dart';

void main() {
  final day = DateTime(2026, 7, 18);

  Future<void> joinPair(ChallengeRepository challenges) async {
    await challenges.join(
      id: 'temperature-roulette',
      name: 'Temperature Roulette',
      description: 'Temperature plan',
      targetMl: 2200,
      durationDays: 5,
      joinedAt: DateTime(2026, 7, 18, 7),
      parameters: const {
        'amountMl': 250,
        'weatherOrdering': 'disabled',
        'temperatureSchedule': [
          'Cool',
          'Room temperature',
          'Comfortably warm',
          'Cool',
          'Room temperature',
        ],
      },
    );
    await challenges.join(
      id: 'around-the-world-infusion-week',
      name: 'Around the World Infusion Week',
      description: 'Infusion plan',
      targetMl: 2200,
      durationDays: 7,
      joinedAt: DateTime(2026, 7, 18, 7),
      parameters: const {'amountMl': 250},
    );
  }

  group('Release 18 shared hydration qualification', () {
    test(
        'one record can qualify neither, A, B, or both without duplicate water',
        () async {
      final hydration = HydrationRepository.memory();
      final challenges = ChallengeRepository.memory();
      challenges.bindHydrationRepository(hydration);
      await joinPair(challenges);

      final none = (await hydration.addLog(
        volumeMl: 100,
        timestamp: DateTime(2026, 7, 18, 8),
        source: 'quick-add',
      ))!;
      final onlyA = (await hydration.addLog(
        volumeMl: 150,
        timestamp: DateTime(2026, 7, 18, 9),
        source: 'quick-add',
        metadata: const HydrationMetadata(temperatureStyle: 'Cool'),
      ))!;
      final onlyB = (await hydration.addLog(
        volumeMl: 200,
        timestamp: DateTime(2026, 7, 18, 10),
        source: 'quick-add',
        metadata: const HydrationMetadata(
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      ))!;
      final both = (await hydration.addLog(
        volumeMl: 250,
        timestamp: DateTime(2026, 7, 18, 11),
        source: 'quick-add',
        metadata: const HydrationMetadata(
          temperatureStyle: 'Cool',
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      ))!;

      expect(challenges.qualificationsForLogId(none.id), isEmpty);
      expect(challenges.qualificationsForLogId(onlyA.id), hasLength(1));
      expect(challenges.qualificationsForLogId(onlyB.id), hasLength(1));
      expect(challenges.qualificationsForLogId(both.id), hasLength(2));
      expect(hydration.logs, hasLength(4));
      expect(hydration.totalForDay(day), 700);
      expect(
        challenges
            .progressFor(
              hydration,
              challengeId: 'temperature-roulette',
              now: DateTime(2026, 7, 18, 12),
            )
            .todayMl,
        400,
      );
      expect(
        challenges
            .progressFor(
              hydration,
              challengeId: 'around-the-world-infusion-week',
              now: DateTime(2026, 7, 18, 12),
            )
            .todayMl,
        450,
      );
    });

    test('edit and delete recalculate every active challenge', () async {
      final hydration = HydrationRepository.memory();
      final challenges = ChallengeRepository.memory();
      challenges.bindHydrationRepository(hydration);
      await joinPair(challenges);
      final log = (await hydration.addLog(
        volumeMl: 250,
        timestamp: DateTime(2026, 7, 18, 9),
        source: 'quick-add',
        metadata: const HydrationMetadata(
          temperatureStyle: 'Cool',
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      ))!;
      expect(challenges.qualificationsForLogId(log.id), hasLength(2));

      await hydration.updateLog(
        id: log.id,
        volumeMl: 300,
        metadata: const HydrationMetadata(
          temperatureStyle: 'Room temperature',
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      );
      expect(challenges.qualificationsForLogId(log.id), hasLength(1));
      expect(
        challenges
            .progressFor(
              hydration,
              challengeId: 'temperature-roulette',
              now: day,
            )
            .todayMl,
        0,
      );
      expect(
        challenges
            .progressFor(
              hydration,
              challengeId: 'around-the-world-infusion-week',
              now: day,
            )
            .todayMl,
        300,
      );

      await hydration.deleteLog(log.id);
      expect(hydration.totalForDay(day), 0);
      expect(challenges.qualificationsForLogId(log.id), isEmpty);
      expect(
        challenges
            .progressFor(
              hydration,
              challengeId: 'around-the-world-infusion-week',
              now: day,
            )
            .todayMl,
        0,
      );
    });

    test('qualification and metadata survive repository restart', () async {
      final store = MemoryHydrionStore();
      final hydration = await HydrationRepository.load(store);
      final challenges = await ChallengeRepository.load(store);
      challenges.bindHydrationRepository(hydration);
      await joinPair(challenges);
      final log = (await hydration.addLog(
        volumeMl: 250,
        timestamp: DateTime(2026, 7, 18, 9),
        source: 'quick-add',
        metadata: const HydrationMetadata(
          temperatureStyle: 'Cool',
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      ))!;

      final reloadedHydration = await HydrationRepository.load(store);
      final reloadedChallenges = await ChallengeRepository.load(store);
      reloadedChallenges.bindHydrationRepository(reloadedHydration);

      expect(reloadedHydration.logs.single.id, log.id);
      expect(reloadedChallenges.qualificationsForLogId(log.id), hasLength(2));
      expect(reloadedHydration.totalForDay(day), 250);
    });

    test('one shared log has friendly evidence in both challenge histories',
        () async {
      final hydration = HydrationRepository.memory();
      final challenges = ChallengeRepository.memory();
      challenges.bindHydrationRepository(hydration);
      await joinPair(challenges);
      final log = (await hydration.addLog(
        volumeMl: 250,
        timestamp: DateTime(2026, 7, 18, 11, 15),
        source: 'quick-add',
        metadata: const HydrationMetadata(
          temperatureStyle: 'Cool',
          infusionTheme: 'Citrus',
          noAddedSugar: true,
        ),
      ))!;

      final histories = {
        for (final challenge in challenges.activeChallenges)
          challenge.id: ChallengeHistoryPresenter.present(
            challenge: challenge,
            hydrationLogs: hydration.logs,
            unit: HydrionVolumeUnit.ounces,
            hydrationLogQualifies: (candidate) =>
                challenges.hydrationLogQualifies(challenge, candidate),
          ),
      };

      expect(hydration.logs, [log]);
      expect(histories['temperature-roulette'], hasLength(1));
      expect(
        histories['temperature-roulette']!.single.description,
        'Logged a Cool drink · 8.5 oz',
      );
      expect(histories['around-the-world-infusion-week'], hasLength(1));
      expect(
        histories['around-the-world-infusion-week']!.single.description,
        'Tried the Citrus infusion · 8.5 oz',
      );
    });

    test('Bottle Bingo automatic evidence reverses after edit and delete',
        () async {
      final hydration = HydrationRepository.memory();
      final challenges = ChallengeRepository.memory();
      await challenges.join(
        id: 'bottle-bingo',
        name: 'Bottle Bingo',
        description: 'A hydration board.',
        targetMl: 2200,
        durationDays: 7,
        joinedAt: DateTime(2026, 7, 18, 7),
        parameters: const {'cutoffHour': 12, 'bingoBoardVersion': 2},
      );
      final board = BottleBingoBoard.forInstance(
        challenges.activeChallenge!.joinedAt.microsecondsSinceEpoch,
      );
      final beforeLunch = board.tiles.indexWhere(
        (tile) => tile.id == 'before-lunch',
      );
      final firstQuarter = board.tiles.indexWhere(
        (tile) => tile.id == 'goal-25',
      );
      final log = (await hydration.addLog(
        volumeMl: 600,
        timestamp: DateTime(2026, 7, 18, 9),
        source: 'quick-add',
      ))!;

      expect(
        challenges.bottleBingoCompletedIndexes(
          hydration,
          now: day,
          dailyGoalMl: 2200,
        ),
        containsAll(<int>[beforeLunch, firstQuarter]),
      );

      await hydration.updateLog(
        id: log.id,
        volumeMl: 100,
        timestamp: DateTime(2026, 7, 18, 18),
      );
      final edited = challenges.bottleBingoCompletedIndexes(
        hydration,
        now: day,
        dailyGoalMl: 2200,
      );
      expect(edited, isNot(contains(beforeLunch)));
      expect(edited, isNot(contains(firstQuarter)));

      await hydration.deleteLog(log.id);
      expect(
        challenges.bottleBingoCompletedIndexes(
          hydration,
          now: day,
          dailyGoalMl: 2200,
        ),
        {BottleBingoBoard.centerIndex},
      );
    });

    test('rapid taps, new-day reuse, and new-instance reuse stay idempotent',
        () async {
      final hydration = HydrationRepository.memory();
      final challenges = ChallengeRepository.memory();
      challenges.bindHydrationRepository(hydration);
      await challenges.join(
        id: 'temperature-roulette',
        name: 'Temperature Roulette',
        description: 'Temperature plan',
        targetMl: 2200,
        durationDays: 5,
        joinedAt: DateTime(2026, 7, 18, 7),
        parameters: const {
          'amountMl': 250,
          'weatherOrdering': 'disabled',
          'temperatureSchedule': ['Cool'],
        },
      );

      final results = await Future.wait([
        challenges.completeHydrationAction(
          hydrationRepository: hydration,
          volumeMl: 250,
          actionKey: 'temperature-action',
          timestamp: DateTime(2026, 7, 18, 9),
          challengeId: 'temperature-roulette',
          metadata: const HydrationMetadata(temperatureStyle: 'Cool'),
        ),
        challenges.completeHydrationAction(
          hydrationRepository: hydration,
          volumeMl: 250,
          actionKey: 'temperature-action',
          timestamp: DateTime(2026, 7, 18, 9),
          challengeId: 'temperature-roulette',
          metadata: const HydrationMetadata(temperatureStyle: 'Cool'),
        ),
      ]);
      expect(results.whereType<HydrationLog>(), hasLength(1));

      expect(
        await challenges.completeHydrationAction(
          hydrationRepository: hydration,
          volumeMl: 250,
          actionKey: 'temperature-action',
          timestamp: DateTime(2026, 7, 19, 9),
          challengeId: 'temperature-roulette',
          metadata: const HydrationMetadata(temperatureStyle: 'Cool'),
        ),
        isNotNull,
      );
      final oldInstance = challenges.activeChallenge!.instanceId;
      await challenges.completeChallenge('temperature-roulette');
      final repeated = await challenges.repeatChallenge(
        oldInstance,
        startedAt: DateTime(2026, 7, 20, 7),
      );
      expect(repeated, isNotNull);
      expect(repeated!.instanceId, isNot(oldInstance));
      expect(
        await challenges.completeHydrationAction(
          hydrationRepository: hydration,
          volumeMl: 250,
          actionKey: 'temperature-action',
          timestamp: DateTime(2026, 7, 20, 9),
          challengeId: 'temperature-roulette',
          metadata: const HydrationMetadata(temperatureStyle: 'Cool'),
        ),
        isNotNull,
      );
      expect(hydration.logs, hasLength(3));
      expect(hydration.totalMl, 750);
    });
  });
}
