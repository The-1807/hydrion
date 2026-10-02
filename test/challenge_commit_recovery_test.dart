import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_challenge_record.dart';
import 'support/memory_protected_app_store.dart';
import 'pomodoro_session_service_test.dart' show PomodoroFixture;

class AmbiguousStore extends MemoryProtectedAppStore {
  bool armed = false;
  bool commit = false;
  bool unreadable = false;
  ProtectedWriteStatus failure = ProtectedWriteStatus.verificationFailed;
  @override
  Future<ProtectedWriteStatus> writeChallenges(
      ProtectedChallengeRecord value) async {
    if (!armed) return super.writeChallenges(value);
    if (commit) await super.writeChallenges(value);
    if (unreadable) challengeReadFailure = ProtectedReadStatus.unavailable;
    return failure;
  }
}

void main() {
  test('Bottle Bingo retains a committed log and never duplicates retry',
      () async {
    final store = AmbiguousStore()..commit = true;
    final local = MemoryHydrionStore();
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    final hydration = await HydrationRepository.load(local);
    final time = DateTime(2030, 1, 1, 12);
    await repo.join(
        id: 'bottle-bingo',
        name: 'Bingo',
        description: '',
        targetMl: 2000,
        durationDays: 7,
        joinedAt: time);
    store.armed = true;
    final log = await repo.completeBottleBingoHydrationTile(
        index: 0,
        hydrationRepository: hydration,
        volumeMl: 150,
        timestamp: time);
    expect(log, isNotNull);
    expect(repo.isKnown, isTrue);
    expect(repo.activeChallenge!.bottleBingoCompletedTiles, contains(0));
    expect(hydration.logs, hasLength(1));
    await repo.completeBottleBingoHydrationTile(
        index: 0,
        hydrationRepository: hydration,
        volumeMl: 150,
        timestamp: time);
    expect(hydration.logs, hasLength(1));
    await repo.close();
  });

  test(
      'known rejection with unavailable reconciliation makes no destructive guess',
      () async {
    final store = AmbiguousStore()
      ..failure = ProtectedWriteStatus.failed
      ..unreadable = true;
    final local = MemoryHydrionStore();
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    final hydration = await HydrationRepository.load(local);
    final time = DateTime(2030, 1, 1, 12);
    await repo.join(
        id: 'plant-twin-challenge',
        name: 'Plant',
        description: '',
        targetMl: 2000,
        durationDays: 7,
        joinedAt: time,
        parameters: const {'cue': 'test'});
    store.armed = true;
    await expectLater(
        repo.completeHydrationAction(
            hydrationRepository: hydration,
            volumeMl: 150,
            actionKey: 'sip',
            timestamp: time),
        throwsA(isA<ChallengeStorageUnavailable>().having(
            (error) => error.writeStatus,
            'write status',
            ProtectedWriteStatus.failed)));
    expect(repo.isKnown, isFalse);
    expect(hydration.logs, hasLength(1));
    await repo.close();
  });
  for (final commit in [false, true]) {
    test(
        'ambiguous outcome preserves log through unavailable reconciliation commit=$commit',
        () async {
      final store = AmbiguousStore()
        ..commit = commit
        ..unreadable = true;
      final local = MemoryHydrionStore();
      final repo = await ChallengeRepository.load(local, protectedStore: store);
      final hydration = await HydrationRepository.load(local);
      final time = DateTime(2030, 1, 1, 12);
      await repo.join(
          id: 'plant-twin-challenge',
          name: 'Plant',
          description: '',
          targetMl: 2000,
          durationDays: 7,
          joinedAt: time,
          parameters: const {'cue': 'test'});
      store.armed = true;
      await expectLater(
          repo.completeHydrationAction(
              hydrationRepository: hydration,
              volumeMl: 150,
              actionKey: 'sip',
              timestamp: time),
          throwsA(isA<ChallengeStorageUnavailable>()));
      expect(repo.isKnown, isFalse);
      expect(hydration.logs, hasLength(1));
      expect((await HydrationRepository.load(local)).logs, hasLength(1));
      store.armed = false;
      store.challengeReadFailure = null;
      await repo.refreshFromStore();
      await repo.completeHydrationAction(
          hydrationRepository: hydration,
          volumeMl: 150,
          actionKey: 'sip',
          timestamp: time);
      expect(repo.activeChallenge!.completedActionIds, hasLength(1));
      expect(hydration.logs, hasLength(1));
      await repo.close();
    });
  }

  test('verification failure with readable absent evidence remains retryable',
      () async {
    final store = AmbiguousStore();
    final local = MemoryHydrionStore();
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    final hydration = await HydrationRepository.load(local);
    final time = DateTime(2030, 1, 1, 12);
    await repo.join(
        id: 'plant-twin-challenge',
        name: 'Plant',
        description: '',
        targetMl: 2000,
        durationDays: 7,
        joinedAt: time,
        parameters: const {'cue': 'test'});
    store.armed = true;
    await expectLater(
        repo.completeHydrationAction(
            hydrationRepository: hydration,
            volumeMl: 150,
            actionKey: 'sip',
            timestamp: time),
        throwsA(isA<ChallengeStorageUnavailable>()));
    expect(repo.isKnown, isTrue);
    expect(repo.activeChallenge!.completedActionIds, isEmpty);
    expect(hydration.logs, hasLength(1));
    store.armed = false;
    await repo.completeHydrationAction(
        hydrationRepository: hydration,
        volumeMl: 150,
        actionKey: 'sip',
        timestamp: time);
    expect(repo.activeChallenge!.completedActionIds, hasLength(1));
    expect(hydration.logs, hasLength(1));
    await repo.close();
  });

  for (final conflict in [false, true]) {
    test('real precommit rejection compensates only new log conflict=$conflict',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('hydrion-i08-precommit-');
      var fail = false;
      final db = await EncryptedAppStore.open(
          path: '${directory.path}/app.db',
          key: Uint8List.fromList(List.filled(32, 94)),
          failureInjector: (stage) async {
            if (fail && stage == AppStoreStage.recordWritten) {
              throw StateError('synthetic rollback');
            }
          });
      addTearDown(() async {
        await db.close();
        await directory.delete(recursive: true);
      });
      final local = MemoryHydrionStore();
      final repo = await ChallengeRepository.load(local, protectedStore: db);
      final hydration = await HydrationRepository.load(local);
      final time = DateTime(2030, 1, 1, 12);
      await repo.join(
          id: 'plant-twin-challenge',
          name: 'Plant',
          description: '',
          targetMl: 2000,
          durationDays: 7,
          joinedAt: time,
          parameters: const {'cue': 'test'});
      if (conflict) {
        final old = (await db.readChallenges()).record!;
        expect(
            await db.writeChallenges(ProtectedChallengeRecord(
                revision: old.revision + 2,
                phase: ContextRecordPhase.active,
                state: old.state)),
            ProtectedWriteStatus.committed);
      } else {
        fail = true;
      }
      await expectLater(
          repo.completeHydrationAction(
              hydrationRepository: hydration,
              volumeMl: 150,
              actionKey: 'sip',
              timestamp: time),
          throwsA(isA<ChallengeStorageUnavailable>()));
      expect(hydration.logs, isEmpty);
      expect(repo.activeChallenge!.completedActionIds, isEmpty);
    });
  }
  for (final pomodoro in [false, true]) {
    test('committed evidence retains hydration and retry: pomodoro=$pomodoro',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('hydrion-i08-reconcile-');
      var verificationFailures = 0;
      final db = await EncryptedAppStore.open(
        path: '${directory.path}/app.db',
        key: Uint8List.fromList(List.filled(32, 93)),
        failureInjector: (stage) async {
          if (stage == AppStoreStage.beforeVerification &&
              verificationFailures > 0) {
            verificationFailures--;
            throw StateError('synthetic verification outage');
          }
        },
      );
      addTearDown(() async {
        await db.close();
        await directory.delete(recursive: true);
      });
      if (pomodoro) {
        final fixture = await PomodoroFixture.create(protectedStore: db);
        await fixture.sessions.start();
        fixture.clock.advance(const Duration(minutes: 25));
        await fixture.sessions.reconcile();
        // Persist the pending-drink checkpoint before targeting action evidence.
        final state = fixture.sessions.currentState()!;
        await fixture.challenges.updateParameters({
          ...fixture.challenges.activeChallenge!.parameters,
          'pomodoroPendingDrink': {
            'sessionId': state.sessionId,
            'actionKey': 'pomodoro-session-${state.sessionId}-drink',
            'eventAt': fixture.clock.now.toIso8601String(),
            'amountMl': 150,
          },
        });
        verificationFailures = 1;
        final recovered = await fixture.sessions.recordMeasuredDrink(
            hydrationRepository: fixture.hydration, amountMl: 150);
        expect(recovered, isNotNull);
        expect(fixture.challenges.isKnown, isTrue);
        await fixture.challenges.refreshFromStore();
        expect(
            fixture.challenges.activeChallenge!.completedActionIds, isNotEmpty);
        expect(fixture.hydration.logs, hasLength(1));
        await fixture.sessions.recordMeasuredDrink(
            hydrationRepository: fixture.hydration, amountMl: 150);
        expect(fixture.hydration.logs, hasLength(1));
        expect(fixture.hydration.logs.single.volumeMl, 150);
        expect(
            fixture
                .challenges.activeChallenge!.parameters['pomodoroPendingDrink'],
            isNull);
        expect(
            fixture.challenges.activeChallenge!
                .parameters['pomodoroConsumedSessionIds'],
            contains(state.sessionId));
      } else {
        final local = MemoryHydrionStore();
        final repo = await ChallengeRepository.load(local, protectedStore: db);
        final hydration = await HydrationRepository.load(local);
        final time = DateTime(2030, 1, 1, 12);
        await repo.join(
            id: 'plant-twin-challenge',
            name: 'Plant',
            description: '',
            targetMl: 2000,
            durationDays: 7,
            joinedAt: time,
            parameters: const {'cue': 'test'});
        verificationFailures = 1;
        final recovered = await repo.completeHydrationAction(
            hydrationRepository: hydration,
            volumeMl: 150,
            actionKey: 'sip',
            timestamp: time);
        expect(recovered, isNotNull);
        expect(repo.isKnown, isTrue);
        await repo.refreshFromStore();
        expect(repo.activeChallenge!.completedActionIds, hasLength(1));
        expect(hydration.logs, hasLength(1));
        await repo.completeHydrationAction(
            hydrationRepository: hydration,
            volumeMl: 150,
            actionKey: 'sip',
            timestamp: time);
        expect(hydration.logs, hasLength(1));
      }
    });
  }
}
