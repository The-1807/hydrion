import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/health_data_repository.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';
import 'package:hydrion/services/health_connect_provider.dart';
import 'package:hydrion/services/health_connection_controller.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('permission is requested only by explicit connect action', () async {
    final bridge = _ControllerBridge();
    final controller = _controller(bridge);

    await controller.initialize();
    expect(bridge.permissionRequests, 0);
    expect(controller.state, HealthConnectionViewState.consentRequired);

    await controller.connect();
    expect(bridge.permissionRequests, 1);
    expect(controller.isConnected, isFalse);
    expect(controller.state, HealthConnectionViewState.permissionDenied);
  });

  test('provider discovery failures remain a recoverable view state', () async {
    final bridge = _ControllerBridge();
    final repository = MemoryHealthDataRepository();
    final provider = AndroidHealthConnectProvider(
      bridge: bridge,
      discovery: AndroidHealthProviderDiscovery(
        bridge: _FailingDiscoveryBridge(),
      ),
    );
    final controller = HealthConnectionController(
      provider: provider,
      coordinator: HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      ),
      repository: repository,
      store: MemoryHydrionStore(),
    );

    await controller.initialize();

    expect(controller.state, HealthConnectionViewState.providerUnavailable);
    expect(controller.failureReason, 'provider_refresh_failed');
    expect(bridge.permissionRequests, 0);
  });

  test('protected-storage failure blocks provider access', () async {
    final bridge = _ControllerBridge();
    final repository = MemoryHealthDataRepository();
    final provider = AndroidHealthConnectProvider(
      bridge: bridge,
      discovery: AndroidHealthProviderDiscovery(
        bridge: _ControllerDiscoveryBridge(),
      ),
    );
    final controller = HealthConnectionController(
      provider: provider,
      coordinator: HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      ),
      repository: repository,
      store: MemoryHydrionStore(),
      persistenceReady: false,
    );

    await controller.initialize();

    expect(controller.state, HealthConnectionViewState.synchronizationFailed);
    expect(controller.failureReason, 'protected_storage_unavailable');
    expect(bridge.permissionRequests, 0);
  });

  test('disconnect and local deletion preserve unrelated local data', () async {
    final bridge = _GrantedControllerBridge();
    final repository = MemoryHealthDataRepository();
    final store = MemoryHydrionStore();
    await store.writeString('manual_hydration_sentinel', 'preserved');
    await repository.commitImport(
      records: [_healthRecord()],
      checkpoint: HealthSyncCheckpoint(
        providerId: AndroidHealthConnectProvider.id,
        metric: HealthMetric.steps,
        historyStart: DateTime.utc(2026, 8, 14),
      ),
    );
    final provider = AndroidHealthConnectProvider(
      bridge: bridge,
      discovery: AndroidHealthProviderDiscovery(
        bridge: _ControllerDiscoveryBridge(),
        forceAndroidForTesting: true,
      ),
    );
    final controller = HealthConnectionController(
      provider: provider,
      coordinator: HealthDataSyncCoordinator(
        providers: [provider],
        repository: repository,
      ),
      repository: repository,
      store: store,
    );

    await controller.initialize();
    await controller.connect();
    expect(
      controller.state,
      HealthConnectionViewState.connectedNotSynchronized,
    );
    expect(controller.importedRecordCount, 1);
    expect(controller.contributingApplications, {'synthetic.health.writer'});

    await controller.disconnect();
    expect(controller.isConnected, isFalse);
    expect(await repository.records(), hasLength(1));
    expect(await store.readString('manual_hydration_sentinel'), 'preserved');

    expect(await controller.deleteImportedData(), 1);
    expect(await repository.records(), isEmpty);
    expect(await store.readString('manual_hydration_sentinel'), 'preserved');
    expect(bridge.calls, isNot(contains('deleteRecords')));
  });

  test('successful empty synchronization persists across restart', () async {
    final bridge = _SyncControllerBridge();
    final repository = MemoryHealthDataRepository();
    final store = MemoryHydrionStore();
    final controller = _syncController(bridge, repository, store);

    await controller.initialize();
    await controller.connect();
    expect(
        controller.state, HealthConnectionViewState.connectedNotSynchronized);

    final result = await controller.synchronize();
    expect(result.status, HealthSyncStatus.success);
    expect(controller.state, HealthConnectionViewState.synchronizedNoRecords);
    expect(controller.lastRecordsRead, 0);

    final restarted = _syncController(bridge, repository, store);
    await restarted.initialize();
    expect(restarted.state, HealthConnectionViewState.synchronizedNoRecords);
    expect(restarted.lastSuccessfulSynchronization,
        DateTime.utc(2026, 9, 13, 10, 26));
  });

  test('record synchronization exposes durable counts range and source',
      () async {
    final bridge = _SyncControllerBridge(
      recordsByMetric: {
        HealthMetric.steps: [_bridgeRecord('steps', 4321)],
      },
    );
    final repository = MemoryHealthDataRepository();
    final store = MemoryHydrionStore();
    final controller = _syncController(bridge, repository, store);

    await controller.initialize();
    await controller.connect();
    final result = await controller.synchronize();

    expect(result.recordsRead, 1);
    expect(result.insertedCount, 1);
    expect(result.updatedCount, 0);
    expect(controller.state, HealthConnectionViewState.synchronizedWithRecords);
    expect(controller.importedRecordCount, 1);
    expect(controller.availableMetrics, {HealthMetric.steps});
    expect(controller.contributingApplicationRecordCounts,
        {'synthetic.health.writer': 1});
    expect(controller.earliestRecordTime, DateTime.utc(2026, 9, 13, 9));
    expect(controller.latestRecordTime, DateTime.utc(2026, 9, 13, 10));

    final restarted = _syncController(bridge, repository, store);
    await restarted.initialize();
    expect(restarted.state, HealthConnectionViewState.synchronizedWithRecords);
    expect(restarted.lastInsertedCount, 1);
    expect(restarted.importedRecordCount, 1);
  });

  test('latest failure preserves previous success and imported records',
      () async {
    final bridge = _SyncControllerBridge(
      recordsByMetric: {
        HealthMetric.steps: [_bridgeRecord('steps', 4321)],
      },
    );
    final repository = MemoryHealthDataRepository();
    final store = MemoryHydrionStore();
    final controller = _syncController(bridge, repository, store);

    await controller.initialize();
    await controller.connect();
    await controller.synchronize();
    final priorSuccess = controller.lastSuccessfulSynchronization;
    bridge.failReads = true;

    await controller.synchronize();

    expect(controller.state, HealthConnectionViewState.synchronizationFailed);
    expect(controller.lastSuccessfulSynchronization, priorSuccess);
    expect(controller.importedRecordCount, 1);
    expect(controller.failureReason, 'provider_or_repository_failure');
  });

  test('partial synchronization identifies and retries only failed metrics',
      () async {
    final bridge = _SyncControllerBridge(
      failMetrics: {HealthMetric.activeEnergy},
    );
    final repository = MemoryHealthDataRepository();
    final store = MemoryHydrionStore();
    final controller = _syncController(bridge, repository, store);

    await controller.initialize();
    await controller.connect();
    final first = await controller.synchronize();

    expect(first.status, HealthSyncStatus.partial);
    expect(controller.successfulMetrics, {
      HealthMetric.workout,
      HealthMetric.steps,
      HealthMetric.distance,
    });
    expect(controller.failedMetrics, {HealthMetric.activeEnergy});
    expect(
      controller.state,
      HealthConnectionViewState.synchronizationPartiallySuccessful,
    );

    bridge.attemptedMetrics.clear();
    bridge.failMetrics.clear();
    final retried = await controller.retryFailedMetrics();

    expect(retried.status, HealthSyncStatus.success);
    expect(bridge.attemptedMetrics, [HealthMetric.activeEnergy]);
    expect(controller.failedMetrics, isEmpty);

    final restarted = _syncController(bridge, repository, store);
    await restarted.initialize();
    expect(restarted.lastMetricResults.keys, {HealthMetric.activeEnergy});
    expect(restarted.failedMetrics, isEmpty);
  });

  test('refresh distinguishes revoked and partial permissions', () async {
    final bridge = _SyncControllerBridge();
    final controller = _syncController(
      bridge,
      MemoryHealthDataRepository(),
      MemoryHydrionStore(),
    );
    await controller.initialize();
    await controller.connect();

    bridge.grantedMetrics = {HealthMetric.steps, HealthMetric.distance};
    await controller.refresh();
    expect(
        controller.state, HealthConnectionViewState.permissionPartiallyGranted);
    expect(controller.missingMetrics,
        {HealthMetric.workout, HealthMetric.activeEnergy});

    bridge.grantedMetrics = {};
    await controller.refresh();
    expect(controller.state, HealthConnectionViewState.permissionsRevoked);
  });

  test('duplicate synchronization attempt is rejected while one is active',
      () async {
    final gate = Completer<void>();
    final bridge = _SyncControllerBridge(readGate: gate);
    final controller = _syncController(
      bridge,
      MemoryHealthDataRepository(),
      MemoryHydrionStore(),
    );
    await controller.initialize();
    await controller.connect();

    final first = controller.synchronize();
    await Future<void>.delayed(Duration.zero);
    expect(controller.state, HealthConnectionViewState.synchronizing);
    final duplicate = await controller.synchronize();
    expect(duplicate.status, HealthSyncStatus.cancelled);
    expect(duplicate.reasonCode, 'synchronization_not_started');

    gate.complete();
    expect((await first).status, HealthSyncStatus.success);
  });
}

