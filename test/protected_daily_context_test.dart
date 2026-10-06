import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/storage/encrypted_app_store.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';

import 'support/memory_protected_app_store.dart';

void main() {
  const sourceKey = DailyHydrationContextRepository.storageKey;
  const intentKey = DailyHydrationContextRepository.deletionKey;
  const authorityKey = DailyHydrationContextRepository.authorityKey;
  // Plaintext may hold only the payload-free authority revision (D3).
  void expectOnlyAuthority(MemoryHydrionStore local) {
    expect(local.snapshot.keys, [authorityKey]);
    expect(int.parse(local.snapshot[authorityKey]!), greaterThan(0));
  }

  String legacy([int count = 1]) => jsonEncode({
        'schemaVersion': 1,
        'contexts': List.generate(count, (i) => _context(i + 1).toJson())
      });

  test(
      'real SQLCipher migration verifies then strips source and survives restart',
      () async {
    final directory = await Directory.systemTemp.createTemp('hydrion-context-');
    final path = '${directory.path}/app.db';
    final key = Uint8List.fromList(List.filled(32, 70));
    final local = MemoryHydrionStore({sourceKey: legacy(20)});
    var store = await EncryptedAppStore.open(path: path, key: key);
    var repo = await DailyHydrationContextRepository.load(local,
        protectedStore: store);
    expect(repo.status, DailyContextStatus.ready);
    expectOnlyAuthority(local);
    expect((await store.readDailyContext()).record!.contexts, hasLength(14));
    expect(repo.forDate('2026-09-06'), isNull);
    expect(repo.forDate('2026-09-07'), isNotNull);
    await repo.close();
    store = await EncryptedAppStore.open(path: path, key: key);
    repo = await DailyHydrationContextRepository.load(local,
        protectedStore: store);
    expect(repo.forDate('2026-09-20')!.temporaryCondition,
        HydrionTemporaryCondition.fever);
    await repo.clear();
    expect(repo.forDate('2026-09-20'), isNull);
    expectOnlyAuthority(local);
    await repo.close();
    await directory.delete(recursive: true);
  });

  for (final failure in [
    ProtectedWriteStatus.failed,
    ProtectedWriteStatus.verificationFailed
  ]) {
    test('migration $failure preserves source and reports unavailable',
        () async {
      final raw = legacy();
      final local = MemoryHydrionStore({sourceKey: raw});
      final protected = MemoryProtectedAppStore()..writeFailure = failure;
      final repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      expect(repo.isKnown, isFalse);
      expect(repo.forDate('2026-09-01'), isNull);
      expect(local.snapshot[sourceKey], raw);
      protected.writeFailure = null;
      await repo.retry();
      expect(repo.status, DailyContextStatus.ready);
      expect(local.snapshot.containsKey(sourceKey), isFalse);
    });
  }

  test('cutover failure retains source and provisional state for retry',
      () async {
    final local = MemoryHydrionStore({sourceKey: legacy()});
    final protected = _RejectActivation();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.isKnown, isFalse);
    expect(protected.record!.phase, ContextRecordPhase.provisional);
    expect(local.snapshot[sourceKey], isNotNull);
    protected.reject = false;
    await repo.retry();
    expect(repo.status, DailyContextStatus.ready);
    expect(protected.record!.phase, ContextRecordPhase.active);
    expectOnlyAuthority(local);
  });

  test(
      'failed legacy cleanup is explicit and retry never restores stale source',
      () async {
    final local = _Local({sourceKey: legacy()})..rejectRemoval = true;
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.cleanupPending);
    expect(await repo.remove('2026-09-01'), isFalse);
    expect(await repo.save(_context(2)), isTrue);
    expect(repo.status, DailyContextStatus.cleanupPending);
    local.rejectRemoval = false;
    final restarted = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(restarted.status, DailyContextStatus.ready);
    expect(restarted.forDate('2026-09-02'), isNotNull);
    expectOnlyAuthority(local);
  });

  test('failed save never publishes new fields or creates plaintext', () async {
    final local = MemoryHydrionStore();
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(await repo.save(_context(1)), isTrue);
    protected.writeFailure = ProtectedWriteStatus.failed;
    expect(await repo.save(_context(2)), isFalse);
    expect(repo.isKnown, isFalse);
    expectOnlyAuthority(local);
    protected.writeFailure = null;
    await repo.retry();
    expect(repo.forDate('2026-09-01'), isNotNull);
    expect(repo.forDate('2026-09-02'), isNull);
  });

  test('acknowledged deletion intent hides both copies across restart',
      () async {
    final local = _Local({sourceKey: legacy()})..rejectRemoval = true;
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    protected.deleteFailure = ProtectedDeleteStatus.failed;
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(repo.status, DailyContextStatus.deletionPending);
    expect(local.snapshot[intentKey], isNotNull);
    expect(repo.forDate('2026-09-01'), isNull);
    final restarted = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(restarted.status, DailyContextStatus.deletionPending);
    expect(await restarted.save(_context(2)), isFalse);
    protected.deleteFailure = null;
    local.rejectRemoval = false;
    await restarted.retry();
    expect(restarted.status, DailyContextStatus.ready);
    expect(restarted.forDate('2026-09-01'), isNull);
    expectOnlyAuthority(local);
  });

  test('rejected deletion intent does not destroy protected data', () async {
    final local = _Local();
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    await repo.save(_context(1));
    local.rejectWrite = true;
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(protected.record!.contexts, hasLength(1));
    expect(local.snapshot.containsKey(intentKey), isFalse);
    expect(repo.isKnown, isFalse);
  });

  for (final restart in [false, true]) {
    test('H1 unavailable clear cannot resurrect context: restart=$restart',
        () async {
      final local = MemoryHydrionStore();
      final protected = MemoryProtectedAppStore();
      var repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      await repo.save(_context(1));
      protected.readFailure = ProtectedReadStatus.unavailable;
      await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
      expect(repo.isKnown, isFalse);
      protected.readFailure = null;
      if (restart) {
        repo = await DailyHydrationContextRepository.load(local,
            protectedStore: protected);
      } else {
        await repo.retry();
      }
      expect(repo.forDate('2026-09-01'), isNull);
      expect(repo.isKnown, isTrue);
      expect(protected.record!.phase, ContextRecordPhase.deleted);
      expectOnlyAuthority(local);
    });
  }

  test('deletion verification failure retains intent until verified retry',
      () async {
    final local = MemoryHydrionStore();
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    await repo.save(_context(1));
    protected.deleteFailure = ProtectedDeleteStatus.verificationFailed;
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(local.snapshot[intentKey], isNotNull);
    expect(repo.isKnown, isFalse);
    protected.deleteFailure = null;
    await repo.retry();
    expect(repo.isKnown, isTrue);
    expectOnlyAuthority(local);
    expect(repo.forDate('2026-09-01'), isNull);
  });

  for (final throwsRead in [false, true]) {
    test(
        'H1 intent precedes unreadable storage and survives restart: throw=$throwsRead',
        () async {
      final local = MemoryHydrionStore();
      final protected = _ObservedProtected(local)
        ..record = ProtectedContextRecord(
            revision: 41,
            phase: ContextRecordPhase.active,
            contexts: [_context(1)]);
      final repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      protected.observing = true;
      protected.throwRead = throwsRead;
      protected.readFailure = ProtectedReadStatus.unavailable;
      await expectLater(
          repo.clear(),
          throwsA(predicate<Object>(
              (error) => error.toString() == 'DailyContextUnavailable')));
      expect(protected.readIntents, [true]);
      expect(protected.deletedRevisions, isEmpty);
      expect(jsonDecode(local.snapshot[intentKey]!),
          {'schemaVersion': 2, 'pending': true});
      expect(repo.recoveryEvents, isEmpty);
      final restarted = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      expect(restarted.status, DailyContextStatus.deletionPending);
      expect(restarted.forDate('2026-09-01'), isNull);
      expect(await restarted.save(_context(2)), isFalse);
      await restarted.retry();
      expect(restarted.isKnown, isFalse);
      expect(local.snapshot[intentKey], isNotNull);
      protected.throwRead = false;
      protected.readFailure = null;
      await restarted.retry();
      expect(protected.deletedRevisions, [42]);
      expect(protected.record!.contexts, isEmpty);
      expect(restarted.isKnown, isTrue);
      expectOnlyAuthority(local);
      await restarted.retry();
      expect(protected.deletedRevisions, [42]);
      expect(restarted.forDate('2026-09-01'), isNull);
    });
  }

  test(
      'H1 rejected intent never attempts protected IO or promises restart deletion',
      () async {
    final local = _Local();
    final protected = _ObservedProtected(local)
      ..record = ProtectedContextRecord(
          revision: 8,
          phase: ContextRecordPhase.active,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    protected.observing = true;
    local.rejectWrite = true;
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(protected.readIntents, isEmpty);
    expect(protected.deletedRevisions, isEmpty);
    expect(local.snapshot[intentKey], isNull);
    final restarted = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    // No acknowledged intent means restart protection cannot be promised.
    expect(restarted.forDate('2026-09-01'), isNotNull);
  });

  test(
      'H1 cleanup retries reuse tombstone until legacy removal is acknowledged',
      () async {
    final local = _Local({sourceKey: legacy()})..rejectRemoval = true;
    final protected = _ObservedProtected(local);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(protected.deletedRevisions, [2]);
    expect(local.snapshot[sourceKey], isNotNull);
    expect(local.snapshot[intentKey], isNotNull);
    await repo.retry();
    expect(protected.deletedRevisions, [2, 2]);
    expect(repo.isKnown, isFalse);
    local.rejectRemoval = false;
    await repo.retry();
    expect(protected.deletedRevisions, [2, 2, 2]);
    expectOnlyAuthority(local);
    expect(repo.forDate('2026-09-01'), isNull);
  });

  test('H1 already absent storage and repeated clear are idempotent', () async {
    final local = MemoryHydrionStore();
    final protected = _ObservedProtected(local)
      ..readFailure = ProtectedReadStatus.unavailable;
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    protected.readFailure = null;
    await repo.retry();
    await repo.clear();
    expect(protected.deletedRevisions, [1, 1]);
    expect(repo.isKnown, isTrue);
    expectOnlyAuthority(local);
  });

  test('H1 legacy revision-bearing intent still suppresses active truth',
      () async {
    final local = MemoryHydrionStore({
      intentKey: jsonEncode({'schemaVersion': 1, 'revision': 9})
    });
    final protected = _ObservedProtected(local)
      ..record = ProtectedContextRecord(
          revision: 8,
          phase: ContextRecordPhase.active,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(protected.deletedRevisions, [9]);
    expect(repo.forDate('2026-09-01'), isNull);
    expect(repo.isKnown, isTrue);
    expectOnlyAuthority(local);
  });

  test('conflicting provisional history is preserved instead of guessed',
      () async {
    final local = MemoryHydrionStore({sourceKey: legacy()});
    final protected = MemoryProtectedAppStore()
      ..record = ProtectedContextRecord(
          revision: 1,
          phase: ContextRecordPhase.provisional,
          contexts: [_context(2)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.corrupt);
    expect(protected.writes, 0);
    expect(protected.record!.contexts.single.localDateKey, '2026-09-02');
    expect(local.snapshot[sourceKey], legacy());
  });

  for (final raw in [
    '{',
    '{"schemaVersion":99,"contexts":[]}',
    '{"contexts":[]}',
    '{"schemaVersion":1,"contexts":[{}]}'
  ]) {
    test('invalid or unversioned source is quarantined: $raw', () async {
      final local = MemoryHydrionStore({sourceKey: raw});
      final protected = MemoryProtectedAppStore();
      final repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      expect(
          repo.status,
          raw.contains('99')
              ? DailyContextStatus.unsupported
              : DailyContextStatus.corrupt);
      expect(protected.writes, 0);
      expect(local.snapshot[sourceKey], raw);
    });
  }

  test('unsupported storage preserves source and cannot persist edits',
      () async {
    final local = MemoryHydrionStore({sourceKey: legacy()});
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: const UnavailableProtectedAppStore());
    expect(repo.status, DailyContextStatus.unsupported);
    expect(await repo.save(_context(2)), isFalse);
    expect(local.snapshot[sourceKey], legacy());
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(local.snapshot[sourceKey], legacy());
  });

  test('concurrent facade writes serialize and retain all days', () async {
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(
        MemoryHydrionStore(),
        protectedStore: protected);
    expect(
        await Future.wait(List.generate(20, (i) => repo.save(_context(i + 1)))),
        everyElement(isTrue));
    expect(protected.record!.contexts, hasLength(14));
    expect(protected.record!.revision, 21);
  });
}

DailyHydrationContext _context(int day) => DailyHydrationContext(
    localDateKey: '2026-09-${day.toString().padLeft(2, '0')}',
    temporaryCondition: HydrionTemporaryCondition.fever,
    activityMinutes: 30,
    updatedAt: DateTime.utc(2026, 9, day));

class _Local extends MemoryHydrionStore {
  _Local([super.values]);
  bool rejectRemoval = false, rejectWrite = false;
  @override
  Future<bool> removeAcknowledged(String key) async =>
      rejectRemoval ? false : super.removeAcknowledged(key);
  @override
  Future<bool> writeString(String key, String value) async =>
      rejectWrite ? false : super.writeString(key, value);
}

class _RejectActivation extends MemoryProtectedAppStore {
  bool reject = true;
  @override
  Future<ProtectedWriteStatus> writeDailyContext(
          ProtectedContextRecord value) =>
      reject && value.phase == ContextRecordPhase.active
          ? Future.value(ProtectedWriteStatus.failed)
          : super.writeDailyContext(value);
}

class _ObservedProtected extends MemoryProtectedAppStore {
  _ObservedProtected(this.local);
  final MemoryHydrionStore local;
  bool observing = false, throwRead = false;
  final readIntents = <bool>[];
  final deletedRevisions = <int>[];
  @override
  Future<ProtectedContextRead> readDailyContext() async {
    if (observing) {
      readIntents.add(local.snapshot
          .containsKey(DailyHydrationContextRepository.deletionKey));
    }
    if (throwRead) {
      throw StateError('SYNTHETIC sensitive context must not escape');
    }
    return super.readDailyContext();
  }

  @override
  Future<ProtectedDeleteStatus> deleteDailyContext(int revision) {
    deletedRevisions.add(revision);
    return super.deleteDailyContext(revision);
  }
}
