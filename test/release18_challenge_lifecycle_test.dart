import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/bottle_bingo.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  Future<ChallengeRepository> activePomodoro([HydrionLocalStore? store]) async {
    final repository = store == null
        ? ChallengeRepository.memory()
        : await ChallengeRepository.load(store);
    await repository.join(
      id: 'pomodoro-sip',
      name: 'Pomodoro Sip',
      description: 'Focus and sip',
      targetMl: 2200,
      durationDays: 3,
      joinedAt: DateTime(2026, 7, 18, 8),
      parameters: const {
        'sessionMinutes': 25,
        'sessionsPerDay': 2,
        'amountMl': 150,
        'notifications': 'enabled',
        'timerStatus': 'running',
        'timerEndsAt': '2026-07-18T12:00:00.000',
        'timerReminderId': 'pomodoro-reminder',
      },
    );
    await repository.completeCheckIn(
      '2026-07-18:session-1',
      challengeId: 'pomodoro-sip',
    );
    return repository;
  }

  group('Release 18 challenge lifecycle', () {
    test(
        'pause preserves progress, stops timer, cancels evidence and frees slot',
        () async {
      final repository = await activePomodoro();
      final before = repository.activeChallenge!;
      final change = await repository.pauseChallenge(
        'pomodoro-sip',
        pausedAt: DateTime(2026, 7, 18, 10),
      );

      expect(change.changed, isTrue);
      expect(change.obsoleteReminderIds, contains('pomodoro-reminder'));
      expect(repository.activeChallenges, isEmpty);
      expect(repository.hasRoomForAnotherChallenge, isTrue);
      expect(repository.pausedChallenges.single.completedActionIds,
          before.completedActionIds);
      expect(repository.pausedChallenges.single.parameters['timerStatus'],
          'paused');
      expect(
          repository.pausedChallenges.single.parameters['timerReminderId'], '');
    });

    test('resume restores the same instance and persisted progress', () async {
      final store = MemoryHydrionStore();
      final first = await activePomodoro(store);
      final instance = first.activeChallenge!.instanceId;
      await first.pauseChallenge('pomodoro-sip');

      final second = await ChallengeRepository.load(store);
      expect(second.pausedChallenges.single.instanceId, instance);
      final resumed = await second.resumeChallenge(instance);

      expect(resumed.changed, isTrue);
      expect(second.activeChallenge!.instanceId, instance);
      expect(second.activeChallenge!.completedActionIds, isNotEmpty);
      expect(second.activeChallenge!.parameters['timerStatus'], 'paused');
    });

    test('completion, leave, archive and repeat retain prior attempts',
        () async {
      final repository = await activePomodoro();
      final oldInstance = repository.activeChallenge!.instanceId;
      final completed = await repository.completeChallenge('pomodoro-sip');
      expect(completed.changed, isTrue);
      expect(repository.activeChallenges, isEmpty);
      expect(repository.challengeHistory.single.lifecycleStatus,
          ChallengeLifecycleStatus.completed);

      final repeated = await repository.repeatChallenge(
        oldInstance,
        startedAt: DateTime(2026, 7, 19, 8),
      );
      expect(repeated, isNotNull);
      expect(repeated!.instanceId, isNot(oldInstance));
      expect(repeated.completedActionIds, isEmpty);
      expect(repository.challengeHistory, hasLength(1));

      await repository.leaveChallengeWithHistory('pomodoro-sip');
      expect(repository.challengeHistory.first.lifecycleStatus,
          ChallengeLifecycleStatus.left);
      expect(await repository.archiveChallenge(oldInstance), isTrue);
      expect(
        repository.challengeInstanceFor(oldInstance)!.lifecycleStatus,
        ChallengeLifecycleStatus.archived,
      );
    });

    test('repeated Bottle Bingo attempt receives a new deterministic board',
        () async {
      final repository = ChallengeRepository.memory();
      await repository.join(
        id: 'bottle-bingo',
        name: 'Bottle Bingo',
        description: 'Bingo board',
        targetMl: 2200,
        durationDays: 7,
        joinedAt: DateTime.fromMicrosecondsSinceEpoch(1000),
        parameters: const {'amountMl': 250, 'bingoBoardVersion': 2},
      );
      await repository.toggleBottleBingoTile(3);
      final old = repository.activeChallenge!;
      final oldBoard = BottleBingoBoard.forInstance(
        old.joinedAt.microsecondsSinceEpoch,
      );
      await repository.completeChallenge('bottle-bingo');
      final repeated = await repository.repeatChallenge(
        old.instanceId,
        startedAt: DateTime.fromMicrosecondsSinceEpoch(1001),
      );
      final newBoard = BottleBingoBoard.forInstance(
        repeated!.joinedAt.microsecondsSinceEpoch,
      );

      expect(repeated.bottleBingoCompletedTiles, isEmpty);
      expect(newBoard.tiles.first.id, isNot(oldBoard.tiles.first.id));
      expect(repository.challengeHistory.single.instanceId, old.instanceId);
    });
  });

  group('Release 18 challenge edit policy', () {
    test('immediate, next-day, invalid, and restart policies are explicit',
        () async {
      final repository = await activePomodoro();
      final oldInstance = repository.activeChallenge!.instanceId;

      final immediate = await repository.editParameter(
        challengeId: 'pomodoro-sip',
        key: 'notifications',
        value: 'disabled',
      );
      expect(immediate.effect, ChallengeEditEffect.immediate);
      expect(
          repository.activeChallenge!.parameters['notifications'], 'disabled');

      final tomorrow = await repository.editParameter(
        challengeId: 'pomodoro-sip',
        key: 'sessionMinutes',
        value: 30,
        now: DateTime(2026, 7, 18, 10),
      );
      expect(tomorrow.effect, ChallengeEditEffect.nextLocalDay);
      expect(repository.activeChallenge!.parameters['sessionMinutes'], 25);
      expect(
          repository.activeChallenge!.pendingParameters['sessionMinutes'], 30);
      await repository.reconcileLocalDay(DateTime(2026, 7, 19));
      expect(repository.activeChallenge!.parameters['sessionMinutes'], 30);
      expect(repository.activeChallenge!.pendingParameters, isEmpty);

      final invalid = await repository.editParameter(
        challengeId: 'pomodoro-sip',
        key: 'sessionMinutes',
        value: -1,
      );
      expect(invalid.changed, isFalse);

      final warning = await repository.editParameter(
        challengeId: 'pomodoro-sip',
        key: 'challengeDurationDays',
        value: 5,
      );
      expect(warning.changed, isFalse);
      expect(warning.effect, ChallengeEditEffect.restartRequired);
      expect(warning.message, contains('new challenge attempt'));

      final restarted = await repository.editParameter(
        challengeId: 'pomodoro-sip',
        key: 'challengeDurationDays',
        value: 5,
        now: DateTime(2026, 7, 20),
        confirmRestart: true,
      );
      expect(restarted.changed, isTrue);
      expect(restarted.challenge!.instanceId, isNot(oldInstance));
      expect(repository.challengeHistory, isNotEmpty);
      expect(repository.challengeHistory.first.completedActionIds, isNotEmpty);
    });
  });
}
