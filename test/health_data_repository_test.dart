import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/health_data_repository.dart';

void main() {
  group('memory health repository transaction contract', () {
    test('atomically commits a record and checkpoint', () async {
      final repository = MemoryHealthDataRepository();
      final checkpoint = _checkpoint(cursor: 'next');

      await repository.commitImport(
        records: [_record()],
        checkpoint: checkpoint,
      );

      expect(await repository.records(), hasLength(1));
      expect(
        (await repository.checkpointFor(
          'health-connect',
          HealthMetric.workout,
        ))
            ?.cursor,
        'next',
      );
    });

    test('replayed provider identity is an idempotent upsert', () async {
      final repository = MemoryHealthDataRepository();
      await repository.commitImport(
        records: [_record(value: 20)],
        checkpoint: _checkpoint(cursor: 'one'),
      );
      await repository.commitImport(
        records: [_record(value: 25, syncVersion: '2')],
        checkpoint: _checkpoint(cursor: 'two'),
      );

      final records = await repository.records();
      expect(records, hasLength(1));
      expect(records.single.value, 25);
      expect(records.single.synchronizationVersion, '2');
    });

    test('invalid batch rolls back records and checkpoint', () async {
      final repository = MemoryHealthDataRepository();
      await repository.commitImport(
        records: [_record()],
        checkpoint: _checkpoint(cursor: 'safe'),
      );

      await expectLater(
        repository.commitImport(
          records: [_record(providerId: 'wrong-provider')],
          checkpoint: _checkpoint(cursor: 'unsafe'),
        ),
        throwsFormatException,
      );

      expect(await repository.records(), hasLength(1));
      expect(
        (await repository.checkpointFor(
          'health-connect',
          HealthMetric.workout,
        ))
            ?.cursor,
        'safe',
      );
    });

    test('tombstones hide deleted records while retaining audit state',
        () async {
      final repository = MemoryHealthDataRepository();
      await repository.commitImport(
        records: [_record()],
        checkpoint: _checkpoint(cursor: 'one'),
      );
      await repository.commitImport(
        records: [_record(isDeleted: true, syncVersion: '2')],
        checkpoint: _checkpoint(cursor: 'two'),
      );

      expect(await repository.records(), isEmpty);
      expect(
        await repository.records(includeDeleted: true),
        hasLength(1),
      );
    });

    test('provider deletion and retention purge are bounded', () async {
      final repository = MemoryHealthDataRepository();
      await repository.commitImport(
        records: [_record()],
        checkpoint: _checkpoint(cursor: 'one'),
      );

      expect(
        await repository.purgeBefore(DateTime.utc(2026, 9, 12)),
        1,
      );
      expect(await repository.records(), isEmpty);

      await repository.commitImport(
        records: [_record()],
        checkpoint: _checkpoint(cursor: 'two'),
      );
      expect(await repository.deleteImportedProvider('health-connect'), 1);
      expect(
        await repository.checkpointFor(
          'health-connect',
          HealthMetric.workout,
        ),
        isNull,
      );
    });
  });
}

HealthSyncCheckpoint _checkpoint({required String cursor}) {
  return HealthSyncCheckpoint(
    providerId: 'health-connect',
    metric: HealthMetric.workout,
    cursor: cursor,
    historyStart: DateTime.utc(2026, 8, 12),
    lastSuccessfulSync: DateTime.utc(2026, 9, 11),
  );
}

CanonicalHealthRecord _record({
  double value = 20,
  String providerId = 'health-connect',
  String syncVersion = '1',
  bool isDeleted = false,
}) {
  return CanonicalHealthRecord(
    id: 'record-1',
    providerId: providerId,
    externalRecordId: 'external-1',
    synchronizationVersion: syncVersion,
    metric: HealthMetric.workout,
    semanticId: 'exercise.session.duration',
    value: value,
    unit: HealthUnit.minute,
    startTime: DateTime.utc(2026, 9, 11, 10),
    endTime: DateTime.utc(2026, 9, 11, 10, 20),
    ingestedAt: DateTime.utc(2026, 9, 11, 12),
    shape: HealthRecordShape.interval,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: const HealthProvenance(
      sourcePlatform: 'android',
      sourceApplicationId: 'com.vendor.health',
      physicalDeviceId: 'watch-42',
      acquisitionRoute: HealthAcquisitionRoute.healthConnect,
      entryMethod: HealthEntryMethod.sensor,
    ),
    isDeleted: isDeleted,
  );
}
