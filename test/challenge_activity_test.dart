import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/challenge_activity.dart';
import 'package:hydrion/domain/bottle_bingo.dart';
import 'package:hydrion/domain/challenge_experience.dart';
import 'package:hydrion/l10n/app_localizations_es.dart';
import 'package:hydrion/l10n/app_localizations_fr.dart';
import 'package:hydrion/l10n/challenge_localizations.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  const setupById = <String, Map<String, Object?>>{
    'lunch-break-refill': {
      'windowStartHour': 12,
      'reminderEnabled': 'enabled',
    },
    'homework-hydration': {
      'sessionMinutes': 30,
      'checkpointPattern': 'midpoint',
    },
    'after-school-recharge': {'windowStartHour': 16},
    'backpack-bottle-check': {'preparationHour': 20},
    'desk-day-reset': {
      'blockMinutes': 120,
      'resetFrequencyMinutes': 45,
    },
    'shift-hydration-check': {
      'shiftStartMinutes': 1320,
      'shiftDurationMinutes': 600,
    },
    'commute-cup': {
      'preparationHour': 7,
      'travelStartHour': 8,
    },
    'evening-goal-review': {'reviewHour': 20},
  };

  Future<ChallengeRepository> joinActivity(
    String id, {
    HydrionLocalStore? store,
    DateTime? joinedAt,
  }) async {
    const teenChallenges = {
      'lunch-break-refill',
      'homework-hydration',
      'after-school-recharge',
      'backpack-bottle-check',
    };
    final repository = store == null
        ? ChallengeRepository.memory()
        : await ChallengeRepository.load(store);
    final joined = await repository.join(
      id: id,
      name: id,
      description: 'A deliberate challenge activity.',
      targetMl: 2200,
      durationDays: 7,
      joinedAt: joinedAt ?? DateTime(2026, 7, 30, 8),
      profileAge: teenChallenges.contains(id) ? 15 : 30,
      parameters: setupById[id]!,
    );
    expect(joined, isTrue);
    return repository;
  }

  group('eight challenge activity definitions', () {
    test('French and Spanish cover preview and active activity copy', () {
      final french = AppLocalizationsFr();
      final spanish = AppLocalizationsEs();
      for (final id in HydrionChallengeActivities.definitions.keys) {
        final activity = HydrionChallengeActivities.forId(id)!;
        final experience = HydrionChallengeExperiences.byId(id);
        final sourceValues = <String>[
          experience.purpose,
          ...experience.actions,
          experience.whatCounts,
          experience.whatDoesNotCount,
          activity.setupSummary,
          if (activity.safetyMessage.isNotEmpty) activity.safetyMessage,
          for (final checkpoint in activity.checkpoints) ...[
            checkpoint.title,
            checkpoint.description,
          ],
        ];
        for (final source in sourceValues) {
          expect(french.challengeText(source), isNot(source),
              reason: 'Missing French challenge copy for $id: $source');
          expect(spanish.challengeText(source), isNot(source),
              reason: 'Missing Spanish challenge copy for $id: $source');
        }
      }
    });

    test('all eight have setup and deliberate checkpoints', () {
      expect(HydrionChallengeActivities.definitions, hasLength(8));
      for (final entry in HydrionChallengeActivities.definitions.entries) {
        expect(entry.value.requiredParameters, isNotEmpty, reason: entry.key);
        expect(entry.value.checkpoints, isNotEmpty, reason: entry.key);
      }
    });

    for (final id in setupById.keys) {
      test('$id records each checkpoint once and in order', () async {
        final repository = await joinActivity(id);
        final definition = HydrionChallengeActivities.forId(id)!;
        final at = id == 'commute-cup'
            ? DateTime(2026, 7, 30, 7, 30)
            : DateTime(2026, 7, 30, 12);

        if (definition.checkpoints.length > 1) {
          expect(
            await repository.completeActivityCheckpoint(
              challengeId: id,
              checkpointId: definition.checkpoints[1].id,
              completedAt: at,
            ),
            isFalse,
          );
        }

        for (final checkpoint in definition.checkpoints) {
          expect(
            await repository.completeActivityCheckpoint(
              challengeId: id,
              checkpointId: checkpoint.id,
              completedAt: at,
            ),
            isTrue,
          );
          expect(
            await repository.completeActivityCheckpoint(
              challengeId: id,
              checkpointId: checkpoint.id,
              completedAt: at,
            ),
            isFalse,
          );
        }
        expect(
          repository.activeChallengeFor(id)!.completedActionIds,
          hasLength(definition.checkpoints.length),
        );
      });
    }
  });

  test('opening or reloading a challenge never creates progress', () async {
    final store = MemoryHydrionStore();
    final first = await joinActivity('lunch-break-refill', store: store);
    expect(first.activeChallenge!.completedActionIds, isEmpty);

    final reloaded = await ChallengeRepository.load(store);
    expect(reloaded.activeChallenge!.completedActionIds, isEmpty);
  });

  test('timed activity pause and restart recovery preserve elapsed state',
      () async {
    final store = MemoryHydrionStore();
    final repository = await joinActivity('homework-hydration', store: store);
    final started = DateTime(2026, 7, 30, 10);

    expect(
      await repository.startActivitySession(
        'homework-hydration',
        startedAt: started,
      ),
      isTrue,
    );
    expect(
      repository.activitySessionElapsed(
        'homework-hydration',
        now: started.add(const Duration(minutes: 8)),
      ),
      const Duration(minutes: 8),
    );
    expect(
      await repository.pauseActivitySession(
        'homework-hydration',
        pausedAt: started.add(const Duration(minutes: 8)),
      ),
      isTrue,
    );

    final reloaded = await ChallengeRepository.load(store);
    expect(
      reloaded.activitySessionElapsed('homework-hydration'),
      const Duration(minutes: 8),
    );
    expect(
      reloaded.activeChallenge!.parameters['activitySessionStatus'],
      'paused',
    );
  });

  test('pausing and leaving retain evidence and return reminder IDs', () async {
    final repository = await joinActivity('lunch-break-refill');
    await repository.updateParameters({
      ...repository.activeChallenge!.parameters,
      'lunchReminderId': 'challenge-lunch-reminder',
    });
    await repository.completeActivityCheckpoint(
      challengeId: 'lunch-break-refill',
      checkpointId: 'bottle-check',
      completedAt: DateTime(2026, 7, 30, 12),
    );

    final paused = await repository.pauseChallenge('lunch-break-refill');
    expect(paused.changed, isTrue);
    expect(paused.obsoleteReminderIds, contains('challenge-lunch-reminder'));
    expect(paused.challenge!.completedActionIds, hasLength(1));

    await repository.resumeChallenge(paused.challenge!.instanceId);
    final left =
        await repository.leaveChallengeWithHistory('lunch-break-refill');
    expect(left.changed, isTrue);
    expect(left.challenge!.completedActionIds, hasLength(1));
    expect(left.challenge!.lifecycleStatus, ChallengeLifecycleStatus.left);
  });

  test('commute interaction is rejected after travel begins', () async {
    final repository = await joinActivity('commute-cup');

    expect(
      await repository.completeActivityCheckpoint(
        challengeId: 'commute-cup',
        checkpointId: 'prepared-before-travel',
        completedAt: DateTime(2026, 7, 30, 8),
      ),
      isFalse,
    );
    expect(repository.activeChallenge!.completedActionIds, isEmpty);
    expect(
      HydrionChallengeActivities.forId('commute-cup')!.safetyMessage,
      contains('Do not read, tap, or log while driving'),
    );
  });

  test('overnight shift checkpoint evidence remains on the activity day',
      () async {
    final repository = await joinActivity('shift-hydration-check');
    final definition =
        HydrionChallengeActivities.forId('shift-hydration-check')!;
    final checkpointTimes = [
      DateTime(2026, 7, 30, 22),
      DateTime(2026, 7, 31, 3),
      DateTime(2026, 7, 31, 8),
    ];

    for (var index = 0; index < definition.checkpoints.length; index++) {
      expect(
        await repository.completeActivityCheckpoint(
          challengeId: 'shift-hydration-check',
          checkpointId: definition.checkpoints[index].id,
          completedAt: checkpointTimes[index],
        ),
        isTrue,
      );
    }
    expect(repository.activeChallenge!.completedActionIds, hasLength(3));
  });

  group('all challenge localization coverage', () {
    test('all 14 experience definitions have French and Spanish copy', () {
      final french = AppLocalizationsFr();
      final spanish = AppLocalizationsEs();
      final missing = <String>[];
      for (final experience in HydrionChallengeExperiences.definitions) {
        final sourceValues = <String>[
          experience.purpose,
          ...experience.actions,
          experience.whatCounts,
          experience.whatDoesNotCount,
          ...experience.schedule,
        ];
        for (final source in sourceValues) {
          if (french.challengeText(source) == source) {
            missing.add('fr ${experience.id}: $source');
          }
          if (spanish.challengeText(source) == source) {
            missing.add('es ${experience.id}: $source');
          }
        }
      }
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    test('all Bottle Bingo tiles have French and Spanish copy', () {
      final french = AppLocalizationsFr();
      final spanish = AppLocalizationsEs();
      final missing = <String>[];
      for (final tile in BottleBingoBoard.forInstance(0).tiles) {
        for (final source in [tile.title, tile.instruction]) {
          if (french.challengeText(source) == source) {
            missing.add('fr ${tile.id}: $source');
          }
          if (spanish.challengeText(source) == source) {
            missing.add('es ${tile.id}: $source');
          }
        }
      }
      expect(missing, isEmpty, reason: missing.join('\n'));
    });
  });
}
