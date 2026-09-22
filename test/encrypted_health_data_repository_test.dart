import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/encrypted_health_data_repository.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory directory;
  late String path;
  final key = Uint8List.fromList(List<int>.generate(32, (index) => index + 1));

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hydrion-health-');
    path = '${directory.path}/health.db';
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test('creates an encrypted database and reopens all canonical fields',
      () async {
    var repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    final record = _record(
      id: 'full',
      originalUnit: HealthUnit.hour,
      unit: HealthUnit.minute,
      providerMetadata: const {'providerDataType': 'ExerciseSession'},
    );
    await repository.commitImport(
      records: [record],
      checkpoint: _checkpoint('one'),
    );
    await repository.close();

    final header = await File(path).openRead(0, 16).fold<List<int>>(
      <int>[],
      (bytes, part) => bytes..addAll(part),
    );
    expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));

    repository = await EncryptedHealthDataRepository.open(path: path, key: key);
    final reopened = (await repository.records()).single;
    expect(reopened.originalUnit, HealthUnit.hour);
    expect(reopened.unit, HealthUnit.minute);
    expect(reopened.temporalPrecision, HealthTemporalPrecision.minute);
    expect(reopened.sourceTimeZone, 'America/Toronto');
    expect(reopened.createdAt, DateTime.utc(2026, 9, 10, 9));
    expect(reopened.modifiedAt, DateTime.utc(2026, 9, 11, 9));
    expect(reopened.providerMetadata, {'providerDataType': 'ExerciseSession'});
    expect(
        (await repository.checkpointFor('test-provider', HealthMetric.workout))
            ?.cursor,
        'one');
    await repository.close();
  });

  test('rejects a wrong key without replacing the database', () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.commitImport(
      records: [_record(id: 'protected')],
      checkpoint: _checkpoint('safe'),
    );
    await repository.close();
    final before = await File(path).readAsBytes();

    await expectLater(
      EncryptedHealthDataRepository.open(
        path: path,
        key: Uint8List.fromList(List<int>.filled(32, 200)),
      ),
      throwsA(isA<HealthRepositoryOpenException>()),
    );
    expect(await File(path).readAsBytes(), before);
  });

  test('record and checkpoint rollback together after injected failure',
      () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
      failureInjector: (stage) async {
        if (stage == HealthRepositoryWriteStage.beforeCheckpoint) {
          throw StateError('simulated low disk');
        }
      },
    );

    await expectLater(
      repository.commitImport(
        records: [_record(id: 'rollback')],
        checkpoint: _checkpoint('must-not-advance'),
      ),
      throwsStateError,
    );
    expect(await repository.records(), isEmpty);
    expect(
      await repository.checkpointFor('test-provider', HealthMetric.workout),
      isNull,
    );
    await repository.close();
  });

  test('upserts idempotently and retains tombstones', () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.commitImport(
      records: [_record(id: 'same', value: 20)],
      checkpoint: _checkpoint('one'),
    );
    await repository.commitImport(
      records: [_record(id: 'same', value: 35, syncVersion: '2')],
      checkpoint: _checkpoint('two'),
    );
    expect((await repository.records()).single.value, 35);

    await repository.commitImport(
      records: [_record(id: 'same', isDeleted: true, syncVersion: '3')],
      checkpoint: _checkpoint('three'),
    );
    expect(await repository.records(), isEmpty);
    expect(await repository.records(includeDeleted: true), hasLength(1));
    await repository.close();
  });

  test('enforces bounded paging and stable ordering', () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.commitImport(
      records: List.generate(7, (index) => _record(id: 'record-$index')),
      checkpoint: _checkpoint('page'),
    );
    expect(
      (await repository.records(limit: 3, offset: 3)).map((r) => r.id),
      ['record-3', 'record-4', 'record-5'],
    );
    await expectLater(repository.records(limit: 1001), throwsRangeError);
    await repository.close();
  });

  test('provider deletion cascades through derived records and is idempotent',
      () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.commitImport(
      records: [
        _record(id: 'imported'),
        _record(
          id: 'derived',
          valueOrigin: HealthValueOrigin.hydrionDerived,
          algorithmVersion: 'test-v1',
          contributingRecordIds: const ['imported'],
        ),
        _record(
            id: 'derived-next',
            valueOrigin: HealthValueOrigin.hydrionDerived,
            algorithmVersion: 'test-v1',
            contributingRecordIds: const ['derived']),
      ],
      checkpoint: _checkpoint('delete'),
    );
    expect(await repository.deleteImportedProvider('test-provider'), 3);
    expect(await repository.deleteImportedProvider('test-provider'), 0);
    expect(await repository.records(), isEmpty);
    expect(
        await repository.checkpointFor('test-provider', HealthMetric.workout),
        isNull);
    await repository.close();
    final reopened =
        await EncryptedHealthDataRepository.open(path: path, key: key);
    expect(await reopened.records(), isEmpty);
    expect(await reopened.checkpointFor('test-provider', HealthMetric.workout),
        isNull);
    await reopened.close();
  });

  test('failed cascade rolls records and checkpoints back across reopen',
      () async {
    final repository = await EncryptedHealthDataRepository.open(
        path: path,
        key: key,
        failureInjector: (stage) async {
          if (stage == HealthRepositoryWriteStage.recordsDeleted) {
            throw StateError('synthetic failure');
          }
        });
    await repository.commitImport(records: [
      _record(id: 'imported'),
      _record(
          id: 'derived',
          valueOrigin: HealthValueOrigin.hydrionDerived,
          algorithmVersion: 'v1',
          contributingRecordIds: const ['imported']),
    ], checkpoint: _checkpoint('retained'));
    await expectLater(
        repository.deleteImportedProvider('test-provider'), throwsStateError);
    await expectLater(repository.deleteAllWearableData(), throwsStateError);
    await repository.close();
    final reopened =
        await EncryptedHealthDataRepository.open(path: path, key: key);
    expect(await reopened.records(), hasLength(2));
    expect(
        (await reopened.checkpointFor('test-provider', HealthMetric.workout))!
            .cursor,
        'retained');
    await reopened.deleteAllWearableData();
    await reopened.deleteAllWearableData();
    expect(await reopened.records(), isEmpty);
    expect(await reopened.checkpointFor('test-provider', HealthMetric.workout),
        isNull);
    await reopened.close();
  });

  test('serializes concurrent commits without losing records', () async {
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await Future.wait(List.generate(20, (index) {
      return repository.commitImport(
        records: [_record(id: 'concurrent-$index')],
        checkpoint: _checkpoint('cursor-$index'),
      );
    }));
    expect(await repository.records(limit: 20), hasLength(20));
    await repository.close();
  });

  test('detects corrupt files and close is idempotent', () async {
    await File(path).writeAsBytes(List<int>.generate(256, (index) => index));
    await expectLater(
      EncryptedHealthDataRepository.open(path: path, key: key),
      throwsA(isA<HealthRepositoryOpenException>()),
    );

    await File(path).delete();
    final repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.close();
    await repository.close();
    await expectLater(repository.records(), throwsStateError);
  });

  test('initialization is idempotent and rejects future schemas', () async {
    var repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    await repository.close();
    repository = await EncryptedHealthDataRepository.open(path: path, key: key);
    await repository.close();

    final raw = sqlite.sqlite3.open(path);
    final hex =
        key.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    raw.execute('PRAGMA key = "x\'$hex\'"');
    raw.execute('PRAGMA user_version = 999');
    raw.close();

    await expectLater(
      EncryptedHealthDataRepository.open(path: path, key: key),
      throwsA(
        isA<HealthRepositoryOpenException>().having(
          (error) => error.status,
          'status',
          HealthRepositoryOpenStatus.unsupportedSchema,
        ),
      ),
    );
  });

  test('synchronization semantics hold against encrypted persistence',
      () async {
    var repository = await EncryptedHealthDataRepository.open(
      path: path,
      key: key,
    );
    final provider = _PersistentTestProvider(_record(id: 'synced'));
    final result = await HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
    ).synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.workout},
    );
    expect(result.status, HealthSyncStatus.success);
    await repository.close();

    repository = await EncryptedHealthDataRepository.open(path: path, key: key);
    expect((await repository.records()).single.id, 'synced');
    expect(
      (await repository.checkpointFor(
        provider.providerId,
        HealthMetric.workout,
      ))
          ?.cursor,
      'persisted',
    );
    await repository.close();
  });
}

