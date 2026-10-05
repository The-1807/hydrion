import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:hydrion/repositories/challenge_repository.dart';
import 'package:hydrion/repositories/challenge_protection.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';
import 'package:hydrion/storage/protected_challenge_record.dart';

import 'support/memory_protected_app_store.dart';

const sourceKey = ChallengeRepository.storageKey;
const syntheticCue = 'synthetic-private-cue-3791';

Map<String, Object?> state() => {
      'schemaVersion': 6,
      'activeChallenges': [
        JoinedChallenge(
            id: 'plant-twin-challenge',
            name: 'Plant',
            description: '',
            targetMl: 2000,
            durationDays: 7,
            joinedAt: DateTime(2026, 9, 30),
            parameters: const {'cue': syntheticCue}).toJson()
      ],
      'challengeHistory': [],
    };

class CleanupStore extends MemoryHydrionStore {
  bool rejectCleanup = false;
  bool rejectIntent = false;
  CleanupStore(super.initialValues);
  @override
  Future<bool> removeAcknowledged(String key) async =>
      rejectCleanup ? false : super.removeAcknowledged(key);
  @override
  Future<bool> writeString(String key, String value) async =>
      rejectIntent ? false : super.writeString(key, value);
}

class PausedChallengeStore extends MemoryProtectedAppStore {
  Completer<void>? hold;
  @override
  Future<ProtectedWriteStatus> writeChallenges(
      ProtectedChallengeRecord value) async {
    await hold?.future;
    return super.writeChallenges(value);
  }
}

class ActivationStore extends MemoryProtectedAppStore {
  bool failActivation = true;
  @override
  Future<ProtectedWriteStatus> writeChallenges(
      ProtectedChallengeRecord value) async {
    if (failActivation && value.phase == ContextRecordPhase.active) {
      return ProtectedWriteStatus.failed;
    }
    return super.writeChallenges(value);
  }
}