HealthConnectionController _syncController(
  _SyncControllerBridge bridge,
  HealthDataRepository repository,
  HydrionLocalStore store,
) {
  final provider = AndroidHealthConnectProvider(
    bridge: bridge,
    discovery: AndroidHealthProviderDiscovery(
      bridge: _ControllerDiscoveryBridge(),
      forceAndroidForTesting: true,
    ),
    clock: () => DateTime.utc(2026, 9, 13, 10, 26),
  );
  return HealthConnectionController(
    provider: provider,
    coordinator: HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
      clock: () => DateTime.utc(2026, 9, 13, 10, 26),
    ),
    repository: repository,
    store: store,
    clock: () => DateTime.utc(2026, 9, 13, 10, 26),
  );
}

HealthConnectionController _controller(_ControllerBridge bridge) {
  final repository = MemoryHealthDataRepository();
  final provider = AndroidHealthConnectProvider(
    bridge: bridge,
    discovery: AndroidHealthProviderDiscovery(
      bridge: _ControllerDiscoveryBridge(),
    ),
  );
  return HealthConnectionController(
    provider: provider,
    coordinator: HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
    ),
    repository: repository,
    store: MemoryHydrionStore(),
  );
}

class _ControllerBridge implements HealthConnectBridge {
  int permissionRequests = 0;

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (method == 'requestPermissions') permissionRequests += 1;
    return {'state': 'notGranted', 'grantedMetrics': <Object?>[]};
  }

  @override
  Future<void> openSettings() async {}
}

