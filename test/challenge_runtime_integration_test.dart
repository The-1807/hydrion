import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';

void main() {
  String dayToken(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  test('Eat Your Water progresses from its check-in without fake water',
      () async {
    final hydration = HydrationRepository.memory();
    final challenges = ChallengeRepository.memory();
    final now = DateTime.now();
    final challenge = HydrionChallengeCatalog.byId('eat-your-water-day');
    await challenges.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      joinedAt: DateTime(now.year, now.month, now.day),
      parameters: const {'meal': 'lunch', 'food': 'cucumber'},
    );

    expect(challenges.progressFor(hydration).completedDays, 0);
    await challenges.completeCheckIn(
      '${dayToken(now)}:day-1-eat-your-water-day',
    );

    expect(challenges.progressFor(hydration).completedDays, 1);
    expect(hydration.logs, isEmpty);
    expect(hydration.totalForDay(now), 0);
  });

  test('Plant Twin progresses from the real-world cue check-in', () async {
    final hydration = HydrationRepository.memory();
    final challenges = ChallengeRepository.memory();
    final now = DateTime.now();
    final challenge = HydrionChallengeCatalog.byId('plant-twin-challenge');
    await challenges.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      joinedAt: DateTime(now.year, now.month, now.day),
      parameters: const {'cue': 'Water the desk plant'},
    );
    await challenges.completeCheckIn(
      '${dayToken(now)}:day-1-plant-twin-challenge',
    );

    expect(challenges.progressFor(hydration).completedDays, 1);
    expect(hydration.logs, isEmpty);
  });

  test('Infusion action writes one canonical log and updates both totals',
      () async {
    final hydration = HydrationRepository.memory();
    final challenges = ChallengeRepository.memory();
    final now = DateTime.now();
    final challenge =
        HydrionChallengeCatalog.byId('around-the-world-infusion-week');
    await challenges.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      joinedAt: DateTime(now.year, now.month, now.day),
      parameters: const {'amountMl': 300, 'noAddedSugar': 'confirmed'},
    );
    final log = await challenges.completeHydrationAction(
      hydrationRepository: hydration,
      volumeMl: 300,
      actionKey: 'citrus-day-1',
      timestamp: now,
    );

    expect(log, isNotNull);
    expect(hydration.logs, hasLength(1));
    expect(hydration.totalForDay(now), 300);
    expect(challenges.progressFor(hydration).todayMl, 300);
    expect(challenges.activeChallenge!.completedActionIds,
        contains(log!.actionId));
  });

  test('ordinary Home water remains canonical but does not fake infusion proof',
      () async {
    final hydration = HydrationRepository.memory();
    final challenges = ChallengeRepository.memory();
    final now = DateTime.now();
    final challenge =
        HydrionChallengeCatalog.byId('around-the-world-infusion-week');
    await challenges.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      joinedAt: DateTime(now.year, now.month, now.day),
      parameters: const {'amountMl': 300, 'noAddedSugar': 'confirmed'},
    );
    await hydration.addLog(volumeMl: 500, timestamp: now, source: 'home');

    expect(hydration.totalForDay(now), 500);
    expect(challenges.progressFor(hydration).todayMl, 0);
    expect(challenges.progressFor(hydration).completedDays, 0);
  });

  test('Temperature Roulette action is canonical and idempotent', () async {
    final hydration = HydrationRepository.memory();
    final challenges = ChallengeRepository.memory();
    final now = DateTime.now();
    final challenge = HydrionChallengeCatalog.byId('temperature-roulette');
    await challenges.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: 2200,
      durationDays: challenge.durationDays,
      joinedAt: DateTime(now.year, now.month, now.day),
      parameters: const {'amountMl': 250, 'weatherOrdering': 'enabled'},
    );
    final first = await challenges.completeHydrationAction(
      hydrationRepository: hydration,
      volumeMl: 250,
      actionKey: 'day-1-cool',
      timestamp: now,
    );
    final duplicate = await challenges.completeHydrationAction(
      hydrationRepository: hydration,
      volumeMl: 250,
      actionKey: 'day-1-cool',
      timestamp: now,
    );

    expect(first, isNotNull);
    expect(duplicate, isNull);
    expect(hydration.logs, hasLength(1));
    expect(challenges.progressFor(hydration).todayMl, 250);
  });
}
