import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  group('Release 18 active challenge limit', () {
    test('allows two active challenges and blocks a third without replacing',
        () async {
      final challenges = ChallengeRepository.memory();

      expect(
        await challenges.join(
          id: 'temperature-roulette',
          name: 'Temperature Roulette',
          description: 'Temperature plan',
          targetMl: 2200,
          durationDays: 5,
          parameters: const {'amountMl': 250, 'weatherOrdering': 'disabled'},
        ),
        isTrue,
      );
      expect(
        await challenges.join(
          id: 'eat-your-water-day',
          name: 'Eat Your Water Day',
          description: 'Food check-in',
          targetMl: 2200,
          durationDays: 1,
          parameters: const {'meal': 'Lunch', 'food': 'Cucumber'},
        ),
        isTrue,
      );
      expect(
        await challenges.join(
          id: 'bottle-bingo',
          name: 'Bottle Bingo',
          description: 'Bingo',
          targetMl: 2200,
          durationDays: 7,
          parameters: const {
            'cutoffHour': 12,
            'difficulty': 'steady',
            'reminderPreference': 'morning',
            'amountMl': 250,
          },
        ),
        isFalse,
      );

      expect(challenges.activeChallenges.map((challenge) => challenge.id), [
        'temperature-roulette',
        'eat-your-water-day',
      ]);
    });

    test('legacy single active challenge migrates into active challenge list',
        () async {
      final store = MemoryHydrionStore();
      await store.writeString(
        ChallengeRepository.storageKey,
        '{"schemaVersion":3,"id":"temperature-roulette","name":"Temperature Roulette","description":"Legacy","targetMl":2200,"durationDays":5,"joinedAt":"2026-07-18T08:00:00.000","parameters":{"amountMl":250,"weatherOrdering":"disabled"}}',
      );

      final challenges = await ChallengeRepository.load(store);

      expect(challenges.activeChallenges, hasLength(1));
      expect(challenges.activeChallenge?.id, 'temperature-roulette');
    });

    test('migration keeps two active attempts and pauses visible overflow',
        () async {
      final store = MemoryHydrionStore();
      JoinedChallenge legacy(String id, int hour) => JoinedChallenge(
            id: id,
            name: 'Friendly $id',
            description: 'A preserved challenge attempt.',
            targetMl: 2200,
            durationDays: 5,
            joinedAt: DateTime(2026, 7, 18, hour),
          );
      await store.writeString(
        ChallengeRepository.storageKey,
        jsonEncode({
          'schemaVersion': 4,
          'activeChallenges': [
            legacy('temperature-roulette', 7).toJson(),
            legacy('pomodoro-sip', 8).toJson(),
            legacy('bottle-bingo', 9).toJson(),
          ],
        }),
      );

      final challenges = await ChallengeRepository.load(store);

      expect(challenges.activeChallenges, hasLength(2));
      expect(challenges.pausedChallenges, hasLength(1));
      expect(challenges.pausedChallenges.single.id, 'bottle-bingo');
      expect(challenges.pausedChallenges.single.lifecycleStatus,
          ChallengeLifecycleStatus.paused);
    });
  });

  group('Release 18 Pomodoro sip semantics', () {
    test(
        'legacy Pomodoro check-in remains readable without inventing hydration',
        () async {
      final challenges = ChallengeRepository.memory();
      final hydration = HydrationRepository.memory();
      await challenges.join(
        id: 'pomodoro-sip',
        name: 'Pomodoro Sip',
        description: 'Focus check-ins',
        targetMl: 2200,
        durationDays: 3,
        joinedAt: DateTime(2026, 7, 18, 8),
        parameters: const {
          'sessionMinutes': 25,
          'sessionsPerDay': 1,
          'amountMl': 150,
          'shortBreakMinutes': 5,
          'notifications': 'disabled',
          'autoStartNext': 'disabled',
          'challengeDurationDays': 3,
        },
      );

      final checkedIn = await challenges.completeCheckIn(
        '2026-07-18:day-1-pomodoro-sip-session-1',
        challengeId: 'pomodoro-sip',
      );

      expect(checkedIn, isTrue);
      expect(hydration.logs, isEmpty);
      expect(
        challenges
            .progressFor(hydration, now: DateTime(2026, 7, 18, 10))
            .completedDays,
        1,
      );
    });

    test('measured Pomodoro drink creates one canonical hydration record',
        () async {
      final challenges = ChallengeRepository.memory();
      final hydration = HydrationRepository.memory();
      await challenges.join(
        id: 'pomodoro-sip',
        name: 'Pomodoro Sip',
        description: 'Focus check-ins',
        targetMl: 2200,
        durationDays: 3,
        joinedAt: DateTime(2026, 7, 18, 8),
        parameters: const {
          'sessionMinutes': 25,
          'sessionsPerDay': 1,
          'amountMl': 150,
          'shortBreakMinutes': 5,
          'notifications': 'disabled',
          'autoStartNext': 'disabled',
          'challengeDurationDays': 3,
        },
      );

      final log = await challenges.completeHydrationAction(
        hydrationRepository: hydration,
        volumeMl: 150,
        actionKey: '2026-07-18:day-1-pomodoro-sip-measured-1',
        timestamp: DateTime(2026, 7, 18, 9),
        challengeId: 'pomodoro-sip',
      );

      expect(log, isNotNull);
      expect(hydration.logs, hasLength(1));
      expect(hydration.totalForDay(DateTime(2026, 7, 18)), 150);
      final progress = challenges.progressFor(
        hydration,
        now: DateTime(2026, 7, 18, 10),
      );
      expect(progress.todayMl, 150);
      expect(progress.completedDays, 1);
    });
  });

  group('Release 18 guided tour state', () {
    test('persists skip, completion, contextual tours, and replay request',
        () async {
      final store = MemoryHydrionStore();
      final first = await GuidedTourRepository.load(store);

      expect(first.shouldShowCoreTour, isTrue);

      await first.setCurrentStep(2);
      await first.skipCoreTour();
      await first.completeContextualTour('bottle-bingo');

      final second = await GuidedTourRepository.load(store);
      expect(second.shouldShowCoreTour, isFalse);
      expect(second.currentStep, 0);
      expect(second.isContextualTourComplete('bottle-bingo'), isTrue);

      second.replayCoreTour();
      expect(second.shouldShowCoreTour, isTrue);

      await second.completeCoreTour();
      expect(second.shouldShowCoreTour, isFalse);
      expect(second.state.completed, isTrue);
    });
  });
}