class _ControllerDiscoveryBridge implements AndroidHealthDiscoveryBridge {
  @override
  Future<Map<String, Object?>> discover() async => {
        'phoneManufacturer': 'INFINIX',
        'phoneModel': 'test',
        'sdkLevel': 33,
        'googleMobileServicesAvailable': true,
        'googlePlayStoreAvailable': true,
        'workProfile': false,
        'healthConnectBuiltIn': false,
        'healthConnectPackageInstalled': true,
        'healthConnectStatus': 'available',
        'permissionState': 'notRequested',
        'connectionState': 'disconnected',
        'companions': <Object?>[],
      };
}

class _FailingDiscoveryBridge implements AndroidHealthDiscoveryBridge {
  @override
  Future<Map<String, Object?>> discover() async =>
      throw StateError('synthetic discovery failure');
}

class _GrantedControllerBridge implements HealthConnectBridge {
  final List<String> calls = [];

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    calls.add(method);
    return {
      'state': 'granted',
      'grantedMetrics': const [
        'workout',
        'activeEnergy',
        'steps',
        'distance',
      ],
    };
  }

  @override
  Future<void> openSettings() async => calls.add('openSettings');
}

class _SyncControllerBridge implements HealthConnectBridge {
  final Map<HealthMetric, List<Map<String, Object?>>> recordsByMetric;
  final Completer<void>? readGate;
  Set<HealthMetric> grantedMetrics =
      AndroidHealthConnectProvider.supportedMetrics;
  bool failReads = false;
  final Set<HealthMetric> failMetrics;
  final List<HealthMetric> attemptedMetrics = [];