class _PersistentTestProvider implements HealthDataProvider {
  final CanonicalHealthRecord record;

  _PersistentTestProvider(this.record);

  @override
  String get providerId => 'test-provider';

  @override
  Future<HealthProviderAvailability> availability() async =>
      const HealthProviderAvailability(
        HealthProviderAvailabilityStatus.available,
      );

  @override
  Future<HealthAuthorizationState> authorizationState(
    Set<HealthMetric> metrics,
  ) async =>
      const HealthAuthorizationState(
        status: HealthPermissionStatus.granted,
        grantedMetrics: {HealthMetric.workout},
      );

  @override
  Future<HealthProviderCapabilities> capabilities() async =>
      const HealthProviderCapabilities(
        readableMetrics: {HealthMetric.workout},
        supportsIncrementalChanges: true,
        supportsDeletions: true,
        supportsBackgroundReads: false,
      );

  @override
  Future<HealthAuthorizationState> requestReadAccess(
    Set<HealthMetric> metrics,
  ) =>
      authorizationState(metrics);

  @override
  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint) async {
    return HealthImportPage(
      records: [record],
      nextCheckpoint: HealthSyncCheckpoint(
        providerId: providerId,
        metric: HealthMetric.workout,
        cursor: 'persisted',
        historyStart: checkpoint.historyStart,
        lastSuccessfulSync: DateTime.utc(2026, 9, 11, 12),
      ),
    );
  }
}