void main() {
  test('matching provisional restart activates without losing source',
      () async {
    final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
    final store = ActivationStore();
    var repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.isKnown, isFalse);
    expect(store.challengeRecord!.phase, ContextRecordPhase.provisional);
    expect(local.snapshot[sourceKey], contains(syntheticCue));
    store.failActivation = false;
    repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.isKnown, isTrue);
    expect(local.snapshot[sourceKey], isNull);
  });

  test('missing destination cannot erase acknowledged migration history',
      () async {
    final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
    final store = MemoryProtectedAppStore();
    await ChallengeRepository.load(local, protectedStore: store);
    store.challengeRecord = null;
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.corrupt);
    expect(store.challengeRecord, isNull);
    expect(local.snapshot[ChallengeProtection.authorityKey], '1');
  });

  test('unknown source fields retained even beside an active protected copy',
      () async {
    final local = MemoryHydrionStore({
      sourceKey: jsonEncode({...state(), 'future': syntheticCue})
    });
    final store = MemoryProtectedAppStore()
      ..challengeRecord = ProtectedChallengeRecord(
          revision: 2, phase: ContextRecordPhase.active, state: state());
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.cleanupPending);
    expect(repo.activeChallenge!.parameters['cue'], syntheticCue);
    expect(local.snapshot[sourceKey], contains('future'));
  });

  test('competing mutations reject before changing pending state', () async {
    final store = PausedChallengeStore();
    final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    store.hold = Completer<void>();
    final pending = repo.updateParameters({'cue': '$syntheticCue-next'});
    expect(repo.isKnown, isFalse);
    await expectLater(
        repo.clear(), throwsA(isA<ChallengeStorageUnavailable>()));
    await expectLater(repo.updateParameters({'cue': 'stale'}),
        throwsA(isA<ChallengeStorageUnavailable>()));
    store.hold!.complete();
    await pending;
    expect(repo.activeChallenge!.parameters['cue'], '$syntheticCue-next');
    expect(local.snapshot[sourceKey], isNull);
  });

  test('failed new write is not published or written as plaintext', () async {
    final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
    final store = MemoryProtectedAppStore();
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    store.challengeWriteFailure = ProtectedWriteStatus.failed;
    await expectLater(repo.updateParameters({'cue': '$syntheticCue-new'}),
        throwsA(isA<ChallengeStorageUnavailable>()));
    expect(repo.isKnown, isFalse);
    expect(jsonEncode(local.snapshot), isNot(contains(syntheticCue)));
    store.challengeWriteFailure = null;
    await repo.refreshFromStore();
    expect(repo.activeChallenge!.parameters['cue'], syntheticCue);
  });

  test('deletion cleanup failure remains fenced through restart', () async {
    final local = CleanupStore({sourceKey: jsonEncode(state())});
    final store = MemoryProtectedAppStore();
    var repo = await ChallengeRepository.load(local, protectedStore: store);
    local.rejectCleanup = true;
    await expectLater(
        repo.clear(), throwsA(isA<ChallengeStorageUnavailable>()));
    expect(store.challengeRecord!.phase, ContextRecordPhase.deleted);
    final revision = store.challengeRecord!.revision;
    repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.deletionPending);
    expect(repo.isKnown, isFalse);
    local.rejectCleanup = false;
    await repo.refreshFromStore();
    expect(repo.isKnown, isTrue);
    expect(store.challengeRecord!.revision, revision);
    expect(local.snapshot[ChallengeProtection.deletionKey], isNull);
  });

  for (final phase in [
    AppStoreStage.recordWritten,
    AppStoreStage.beforeVerification
  ]) {
    test('real transactional $phase failure preserves restart authority',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('hydrion-i08-fault-');
      var fail = false;
      final db = await EncryptedAppStore.open(
          path: '${directory.path}/app.db',
          key: Uint8List.fromList(List.filled(32, 81)),
          failureInjector: (stage) async {
            if (fail && stage == phase) throw StateError('synthetic fault');
          });
      final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
      final repo = await ChallengeRepository.load(local, protectedStore: db);
      fail = true;
      await expectLater(repo.updateParameters({'cue': '$syntheticCue-new'}),
          throwsA(isA<ChallengeStorageUnavailable>()));
      expect(repo.isKnown, isFalse);
      expect(jsonEncode(local.snapshot), isNot(contains(syntheticCue)));
      fail = false;
      await repo.refreshFromStore();
      expect(
          repo.activeChallenge!.parameters['cue'],
          phase == AppStoreStage.recordWritten
              ? syntheticCue
              : '$syntheticCue-new');
      await repo.close();
      await directory.delete(recursive: true);
    });
  }

  for (final future in [false, true]) {
    test(
        'real protected ${future ? 'future' : 'corrupt'} schema is quarantined',
        () async {
      final directory =
          await Directory.systemTemp.createTemp('hydrion-i08-schema-');
      final path = '${directory.path}/app.db';
      final key = Uint8List.fromList(List.filled(32, 82));
      var db = await EncryptedAppStore.open(path: path, key: key);
      final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
      await ChallengeRepository.load(local, protectedStore: db);
      await db.close();
      final native = sqlite.sqlite3.open(path);
      native.execute(
          'PRAGMA key = "x\'${key.map((e) => e.toRadixString(16).padLeft(2, '0')).join()}\'"');
      native.execute(future
          ? 'UPDATE challenge_state SET schema_version = 99'
          : "UPDATE challenge_state SET payload = 'broken'");
      native.close();
      db = await EncryptedAppStore.open(path: path, key: key);
      final repo = await ChallengeRepository.load(local, protectedStore: db);
      expect(
          repo.storageStatus,
          future
              ? ChallengeStorageStatus.unsupported
              : ChallengeStorageStatus.corrupt);
      expect(repo.isKnown, isFalse);
      await repo.close();
      await directory.delete(recursive: true);
    });
  }

  test('SQLCipher migration, protected writes, reopen and tombstone deletion',
      () async {
    final directory = await Directory.systemTemp.createTemp('hydrion-i08-');
    final path = '${directory.path}/app.db';
    final key = Uint8List.fromList(List.filled(32, 79));
    final local = MemoryHydrionStore(
        {sourceKey: jsonEncode(state()), 'ordinary': 'keep'});
    var store = await EncryptedAppStore.open(path: path, key: key);
    var repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.ready);
    expect(repo.activeChallenge!.parameters['cue'], syntheticCue);
    expect(local.snapshot,
        {'ordinary': 'keep', ChallengeProtection.authorityKey: '1'});
    await repo.updateParameters({'cue': '$syntheticCue-new'});
    expect(jsonEncode(local.snapshot), isNot(contains(syntheticCue)));
    await repo.close();
    store = await EncryptedAppStore.open(path: path, key: key);
    repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.activeChallenge!.parameters['cue'], '$syntheticCue-new');
    await repo.clear();
    expect((await store.readChallenges()).status, ProtectedReadStatus.absent);
    expect(local.snapshot,
        {'ordinary': 'keep', ChallengeProtection.authorityKey: '3'});
    await repo.close();
    await directory.delete(recursive: true);
  });

  for (final failure in [
    ProtectedWriteStatus.failed,
    ProtectedWriteStatus.verificationFailed
  ]) {
    test('$failure preserves legacy and supports retry', () async {
      final raw = jsonEncode(state());
      final local = MemoryHydrionStore({sourceKey: raw});
      final store = MemoryProtectedAppStore()..challengeWriteFailure = failure;
      final repo = await ChallengeRepository.load(local, protectedStore: store);
      expect(repo.isKnown, isFalse);
      expect(local.snapshot[sourceKey], raw);
      store.challengeWriteFailure = null;
      await repo.refreshFromStore();
      expect(repo.isKnown, isTrue);
      expect(local.snapshot, {ChallengeProtection.authorityKey: '1'});
    });
  }
  for (final failure in [
    ProtectedReadStatus.unavailable,
    ProtectedReadStatus.unsupported,
    ProtectedReadStatus.corrupt
  ]) {
    test('$failure cannot publish defaults or remove source', () async {
      final raw = jsonEncode(state());
      final local = MemoryHydrionStore({sourceKey: raw});
      final repo = await ChallengeRepository.load(local,
          protectedStore: MemoryProtectedAppStore()
            ..challengeReadFailure = failure);
      expect(repo.isKnown, isFalse);
      expect(repo.hasRoomForAnotherChallenge, isFalse);
      expect(local.snapshot[sourceKey], raw);
      await expectLater(repo.updateParameters({'cue': 'new'}),
          throwsA(isA<ChallengeStorageUnavailable>()));
    });
  }
  test('cleanup failure, activation restart, conflict authority, cleanup retry',
      () async {
    final local = CleanupStore({sourceKey: jsonEncode(state())})
      ..rejectCleanup = true;
    final store = MemoryProtectedAppStore();
    var repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.cleanupPending);
    await repo.updateParameters({'cue': '$syntheticCue-new'});
    repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.activeChallenge!.parameters['cue'], '$syntheticCue-new');
    expect(repo.storageStatus, ChallengeStorageStatus.cleanupPending);
    local.rejectCleanup = false;
    await repo.refreshFromStore();
    expect(repo.storageStatus, ChallengeStorageStatus.ready);
    expect(local.snapshot, {ChallengeProtection.authorityKey: '2'});
    final revision = store.challengeRecord!.revision;
    await repo.refreshFromStore();
    expect(store.challengeRecord!.revision, revision);
  });
  test('provisional conflict preserves both copies', () async {
    final local = MemoryHydrionStore({sourceKey: jsonEncode(state())});
    final store = MemoryProtectedAppStore()
      ..challengeRecord = ProtectedChallengeRecord(
          revision: 1,
          phase: ContextRecordPhase.provisional,
          state: const {
            'schemaVersion': 6,
            'activeChallenges': [],
            'challengeHistory': []
          });
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.corrupt);
    expect(local.snapshot[sourceKey], contains(syntheticCue));
    expect(store.challengeRecord!.phase, ContextRecordPhase.provisional);
  });
  for (final raw in [
    'broken',
    '{"schemaVersion":99}',
    jsonEncode({...state(), 'unknown': syntheticCue})
  ]) {
    test('invalid or future source is retained: ${raw.length}', () async {
      final local = MemoryHydrionStore({sourceKey: raw});
      final repo = await ChallengeRepository.load(local,
          protectedStore: MemoryProtectedAppStore());
      expect(repo.isKnown, isFalse);
      expect(local.snapshot[sourceKey], raw);
    });
  }
  test(
      'failed deletion intent preserves source; acknowledged intent fences restart',
      () async {
    final local = CleanupStore({sourceKey: jsonEncode(state())});
    final store = MemoryProtectedAppStore();
    var repo = await ChallengeRepository.load(local, protectedStore: store);
    local.rejectIntent = true;
    await expectLater(
        repo.clear(), throwsA(isA<ChallengeStorageUnavailable>()));
    expect(store.challengeRecord!.phase, ContextRecordPhase.active);
    local.rejectIntent = false;
    store.challengeWriteFailure = ProtectedWriteStatus.failed;
    await expectLater(
        repo.clear(), throwsA(isA<ChallengeStorageUnavailable>()));
    expect(local.snapshot[ChallengeProtection.deletionKey], isNotNull);
    repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.deletionPending);
    expect(repo.activeChallenges, isEmpty);
    store.challengeWriteFailure = null;
    await repo.refreshFromStore();
    expect(repo.storageStatus, ChallengeStorageStatus.ready);
    expect(store.challengeRecord!.phase, ContextRecordPhase.deleted);
    expect(local.snapshot, {ChallengeProtection.authorityKey: '2'});
  });
  test('diagnostics never stringify source payload', () {
    final record = ProtectedChallengeRecord(
        revision: 1, phase: ContextRecordPhase.active, state: state());
    expect(
        '$record ${ProtectedChallengeRead(ProtectedReadStatus.found, record)} ${const ChallengeStorageUnavailable()}',
        isNot(contains(syntheticCue)));
  });

  test(
      'typed entry fields cannot mutate a protected record through facade copies',
      () {
    final record = ProtectedChallengeRecord(
        revision: 1, phase: ContextRecordPhase.active, state: state());
    final entry = record.activeChallenges.single;
    expect(entry.targetMl, 2000);
    expect(entry.joinedAt, DateTime(2026, 9, 30));
    entry.parameters['cue'] = 'mutated';
    expect(record.activeChallenges.single.parameters['cue'], syntheticCue);
  });

  test(
      'protected activity checkpoint supports the complete owned parameter vocabulary',
      () async {
    final repo = await ChallengeRepository.load(MemoryHydrionStore(),
        protectedStore: MemoryProtectedAppStore());
    await repo.join(
        id: 'backpack-bottle-check',
        name: 'Synthetic',
        description: '',
        targetMl: 2000,
        durationDays: 7,
        profileAge: 15,
        joinedAt: DateTime(2026, 9, 30),
        parameters: {'preparationHour': 8});
    expect(
        await repo.completeActivityCheckpoint(
            challengeId: 'backpack-bottle-check',
            checkpointId: 'bottle-status',
            outcome: 'ready',
            completedAt: DateTime(2026, 9, 30, 8)),
        isTrue);
    await repo.refreshFromStore();
    expect(repo.activeChallenge!.parameters['lastActivityOutcome'], 'ready');
    expect(repo.activeChallenge!.completedActionIds, hasLength(1));
  });

  test('unclassified nested parameters preserve the entire legacy source',
      () async {
    final payload = state();
    ((payload['activeChallenges'] as List).single as Map)['parameters'] = {
      'unknown': {'clinical': syntheticCue}
    };
    final raw = jsonEncode(payload);
    final local = MemoryHydrionStore({sourceKey: raw});
    final store = MemoryProtectedAppStore();
    final repo = await ChallengeRepository.load(local, protectedStore: store);
    expect(repo.storageStatus, ChallengeStorageStatus.corrupt);
    expect(local.snapshot[sourceKey], raw);
    expect(store.challengeRecord, isNull);
  });
}
