import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/services/sensitive_body_metrics_store.dart';
import 'package:hydrion/storage/local_store.dart';

// Synthetic SEC-001 fixtures; native protection requires separate certification.
const sample = HydrionBodyMetrics(
  personalizationEnabled: true,
  weightKg: 83.625,
  heightCm: 176.375,
  reproductiveState: HydrionReproductiveHydrationState.pregnant,
  pregnancyGestationalDays: 193,
  fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
  clinicianTargetMl: 2375,
  allowAdjustmentsAboveClinicianTarget: true,
  wakeMinuteOfDay: 427,
  sleepMinuteOfDay: 1327,
);
final stamp = DateTime.utc(2025, 7, 19, 13, 47, 23);

void expectNoPayload(MemoryHydrionStore local) {
  final serialized = jsonEncode(local.snapshot);
  for (final value in [
    '83.625',
    '176.375',
    'pregnant',
    '193',
    '2375',
    'clinicianTarget',
    '427',
    '1327',
    '2025-07-19',
  ]) {
    expect(serialized, isNot(contains(value)), reason: 'plaintext $value');
  }
  final raw = local.snapshot[BodyMetricsRepository.storageKey];
  if (raw != null) {
    final fields = jsonDecode(raw) as Map;
    for (final key in sample.toJson().keys.where(
        (key) => key != 'schemaVersion' && !key.startsWith('preferred'))) {
      expect(fields.containsKey(key), isFalse, reason: 'plaintext field $key');
    }
  }
}