HealthSyncCheckpoint _checkpoint(String cursor) => HealthSyncCheckpoint(
      providerId: 'test-provider',
      metric: HealthMetric.workout,
      cursor: cursor,
      historyStart: DateTime.utc(2026, 8, 12),
      lastSuccessfulSync: DateTime.utc(2026, 9, 11, 12),
    );

CanonicalHealthRecord _record({
  required String id,
  double value = 30,
  String syncVersion = '1',
  bool isDeleted = false,
  HealthUnit originalUnit = HealthUnit.minute,
  HealthUnit unit = HealthUnit.minute,
  HealthValueOrigin valueOrigin = HealthValueOrigin.rawSensor,
  String? algorithmVersion,
  List<String> contributingRecordIds = const [],
  Map<String, String> providerMetadata = const {},
}) =>
    CanonicalHealthRecord(
      id: id,
      providerId: 'test-provider',
      externalRecordId: id,
      synchronizationVersion: syncVersion,
      metric: HealthMetric.workout,
      semanticId: 'exercise.session.duration',
      value: value,
      originalUnit: originalUnit,
      unit: unit,
      startTime: DateTime.utc(2026, 9, 11, 10),
      endTime: DateTime.utc(2026, 9, 11, 10, 30),
      sourceTimeZone: 'America/Toronto',
      sourceUtcOffset: const Duration(hours: -4),
      temporalPrecision: HealthTemporalPrecision.minute,
      recordedAt: DateTime.utc(2026, 9, 11, 10, 31),
      createdAt: DateTime.utc(2026, 9, 10, 9),
      modifiedAt: DateTime.utc(2026, 9, 11, 9),
      ingestedAt: DateTime.utc(2026, 9, 11, 12),
      shape: HealthRecordShape.interval,
      aggregationMethod: 'provider-session',
      valueOrigin: valueOrigin,
      provenance: const HealthProvenance(
        sourcePlatform: 'test',
        sourceApplicationId: 'test.app',
        sourceApplicationName: 'Test Health',
        physicalDeviceId: 'watch-42',
        manufacturer: 'Vendor',
        deviceModel: 'Watch',
        deviceHardwareVersion: '2',
        deviceSoftwareVersion: '3',
        acquisitionRoute: HealthAcquisitionRoute.test,
        entryMethod: HealthEntryMethod.sensor,
      ),
      quality: 'verified',
      isDeleted: isDeleted,
      algorithmVersion: algorithmVersion,
      contributingRecordIds: contributingRecordIds,
      providerMetadata: providerMetadata,
    );
