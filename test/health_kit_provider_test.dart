import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/repositories/health_data_repository.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';
import 'package:hydrion/services/health_kit_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHealthKitBridge bridge;
  late AppleHealthKitProvider provider;
  late DateTime now;

  setUp(() {
    bridge = _FakeHealthKitBridge();
    now = DateTime.utc(2026, 9, 13, 12);
    provider = AppleHealthKitProvider(
      bridge: bridge,
      clock: () => now,
    );
  });

  test('reports the narrow read-only HealthKit capability', () async {
    expect((await provider.availability()).status,
        HealthProviderAvailabilityStatus.available);
    final capabilities = await provider.capabilities();
    expect(
        capabilities.readableMetrics, AppleHealthKitProvider.supportedMetrics);
    expect(capabilities.supportsIncrementalChanges, isTrue);
    expect(capabilities.supportsDeletions, isTrue);
    expect(capabilities.supportsBackgroundReads, isFalse);
    expect(provider.readAuthorizationIsOpaque, isTrue);
  });

  test('does not claim read grants before HealthKit authorization is requested',
      () async {
    bridge.requestStatus = 'shouldRequest';
    final authorization = await provider.authorizationState(
      AppleHealthKitProvider.supportedMetrics,
    );
    expect(authorization.status, HealthPermissionStatus.notRequested);
    expect(authorization.grantedMetrics, isEmpty);
  });

  test('treats completed request as queryable without claiming visible grants',
      () async {
    final authorization = await provider.requestReadAccess(
      AppleHealthKitProvider.supportedMetrics,
    );
    expect(authorization.status, HealthPermissionStatus.requestCompleted);
    expect(
      authorization.grantedMetrics,
      AppleHealthKitProvider.supportedMetrics,
    );
    expect(provider.readAuthorizationIsOpaque, isTrue);
  });

  test('maps an anchored HealthKit sample and preserves source provenance',
      () async {
    bridge.records = [
      {
        'schemaVersion': 1,
        'recordId': 'A1',
        'metric': 'steps',
        'value': 2400,
        'originalUnit': 'count',
        'startTime': '2026-09-13T10:00:00.000Z',
        'endTime': '2026-09-13T11:00:00.000Z',
        'synchronizationVersion': 'A1',
        'sourceApplicationId': 'com.apple.Health',
        'sourceApplicationName': 'Health',
        'deviceManufacturer': 'Apple Inc.',
        'deviceModel': 'Watch',
        'deviceHardwareVersion': 'Watch7,5',
        'deviceSoftwareVersion': '11.6',
        'physicalDeviceId': 'local-watch',
        'sourceRevision': '1.2.3|Watch7,5|18.6.0',
        'sourceTimeZone': 'America/Toronto',
        'startOffsetSeconds': -14400,
        'recordingMethod': 'sensor',
        'deleted': false,
      }
    ];
    final page = await provider.readChanges(HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      historyStart: DateTime.utc(2026, 8, 14),
    ));
    expect(page.records, hasLength(1));
    final record = page.records.single;
    expect(record.value, 2400);
    expect(record.unit, HealthUnit.count);
    expect(record.provenance.sourcePlatform, 'ios');
    expect(record.provenance.sourceApplicationName, 'Health');
    expect(record.provenance.physicalDeviceId, 'local-watch');
    expect(record.provenance.deviceHardwareVersion, 'Watch7,5');
    expect(record.provenance.deviceSoftwareVersion, '11.6');
    expect(record.sourceTimeZone, 'America/Toronto');
    expect(record.sourceUtcOffset, const Duration(hours: -4));
    expect(
      record.providerMetadata['providerSourceRevision'],
      '1.2.3|Watch7,5|18.6.0',
    );
    expect(
        record.provenance.acquisitionRoute, HealthAcquisitionRoute.healthKit);
    expect(
      jsonDecode(page.nextCheckpoint.cursor!)['anchor'],
      'anchor-1',
    );
  });

  test('passes a saved anchor and maps HealthKit deletions', () async {
    bridge.records = [
      {
        'schemaVersion': 1,
        'recordId': 'A1',
        'metric': 'steps',
        'deleted': true,
      }
    ];
    final page = await provider.readChanges(HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      cursor: 'anchor-0',
      historyStart: DateTime.utc(2026, 8, 14),
    ));
    expect(bridge.lastArguments['anchor'], 'anchor-0');
    expect(page.records.single.isDeleted, isTrue);
  });

  test('rejects a mismatched or malformed native record', () async {
    bridge.records = [
      {
        'schemaVersion': 1,
        'recordId': 'A1',
        'metric': 'distance',
        'deleted': true,
      }
    ];
    expect(
      () => provider.readChanges(HealthSyncCheckpoint(
        providerId: AppleHealthKitProvider.id,
        metric: HealthMetric.steps,
        historyStart: DateTime.utc(2026, 8, 14),
      )),
      throwsFormatException,
    );
  });

  test('maps every supported metric and allows missing optional metadata',
      () async {
    final fixtures = <HealthMetric, (String, num)>{
      HealthMetric.workout: ('minute', 45),
      HealthMetric.activeEnergy: ('kilocalorie', 320.5),
      HealthMetric.steps: ('count', 2400),
      HealthMetric.distance: ('meter', 5000.25),
    };
    for (final entry in fixtures.entries) {
      bridge.records = [
        {
          'schemaVersion': 1,
          'recordId': 'record-${entry.key.name}',
          'metric': entry.key.name,
          'value': entry.value.$2,
          'originalUnit': entry.value.$1,
          'startTime': '2026-09-13T10:00:00.000Z',
          'endTime': '2026-09-13T11:00:00.000Z',
          'synchronizationVersion': 'v1',
          'sourceApplicationId': 'com.example.source',
          'recordingMethod': 'unknown',
          'deleted': false,
        }
      ];
      final page = await provider.readChanges(HealthSyncCheckpoint(
        providerId: AppleHealthKitProvider.id,
        metric: entry.key,
        historyStart: DateTime.utc(2026, 8, 14),
      ));
      expect(page.records.single.metric, entry.key);
      expect(page.records.single.value, entry.value.$2.toDouble());
      expect(page.records.single.provenance.sourceApplicationName, isNull);
      expect(page.records.single.provenance.deviceModel, isNull);
    }
  });

  test('keeps one bounded history end across an anchored page sequence',
      () async {
    bridge.hasMore = true;
    final first = await provider.readChanges(HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      historyStart: DateTime.utc(2026, 8, 14),
    ));
    expect(bridge.lastArguments['historyEnd'], now.toIso8601String());

    now = now.add(const Duration(hours: 4));
    bridge.hasMore = false;
    await provider.readChanges(first.nextCheckpoint);
    expect(
      bridge.lastArguments['historyEnd'],
      DateTime.utc(2026, 9, 13, 12).toIso8601String(),
    );
  });

  test('rejects unsupported response and checkpoint schema versions', () async {
    bridge.schemaVersion = 2;
    final checkpoint = HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      historyStart: DateTime.utc(2026, 8, 14),
    );
    await expectLater(provider.readChanges(checkpoint), throwsFormatException);
    await expectLater(
      provider.readChanges(HealthSyncCheckpoint(
        providerId: AppleHealthKitProvider.id,
        metric: HealthMetric.steps,
        cursor: '{"version":2,"anchor":"future"}',
        historyStart: DateTime.utc(2026, 8, 14),
      )),
      throwsFormatException,
    );
  });

  test('turns an invalid native anchor into an explicit checkpoint restart',
      () async {
    bridge.error = PlatformException(code: 'invalid_anchor');
    final checkpoint = HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      cursor: 'old-anchor',
      historyStart: DateTime.utc(2026, 8, 14),
    );
    final page = await provider.readChanges(checkpoint);
    expect(page.checkpointExpired, isTrue);
    expect(page.nextCheckpoint, same(checkpoint));
  });

  test('maps native query failures without exposing native details', () async {
    bridge.error = PlatformException(
      code: 'health_kit_read_failed',
      message: 'sensitive native detail',
    );
    final operation = provider.readChanges(HealthSyncCheckpoint(
      providerId: AppleHealthKitProvider.id,
      metric: HealthMetric.steps,
      historyStart: DateTime.utc(2026, 8, 14),
    ));
    await expectLater(
      operation,
      throwsA(isA<HealthDataProviderException>().having(
        (error) => error.reasonCode,
        'reasonCode',
        'health_kit_read_failed',
      )),
    );
  });

  test('coordinator imports updates and deletes one HealthKit identity',
      () async {
    final repository = MemoryHealthDataRepository();
    final coordinator = HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
      clock: () => now,
    );
    bridge.records = [_sample(value: 1000, version: 'v1')];
    final first = await coordinator.synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.steps},
    );

    bridge.records = [_sample(value: 1200, version: 'v2')];
    final updated = await coordinator.synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.steps},
    );

    bridge.records = [
      {
        'schemaVersion': 1,
        'recordId': 'stable-id',
        'metric': 'steps',
        'deleted': true,
      }
    ];
    final deleted = await coordinator.synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.steps},
    );

    expect(first.insertedCount, 1);
    expect(updated.updatedCount, 1);
    expect(deleted.deletedCount, 1);
    expect(
      await repository.records(includeDeleted: true),
      hasLength(1),
    );
    expect(
      (await repository.records(includeDeleted: true)).single.isDeleted,
      isTrue,
    );
  });

  test('metric failure is isolated and retry advances only its checkpoint',
      () async {
    final repository = MemoryHealthDataRepository();
    final coordinator = HealthDataSyncCoordinator(
      providers: [provider],
      repository: repository,
      clock: () => now,
    );
    bridge.recordsByMetric[HealthMetric.steps.name] = [_sample()];
    bridge.errorsByMetric[HealthMetric.activeEnergy.name] =
        PlatformException(code: 'health_kit_read_failed');

    final partial = await coordinator.synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.steps, HealthMetric.activeEnergy},
    );

    expect(partial.status, HealthSyncStatus.partial);
    expect(partial.metricResults[HealthMetric.steps]?.status,
        HealthSyncStatus.success);
    expect(partial.metricResults[HealthMetric.activeEnergy]?.status,
        HealthSyncStatus.failed);
    expect(
      await repository.checkpointFor(provider.providerId, HealthMetric.steps),
      isNotNull,
    );
    expect(
      await repository.checkpointFor(
          provider.providerId, HealthMetric.activeEnergy),
      isNull,
    );

    bridge.errorsByMetric.clear();
    bridge.recordsByMetric[HealthMetric.activeEnergy.name] = [
      _sample(
        id: 'energy-id',
        metric: HealthMetric.activeEnergy,
        unit: 'kilocalorie',
        value: 250,
      ),
    ];
    final retry = await coordinator.synchronize(
      providerId: provider.providerId,
      metrics: {HealthMetric.activeEnergy},
    );
    expect(retry.status, HealthSyncStatus.success);
    expect(
      await repository.checkpointFor(
          provider.providerId, HealthMetric.activeEnergy),
      isNotNull,
    );
  });

  test('permission-request failure is explicit and imports nothing', () async {
    bridge.permissionError = PlatformException(
      code: 'permission_request_failed',
    );
    await expectLater(
      provider.requestReadAccess(AppleHealthKitProvider.supportedMetrics),
      throwsA(isA<PlatformException>()),
    );
  });
}

