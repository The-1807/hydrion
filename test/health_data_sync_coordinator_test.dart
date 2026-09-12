import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/health_data_repository.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';

void main() {
  group('health data synchronization coordinator', () {
    test('reports unregistered providers as unsupported', () async {
      final coordinator = HealthDataSyncCoordinator(
        providers: const [],
        repository: MemoryHealthDataRepository(),
      );

      final result = await coordinator.synchronize(
        providerId: 'unknown',
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.unsupported);
    });

    test('never requests permission without explicit user action', () async {
      final provider = _FakeHealthProvider();
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: MemoryHealthDataRepository(),
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
        requestPermission: true,
      );

      expect(result.status, HealthSyncStatus.permissionRequired);
      expect(provider.permissionRequestCount, 0);
    });

    test('imports after user permission and advances checkpoint', () async {
      final repository = MemoryHealthDataRepository();
      final provider = _FakeHealthProvider(
        authorization: const HealthAuthorizationState(
          status: HealthPermissionStatus.notRequested,
        ),
        requestedAuthorization: const HealthAuthorizationState(
          status: HealthPermissionStatus.granted,
          grantedMetrics: {HealthMetric.workout},
        ),
        pages: [
          _page([_record(id: 'one', externalId: 'external-one')])
        ],
      );
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
        clock: () => DateTime.utc(2026, 9, 11),
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
        requestPermission: true,
        userInitiated: true,
      );

      expect(result.status, HealthSyncStatus.success);
      expect(provider.permissionRequestCount, 1);
      expect(await repository.records(), hasLength(1));
      expect(
        (await repository.checkpointFor(
          provider.providerId,
          HealthMetric.workout,
        ))
            ?.cursor,
        'next',
      );
    });

    test('repeated synchronization upserts instead of duplicating', () async {
      final repository = MemoryHealthDataRepository();
      final record = _record(id: 'one', externalId: 'external-one');
      final provider = _FakeHealthProvider(pages: [
        _page([record]),
        _page([record]),
      ]);
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      );

      await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(await repository.records(), hasLength(1));
    });

    test('marks the same physical event from another route as duplicate',
        () async {
      final repository = MemoryHealthDataRepository();
      final provider = _FakeHealthProvider(pages: [
        _page([
          _record(id: 'hub', externalId: 'hub-id'),
          _record(
            id: 'cloud',
            externalId: 'cloud-id',
            sourceApp: 'vendor-cloud',
            route: HealthAcquisitionRoute.vendorCloud,
          ),
        ]),
      ]);
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.duplicateCount, 1);
      expect(await repository.records(), hasLength(1));
      expect(
        await repository.records(includeDuplicates: true),
        hasLength(2),
      );
    });

    test('recovers an expired checkpoint with bounded initial reread',
        () async {
      final repository = MemoryHealthDataRepository();
      final provider = _FakeHealthProvider(pages: [
        _page(const [], expired: true),
        _page([_record(id: 'one', externalId: 'external-one')]),
      ]);
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
        clock: () => DateTime.utc(2026, 9, 11),
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.success);
      expect(provider.receivedCheckpoints, hasLength(2));
      expect(
        provider.receivedCheckpoints.last.historyStart,
        DateTime.utc(2026, 8, 12),
      );
    });

    test('repository failure does not falsely report success', () async {
      final provider = _FakeHealthProvider(
        pages: [
          _page([_record(id: 'one', externalId: 'external-one')])
        ],
      );
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: _FailingRepository(),
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.failed);
      expect(result.reasonCode, 'provider_or_repository_failure');
    });

    test('empty provider history is a successful zero-record synchronization',
        () async {
      final result = await HealthDataSyncCoordinator(
        providers: [_FakeHealthProvider()],
        repository: MemoryHealthDataRepository(),
      ).synchronize(
        providerId: 'test-provider',
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.success);
      expect(result.importedCount, 0);
    });

    test('cancellation stops before provider reads or checkpoint changes',
        () async {
      final provider = _FakeHealthProvider(
        pages: [
          _page([_record(id: 'never', externalId: 'never')]),
        ],
      );
      final repository = MemoryHealthDataRepository();
      final result = await HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      ).synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
        isCancelled: () => true,
      );

      expect(result.status, HealthSyncStatus.cancelled);
      expect(provider.receivedCheckpoints, isEmpty);
      expect(await repository.records(), isEmpty);
    });

    test('malformed provider records fail without advancing the checkpoint',
        () async {
      final provider = _FakeHealthProvider(
        pages: [
          _page([
            _record(id: 'invalid', externalId: 'invalid', value: double.nan),
          ]),
        ],
      );
      final repository = MemoryHealthDataRepository();
      final result = await HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      ).synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.failed);
      expect(
        await repository.checkpointFor(
          provider.providerId,
          HealthMetric.workout,
        ),
        isNull,
      );
    });

    test('permission revocation pauses import and preserves existing data',
        () async {
      final repository = MemoryHealthDataRepository();
      await repository.commitImport(
        records: [_record(id: 'existing', externalId: 'existing-id')],
        checkpoint: HealthSyncCheckpoint(
          providerId: 'test-provider',
          metric: HealthMetric.workout,
          cursor: 'before-revocation',
          historyStart: DateTime.utc(2026, 8, 12),
        ),
      );
      final provider = _FakeHealthProvider(
        authorization: const HealthAuthorizationState(
          status: HealthPermissionStatus.revoked,
        ),
      );
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      );

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.permissionDenied);
      expect(await repository.records(), hasLength(1));
      expect(provider.receivedCheckpoints, isEmpty);
    });

    test('permission denial returns a distinct state without reading data',
        () async {
      final provider = _FakeHealthProvider(
        authorization: const HealthAuthorizationState(
          status: HealthPermissionStatus.denied,
        ),
      );
      final result = await HealthDataSyncCoordinator(
        providers: [provider],
        repository: MemoryHealthDataRepository(),
      ).synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );

      expect(result.status, HealthSyncStatus.permissionDenied);
      expect(provider.receivedCheckpoints, isEmpty);
    });

    test('provider corrections and tombstones reconcile by stable identity',
        () async {
      final repository = MemoryHealthDataRepository();
      final original = _record(id: 'one', externalId: 'external-one');
      final corrected = _record(
        id: 'one',
        externalId: 'external-one',
        value: 45,
        synchronizationVersion: '2',
      );
      final deleted = _record(
        id: 'one',
        externalId: 'external-one',
        value: 45,
        synchronizationVersion: '3',
        isDeleted: true,
      );
      final provider = _FakeHealthProvider(pages: [
        _page([original]),
        _page([corrected]),
        _page([deleted]),
      ]);
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      );

      await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      expect((await repository.records()).single.value, 45);

      final result = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      expect(result.deletedCount, 1);
      expect(await repository.records(), isEmpty);
      expect(await repository.records(includeDeleted: true), hasLength(1));
    });

    test('a failed transaction can be retried without duplicate state',
        () async {
      final provider = _FakeHealthProvider(pages: [
        _page([_record(id: 'one', externalId: 'external-one')]),
      ]);
      final repository = _FailOnceRepository();
      final coordinator = HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      );

      final failed = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      expect(failed.status, HealthSyncStatus.failed);
      expect(await repository.records(), isEmpty);

      provider.pages.add(
        _page([_record(id: 'one', externalId: 'external-one')]),
      );
      final retried = await coordinator.synchronize(
        providerId: provider.providerId,
        metrics: {HealthMetric.workout},
      );
      expect(retried.status, HealthSyncStatus.success);
      expect(await repository.records(), hasLength(1));
    });
  });
}