void main() {
  for (final failure in ['write', 'unsupported', 'readback']) {
    test('$failure cannot persist a new sensitive plaintext payload', () async {
      final local = MemoryHydrionStore();
      final secure = ControlledBodyStore(supported: failure != 'unsupported');
      final repo = await BodyMetricsRepository.load(local, secureStore: secure);
      secure.failWrite = failure == 'write';
      secure.failRead = failure == 'readback';
      final saved = await repo.save(sample, femaleProfile: true, now: stamp);
      // Inspect bytes before asserting the result: this reproduces the leak.
      expectNoPayload(local);
      expect(saved, isFalse);
      expect(repo.state.revision, 0);
    });
  }

  test(
      'successful save protects routines and timestamps as well as clinical data',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(await repo.save(sample, femaleProfile: true, now: stamp), isTrue);
    expectNoPayload(local);
    final stored = (await secure.read())!;
    expect(stored['wakeMinuteOfDay'], 427);
    expect(stored['updatedAt'], stamp.toIso8601String());
    final restarted =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(restarted.metrics.toJson(), repo.metrics.toJson());
    expectNoPayload(local);
  });

  test('secure outage after a saved value never publishes a new plaintext edit',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(sample, femaleProfile: true, now: stamp);
    final before = local.snapshot;
    secure.failWrite = true;
    expect(await repo.update(weightKg: 84.625, femaleProfile: true), isFalse);
    expect(local.snapshot, before);
    expect(repo.state.isKnown, isFalse);
    expect(repo.state.revision, 1);
    secure.failWrite = false;
    await repo.reload();
    expect(repo.metrics.weightKg, sample.weightKg);
    expect(await repo.update(weightKg: 84.625, femaleProfile: true), isTrue);
    expect(local.snapshot.toString(), isNot(contains('84.625')));
    expect((await secure.read())!['weightKg'], 84.625);
  });

  for (final fault in ['write', 'read', 'unsupported']) {
    test('legacy pending survives $fault unchanged and read-only', () async {
      final raw = jsonEncode({
        ...sample.toJson(),
        '_bodyAuthority': {'version': 1, 'revision': 8, 'pending': true},
      });
      final local = MemoryHydrionStore({BodyMetricsRepository.storageKey: raw});
      final secure = ControlledBodyStore(supported: fault != 'unsupported')
        ..failRead = fault == 'read'
        ..failWrite = fault == 'write';
      for (var restart = 0; restart < 2; restart++) {
        final repo =
            await BodyMetricsRepository.load(local, secureStore: secure);
        expect(repo.metrics.weightKg, sample.weightKg);
        expect(repo.canSave, isFalse);
        expect(await repo.update(weightKg: 90, femaleProfile: true), isFalse);
        expect(local.snapshot[BodyMetricsRepository.storageKey], raw);
        expect(repo.state.revision, 8);
      }
    });
  }

  test(
      'legacy newer pending is verified before stripping then restart is idempotent',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final first = await BodyMetricsRepository.load(local, secureStore: secure);
    await first.save(sample.copyWith(weightKg: 60),
        femaleProfile: true, now: stamp);
    final legacy = jsonEncode({
      ...sample.copyWith(updatedAt: stamp).toJson(),
      '_bodyAuthority': {'version': 1, 'revision': 8, 'pending': true},
    });
    await local.writeString(BodyMetricsRepository.storageKey, legacy);
    secure.beforeWrite = () {
      expect(local.snapshot[BodyMetricsRepository.storageKey], legacy);
    };
    final recovered =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(recovered.state.status, BodyMetricsStatus.available);
    expect(recovered.state.revision, 8);
    expect(recovered.metrics.weightKg, sample.weightKg);
    expectNoPayload(local);
    final after = local.snapshot;
    secure.beforeWrite = null;
    await recovered.reload();
    expect(local.snapshot, after);
    expect(recovered.metrics.wakeMinuteOfDay, 427);
  });

  test('legacy core-only secure schema promotes routines before stripping',
      () async {
    final fields = <String, Object?>{
      ...sample.toJson(),
      '_bodyRevision': 4,
    };
    for (final key in [
      'personalizationEnabled',
      'wakeMinuteOfDay',
      'sleepMinuteOfDay',
      'updatedAt',
      'weightUpdatedAt',
      'heightUpdatedAt',
      'schemaVersion',
      'preferredWeightUnit',
      'preferredHeightUnit',
      'preferredPregnancyDurationUnit'
    ]) {
      fields.remove(key);
    }
    final local = MemoryHydrionStore({
      BodyMetricsRepository.storageKey: jsonEncode({
        ...sample.copyWith(updatedAt: stamp).toJson(),
        'weightKg': null,
        'heightCm': null,
        'reproductiveState': 'none',
        'pregnancyGestationalDays': null,
        'fluidSafetyMode': 'none',
        'clinicianTargetMl': null,
        'allowAdjustmentsAboveClinicianTarget': false,
        '_bodyAuthority': {'version': 1, 'revision': 4, 'pending': false},
      })
    });
    final secure = ControlledBodyStore();
    await secure.write(fields);
    final before = local.snapshot;
    secure.failWrite = true;
    final failed = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(failed.canSave, isFalse);
    expect(local.snapshot, before);
    secure.failWrite = false;
    await failed.reload();
    expect(failed.metrics.weightKg, sample.weightKg);
    expect(failed.metrics.wakeMinuteOfDay, 427);
    expect(failed.metrics.updatedAt, stamp);
    expect((await secure.read())!['_bodySchema'], 2);
    expectNoPayload(local);
  });

  test('local acknowledgement failure cannot advance published authority',
      () async {
    final local = RejectingBodyPreferences();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    local.reject = true;
    expect(await repo.save(sample, femaleProfile: true, now: stamp), isFalse);
    expect(repo.state.revision, 0);
    expect(repo.state.value, isNull);
    expect(local.snapshot, isEmpty);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.localWriteFailed);
    local.reject = false;
    await repo.reload();
    expect(repo.metrics.weightKg, sample.weightKg);
    expect(repo.state.revision, 1);
    expectNoPayload(local);
  });

  test('silent secure no-op fails verification without plaintext fallback',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    secure.ignoreWrite = true;
    expect(await repo.save(sample, femaleProfile: true, now: stamp), isFalse);
    expect(repo.lastWriteStatus, BodyMetricsWriteStatus.verificationFailed);
    expectNoPayload(local);
    expect(repo.state.value, isNull);
  });

  test('legacy cleanup rejection preserves plaintext until verified retry',
      () async {
    final local = RejectingBodyPreferences();
    final legacy = jsonEncode({
      ...sample.toJson(),
      '_bodyAuthority': {'version': 1, 'revision': 8, 'pending': true},
    });
    await local.writeString(BodyMetricsRepository.storageKey, legacy);
    final secure = ControlledBodyStore();
    local.reject = true;
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    expect(repo.state.status, BodyMetricsStatus.pendingSecure);
    expect(repo.canSave, isFalse);
    expect(local.snapshot[BodyMetricsRepository.storageKey], legacy);
    expect((await secure.read())!['weightKg'], sample.weightKg);
    local.reject = false;
    await repo.reload();
    expect(repo.state.status, BodyMetricsStatus.available);
    expect(repo.metrics.weightKg, sample.weightKg);
    expectNoPayload(local);
  });

  test('future secure schema and stale core-only downgrade remain unavailable',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(sample, femaleProfile: true, now: stamp);
    final verified = (await secure.read())!;
    await secure.write({...verified, '_bodySchema': 99});
    final before = local.snapshot;
    await repo.reload();
    expect(repo.state.status, BodyMetricsStatus.corrupt);
    expect(local.snapshot, before);
    verified.remove('_bodySchema');
    await secure.write(verified);
    await repo.reload();
    expect(repo.state.status, BodyMetricsStatus.unavailable);
    expect(local.snapshot, before);
  });

  test('read failure and corrupt expanded schema never invent absent state',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore()..failRead = true;
    final unknown =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(unknown.state.isKnown, isFalse);
    expect(await unknown.save(sample, femaleProfile: true), isFalse);
    expect(local.snapshot, isEmpty);
    secure.failRead = false;
    await unknown.reload();
    await unknown.save(sample, femaleProfile: true, now: stamp);
    final malformed = (await secure.read())!..remove('wakeMinuteOfDay');
    await secure.write(malformed);
    final before = local.snapshot;
    await unknown.reload();
    expect(unknown.state.status, BodyMetricsStatus.corrupt);
    expect(local.snapshot, before);
    expect(unknown.wakeMinuteOfDay, isNull);
  });

  test(
      'deletion intent outranks secure data and blocks saves without payload metadata',
      () async {
    final local = MemoryHydrionStore();
    final secure = ControlledBodyStore();
    final repo = await BodyMetricsRepository.load(local, secureStore: secure);
    await repo.save(sample, femaleProfile: true, now: stamp);
    secure.failDelete = true;
    await expectLater(
        repo.clear(), throwsA(isA<BodyMetricsDeletionIncomplete>()));
    expectNoPayload(local);
    final restarted =
        await BodyMetricsRepository.load(local, secureStore: secure);
    expect(restarted.state.status, BodyMetricsStatus.deletionPending);
    expect(await restarted.save(sample, femaleProfile: true), isFalse);
    expect(restarted.state.toString(), 'BodyMetricsState(deletionPending)');
    secure.failDelete = false;
    await restarted.clear();
    await restarted.clear();
    expect(restarted.state.status, BodyMetricsStatus.absent);
    expect(await secure.read(), isNull);
    expectNoPayload(local);
  });
}

class ControlledBodyStore extends MemorySensitiveBodyMetricsStore {
  bool failWrite = false;
  bool ignoreWrite = false;
  bool failRead = false;
  bool failDelete = false;
  void Function()? beforeWrite;
  ControlledBodyStore({super.supported});
  @override
  Future<void> write(Map<String, Object?> fields) async {
    beforeWrite?.call();
    if (failWrite) throw StateError('synthetic write failure');
    if (ignoreWrite) return;
    await super.write(fields);
  }

  @override
  Future<SensitiveBodyRead> readResult() async =>
      failRead ? const SensitiveBodyRead.unavailable() : super.readResult();
  @override
  Future<SensitiveBodyDeleteStatus> delete() => failDelete
      ? Future.value(SensitiveBodyDeleteStatus.failed)
      : super.delete();
}

class RejectingBodyPreferences extends MemoryHydrionStore {
  bool reject = false;
  @override
  Future<bool> writeString(String key, String value) async =>
      reject ? false : super.writeString(key, value);
}