Map<String, Object?> _sample({
  String id = 'stable-id',
  HealthMetric metric = HealthMetric.steps,
  String unit = 'count',
  num value = 1000,
  String version = 'v1',
}) =>
    {
      'schemaVersion': 1,
      'recordId': id,
      'metric': metric.name,
      'value': value,
      'originalUnit': unit,
      'startTime': '2026-09-13T10:00:00.000Z',
      'endTime': '2026-09-13T11:00:00.000Z',
      'synchronizationVersion': version,
      'sourceApplicationId': 'com.example.source',
      'recordingMethod': 'unknown',
      'deleted': false,
    };

class _FakeHealthKitBridge implements HealthKitBridge {
  bool available = true;
  String requestStatus = 'unnecessary';
  List<Object?> records = const [];
  Map<String, Object?> lastArguments = const {};
  int schemaVersion = 1;
  bool hasMore = false;
  PlatformException? error;
  PlatformException? permissionError;
  final Map<String, List<Object?>> recordsByMetric = {};
  final Map<String, PlatformException> errorsByMetric = {};

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    lastArguments = arguments;
    if (method == 'requestPermissions' && permissionError != null) {
      throw permissionError!;
    }
    final metric = arguments['metric'];
    final metricError = metric is String ? errorsByMetric[metric] : null;
    if (method == 'readAnchored' && metricError != null) {
      throw metricError;
    }
    if (method == 'readAnchored' && error != null) throw error!;
    return switch (method) {
      'availability' => {'available': available},
      'authorizationState' || 'requestPermissions' => {
          'requestStatus': requestStatus,
        },
      'readAnchored' => {
          'schemaVersion': schemaVersion,
          'records': metric is String && recordsByMetric.containsKey(metric)
              ? recordsByMetric[metric]!
              : records,
          'anchor': 'anchor-1',
          'hasMore': hasMore,
        },
      _ => throw MissingPluginException(),
    };
  }

  @override
  Future<void> openSettings() async {}
}