class _FakeHealthProvider implements HealthDataProvider {
  final HealthAuthorizationState authorization;
  final HealthAuthorizationState requestedAuthorization;
  final List<HealthImportPage> pages;
  int permissionRequestCount = 0;
  final List<HealthSyncCheckpoint> receivedCheckpoints = [];

  _FakeHealthProvider({
    this.authorization = const HealthAuthorizationState(
      status: HealthPermissionStatus.granted,
      grantedMetrics: {HealthMetric.workout},
    ),
    this.requestedAuthorization = const HealthAuthorizationState(
      status: HealthPermissionStatus.granted,
      grantedMetrics: {HealthMetric.workout},
    ),
    this.pages = const [],
  });

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
      authorization;

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
  ) async {
    permissionRequestCount += 1;
    return requestedAuthorization;
  }

  @override
  Future<HealthImportPage> readChanges(HealthSyncCheckpoint checkpoint) async {
    receivedCheckpoints.add(checkpoint);
    if (pages.isEmpty) return _page(const []);
    return pages.removeAt(0);
  }
}

class _FailingRepository extends MemoryHealthDataRepository {
  @override
  Future<void> commitImport({
    required List<CanonicalHealthRecord> records,
    required HealthSyncCheckpoint checkpoint,
  }) {
    throw StateError('simulated write failure');
  }
}

class _FailOnceRepository extends MemoryHealthDataRepository {
  bool _shouldFail = true;

  @override
  Future<void> commitImport({
    required List<CanonicalHealthRecord> records,
    required HealthSyncCheckpoint checkpoint,
  }) async {
    if (_shouldFail) {
      _shouldFail = false;
      throw StateError('simulated interrupted transaction');
    }
    await super.commitImport(records: records, checkpoint: checkpoint);
  }
}

HealthImportPage _page(
  List<CanonicalHealthRecord> records, {
  bool expired = false,
}) {
  return HealthImportPage(
    records: records,
    nextCheckpoint: HealthSyncCheckpoint(
      providerId: 'test-provider',
      metric: HealthMetric.workout,
      cursor: 'next',
      historyStart: DateTime.utc(2026, 8, 12),
      lastSuccessfulSync: DateTime.utc(2026, 9, 11),
    ),
    checkpointExpired: expired,
  );
}

CanonicalHealthRecord _record({
  required String id,
  required String externalId,
  String sourceApp = 'vendor-health-app',
  HealthAcquisitionRoute route = HealthAcquisitionRoute.healthConnect,
  double value = 30,
  String synchronizationVersion = '1',
  bool isDeleted = false,
}) {
  return CanonicalHealthRecord(
    id: id,
    providerId: 'test-provider',
    externalRecordId: externalId,
    synchronizationVersion: synchronizationVersion,
    metric: HealthMetric.workout,
    semanticId: 'exercise.session.duration',
    value: value,
    unit: HealthUnit.minute,
    startTime: DateTime.utc(2026, 9, 11, 10),
    endTime: DateTime.utc(2026, 9, 11, 10, 30),
    ingestedAt: DateTime.utc(2026, 9, 11, 12),
    shape: HealthRecordShape.interval,
    valueOrigin: HealthValueOrigin.rawSensor,
    provenance: HealthProvenance(
      sourcePlatform: 'android',
      sourceApplicationId: sourceApp,
      physicalDeviceId: 'same-watch',
      acquisitionRoute: route,
      entryMethod: HealthEntryMethod.sensor,
    ),
    isDeleted: isDeleted,
  );
}
