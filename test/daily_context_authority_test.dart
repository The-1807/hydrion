import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/storage/protected_app_store.dart';

import 'support/memory_protected_app_store.dart';

/// Wave 0 D3: daily context carries a payload-free authority marker, and the
/// deletion intent is relied upon only after acknowledged write + readback.
void main() {
  const sourceKey = DailyHydrationContextRepository.storageKey;
  const intentKey = DailyHydrationContextRepository.deletionKey;
  const authorityKey = DailyHydrationContextRepository.authorityKey;

  test('marker key is the agreed name', () {
    expect(authorityKey, 'hydrion.daily_hydration_context.authority.v1');
  });

  test('migration writes the marker before stripping the legacy source',
      () async {
    final local = MemoryHydrionStore({sourceKey: _legacy()});
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.ready);
    expect(local.snapshot, {authorityKey: '1'});
    expect(repo.forDate('2026-09-01'), isNotNull);
  });

  test('protected DB loss after legacy cleanup is corrupt, never ready-empty',
      () async {
    final local = MemoryHydrionStore({sourceKey: _legacy()});
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: MemoryProtectedAppStore());
    expect(await repo.save(_context(2)), isTrue);
    expect(local.snapshot, {authorityKey: '2'});

    // Protected database lost/recreated: the record is simply absent.
    final reloaded = await DailyHydrationContextRepository.load(local,
        protectedStore: MemoryProtectedAppStore());
    expect(reloaded.status, DailyContextStatus.corrupt);
    expect(reloaded.isKnown, isFalse);
    expect(reloaded.forDate('2026-09-01'), isNull);
    // Nothing is migrated or written over the missing authority.
    expect(local.snapshot, {authorityKey: '2'});
  });

  test('marker newer than the protected record is corrupt', () async {
    final local = MemoryHydrionStore({authorityKey: '5'});
    final protected = MemoryProtectedAppStore()
      ..record = ProtectedContextRecord(
          revision: 4,
          phase: ContextRecordPhase.active,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.corrupt);
    expect(repo.forDate('2026-09-01'), isNull);
    expect(protected.writes, 0);
  });

  test('marker with a provisional protected record is corrupt', () async {
    final local = MemoryHydrionStore({authorityKey: '1', sourceKey: _legacy()});
    final protected = MemoryProtectedAppStore()
      ..record = ProtectedContextRecord(
          revision: 1,
          phase: ContextRecordPhase.provisional,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.corrupt);
    expect(local.snapshot[sourceKey], isNotNull);
  });

  for (final malformed in ['', 'x', '0', '-3']) {
    test('malformed marker "$malformed" is corrupt', () async {
      final local = MemoryHydrionStore({authorityKey: malformed});
      final protected = MemoryProtectedAppStore()
        ..record = ProtectedContextRecord(
            revision: 1, phase: ContextRecordPhase.active, contexts: const []);
      final repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      expect(repo.status, DailyContextStatus.corrupt);
    });
  }

  test('existing active record without marker gains it during cleanup',
      () async {
    final local = MemoryHydrionStore();
    final protected = MemoryProtectedAppStore()
      ..record = ProtectedContextRecord(
          revision: 3,
          phase: ContextRecordPhase.active,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.ready);
    expect(local.snapshot, {authorityKey: '3'});
    expect(repo.forDate('2026-09-01'), isNotNull);
  });

  test('a protected record ahead of the marker remains authoritative',
      () async {
    final local = MemoryHydrionStore({authorityKey: '2'});
    final protected = MemoryProtectedAppStore()
      ..record = ProtectedContextRecord(
          revision: 3,
          phase: ContextRecordPhase.active,
          contexts: [_context(1)]);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(repo.status, DailyContextStatus.ready);
    expect(local.snapshot, {authorityKey: '3'});
  });

  test('marker write failure keeps the legacy source and reports cleanup',
      () async {
    final raw = _legacy();
    final local = _DroppingStore({sourceKey: raw}, drop: authorityKey);
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: MemoryProtectedAppStore());
    expect(repo.status, DailyContextStatus.cleanupPending);
    expect(local.snapshot[sourceKey], raw);
    expect(local.snapshot.containsKey(authorityKey), isFalse);
  });

  test('deleted tombstone carries the marker across restart', () async {
    final local = MemoryHydrionStore({sourceKey: _legacy()});
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    await repo.clear();
    expect(repo.status, DailyContextStatus.ready);
    expect(protected.record!.phase, ContextRecordPhase.deleted);
    expect(local.snapshot, {authorityKey: '${protected.record!.revision}'});

    final reloaded = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(reloaded.status, DailyContextStatus.ready);
    expect(reloaded.forDate('2026-09-01'), isNull);

    final lost = await DailyHydrationContextRepository.load(local,
        protectedStore: MemoryProtectedAppStore());
    expect(lost.status, DailyContextStatus.corrupt);
  });

  test('deletion intent that does not read back performs no destruction',
      () async {
    final local = _DroppingStore({}, drop: intentKey);
    final protected = MemoryProtectedAppStore();
    final repo = await DailyHydrationContextRepository.load(local,
        protectedStore: protected);
    expect(await repo.save(_context(1)), isTrue);
    final before = protected.record;
    await expectLater(repo.clear(), throwsA(isA<DailyContextUnavailable>()));
    expect(identical(protected.record, before), isTrue);
    expect(protected.record!.phase, ContextRecordPhase.active);
    expect(local.snapshot.containsKey(intentKey), isFalse);
  });

  for (final intent in [
    {'schemaVersion': 2, 'pending': true},
    {'schemaVersion': 1, 'revision': 1},
  ]) {
    test('existing intent format $intent stays readable', () async {
      final local = MemoryHydrionStore({intentKey: jsonEncode(intent)});
      final protected = MemoryProtectedAppStore()
        ..record = ProtectedContextRecord(
            revision: 1,
            phase: ContextRecordPhase.active,
            contexts: [_context(1)]);
      final repo = await DailyHydrationContextRepository.load(local,
          protectedStore: protected);
      expect(repo.status, DailyContextStatus.ready);
      expect(repo.forDate('2026-09-01'), isNull);
      expect(protected.record!.phase, ContextRecordPhase.deleted);
      expect(local.snapshot, {authorityKey: '2'});
    });
  }
}

/// Acknowledges writes of [drop] without persisting them.
class _DroppingStore extends MemoryHydrionStore {
  final String drop;
  _DroppingStore(super.initialValues, {required this.drop});
  @override
  Future<bool> writeString(String key, String value) async =>
      key == drop ? true : super.writeString(key, value);
}

String _legacy() => jsonEncode({
      'schemaVersion': 1,
      'contexts': [_context(1).toJson()],
    });

DailyHydrationContext _context(int day) => DailyHydrationContext(
      localDateKey: '2026-09-${day.toString().padLeft(2, '0')}',
      activityIntensity: HydrionActivityIntensity.moderate,
      activityMinutes: 30,
      updatedAt: DateTime(2026, 9, day, 12),
    );