  _SyncControllerBridge({
    this.recordsByMetric = const {},
    this.readGate,
    Set<HealthMetric>? failMetrics,
  }) : failMetrics = failMetrics ?? {};

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (method == 'authorizationState' || method == 'requestPermissions') {
      return {
        'state': grantedMetrics.length ==
                AndroidHealthConnectProvider.supportedMetrics.length
            ? 'granted'
            : grantedMetrics.isEmpty
                ? 'notGranted'
                : 'partial',
        'grantedMetrics': grantedMetrics.map((metric) => metric.name).toList(),
      };
    }
    if (method == 'readInitial' || method == 'readChanges') {
      if (readGate != null) await readGate!.future;
      if (failReads) throw StateError('synthetic read failure');
      final metric = HealthMetric.values.byName(arguments['metric']! as String);
      attemptedMetrics.add(metric);
      if (failMetrics.contains(metric)) {
        throw StateError('synthetic metric read failure');
      }
      return {
        'records': method == 'readInitial'
            ? recordsByMetric[metric] ?? <Object?>[]
            : <Object?>[],
        'pageToken': null,
        'changesToken': 'token-${metric.name}',
        'hasMore': false,
        'tokenExpired': false,
      };
    }
    throw StateError('Unexpected method $method');
  }

  @override
  Future<void> openSettings() async {}
}

Map<String, Object?> _bridgeRecord(String metric, num value) => {
      'recordId': 'synthetic-$metric-1',
      'metric': metric,
      'value': value,
      'originalUnit': metric == 'steps'
          ? 'count'
          : metric == 'distance'
              ? 'meter'
              : metric == 'activeEnergy'
                  ? 'kilocalorie'
                  : 'minute',
      'category': metric == 'workout' ? '56' : null,
      'startTime': '2026-09-13T09:00:00Z',
      'endTime': '2026-09-13T10:00:00Z',
      'startOffsetSeconds': -14400,
      'endOffsetSeconds': -14400,
      'lastModifiedTime': '2026-09-13T10:01:00Z',
      'clientRecordVersion': '1',
      'sourceApplicationId': 'synthetic.health.writer',
      'sourceApplicationName': 'Synthetic Writer',
      'deviceManufacturer': null,
      'deviceModel': null,
      'recordingMethod': 'manual',
      'deleted': false,
    };

CanonicalHealthRecord _healthRecord() => CanonicalHealthRecord(
      id: 'health-connect:steps:synthetic-1',
      providerId: AndroidHealthConnectProvider.id,
      externalRecordId: 'synthetic-1',
      synchronizationVersion: '1',
      metric: HealthMetric.steps,
      semanticId: 'activity.steps',
      value: 1200,
      originalUnit: HealthUnit.count,
      unit: HealthUnit.count,
      startTime: DateTime.utc(2026, 9, 13, 8),
      endTime: DateTime.utc(2026, 9, 13, 9),
      ingestedAt: DateTime.utc(2026, 9, 13, 9, 1),
      shape: HealthRecordShape.interval,
      valueOrigin: HealthValueOrigin.rawSensor,
      provenance: const HealthProvenance(
        sourcePlatform: 'android',
        sourceApplicationId: 'synthetic.health.writer',
        acquisitionRoute: HealthAcquisitionRoute.healthConnect,
        entryMethod: HealthEntryMethod.sensor,
      ),
    );
