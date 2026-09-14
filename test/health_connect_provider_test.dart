import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';
import 'package:hydrion/services/health_connect_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeHealthConnectBridge bridge;
  late AndroidHealthConnectProvider provider;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    bridge = _FakeHealthConnectBridge();
    provider = AndroidHealthConnectProvider(
      bridge: bridge,
      discovery: AndroidHealthProviderDiscovery(
        bridge: _AvailableDiscoveryBridge(),
      ),
      clock: () => DateTime.utc(2026, 1, 2, 12),
    );
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('exposes only approved read capabilities', () async {
    final capabilities = await provider.capabilities();

    expect(capabilities.readableMetrics, {
      HealthMetric.workout,
      HealthMetric.activeEnergy,
      HealthMetric.steps,
      HealthMetric.distance,
    });
    expect(capabilities.supportsIncrementalChanges, isTrue);
    expect(capabilities.supportsDeletions, isTrue);
    expect(capabilities.supportsBackgroundReads, isFalse);
  });

  test('reports partial authorization from current platform grants', () async {
    bridge.responses['authorizationState'] = {
      'state': 'partial',
      'grantedMetrics': ['steps', 'distance'],
    };

    final state = await provider.authorizationState(
      AndroidHealthConnectProvider.supportedMetrics,
    );

    expect(state.status, HealthPermissionStatus.partial);
    expect(state.grantedMetrics, {HealthMetric.steps, HealthMetric.distance});
    expect(bridge.calls.single.arguments['metrics'], hasLength(4));
  });

  test('initial import is bounded and advances to incremental token', () async {
    bridge.responses['readInitial'] = {
      'records': [_record(metric: 'steps', value: 4321)],
      'pageToken': null,
      'changesToken': 'changes-1',
    };
    final checkpoint = HealthSyncCheckpoint(
      providerId: provider.providerId,
      metric: HealthMetric.steps,
      historyStart: DateTime.utc(2025, 12, 3),
    );

    final page = await provider.readChanges(checkpoint);

    expect(page.records.single.value, 4321);
    expect(page.records.single.originalUnit, HealthUnit.count);
    expect(page.records.single.provenance.sourceApplicationId, 'test.writer');
    expect(page.records.single.provenance.deviceModel, isNull);
    expect(page.hasMore, isFalse);
    expect(page.nextCheckpoint.cursor, contains('changes-1'));
    expect(
      bridge.calls.single.arguments['historyStart'],
      '2025-12-03T00:00:00.000Z',
    );
  });

  for (final testCase in <({String metric, double value, HealthUnit unit})>[
    (metric: 'workout', value: 45, unit: HealthUnit.minute),
    (metric: 'activeEnergy', value: 321.5, unit: HealthUnit.kilocalorie),
    (metric: 'steps', value: 4321, unit: HealthUnit.count),
    (metric: 'distance', value: 2750.25, unit: HealthUnit.meter),
  ]) {
    test('normalizes ${testCase.metric} without repeated conversion', () async {
      bridge.responses['readInitial'] = {
        'records': [
          _record(metric: testCase.metric, value: testCase.value),
        ],
        'pageToken': null,
        'changesToken': 'changes-1',
      };
      final metric = HealthMetric.values.byName(testCase.metric);

      final page = await provider.readChanges(HealthSyncCheckpoint(
        providerId: provider.providerId,
        metric: metric,
        historyStart: DateTime.utc(2025, 12, 3),
      ));

      expect(page.records.single.value, testCase.value);
      expect(page.records.single.originalUnit, testCase.unit);
      expect(page.records.single.unit, testCase.unit);
      expect(page.records.single.sourceUtcOffset, const Duration(hours: -5));
    });
  }

  test('initial pagination preserves the original bounded end time', () async {
    bridge.responses['readInitial'] = {
      'records': <Object?>[],
      'pageToken': 'page-2',
      'changesToken': 'changes-1',
    };
    final checkpoint = HealthSyncCheckpoint(
      providerId: provider.providerId,
      metric: HealthMetric.distance,
      historyStart: DateTime.utc(2025, 12, 3),
    );

    final first = await provider.readChanges(checkpoint);
    bridge.responses['readInitial'] = {
      'records': <Object?>[],
      'pageToken': null,
      'changesToken': 'changes-1',
    };
    await provider.readChanges(first.nextCheckpoint);

    expect(bridge.calls.last.arguments['pageToken'], 'page-2');
    expect(
      bridge.calls.last.arguments['historyEnd'],
      '2026-01-02T12:00:00.000Z',
    );
  });

  test('incremental deletion remains a typed tombstone for reconciliation',
      () async {
    bridge.responses['readChanges'] = {
      'records': [
        {'recordId': 'record-7', 'deleted': true, 'metric': 'steps'},
      ],
      'changesToken': 'changes-2',
      'hasMore': false,
      'tokenExpired': false,
    };
    final checkpoint = HealthSyncCheckpoint(
      providerId: provider.providerId,
      metric: HealthMetric.steps,
      cursor: '{"phase":"changes","token":"changes-1"}',
      historyStart: DateTime.utc(2025, 12, 3),
    );

    final page = await provider.readChanges(checkpoint);

    expect(page.records.single.externalRecordId, 'record-7');
    expect(page.records.single.metric, HealthMetric.steps);
    expect(page.records.single.isDeleted, isTrue);
    expect(page.nextCheckpoint.cursor, contains('changes-2'));
  });

  test('expired token asks coordinator for a bounded recovery read', () async {
    bridge.responses['readChanges'] = {
      'records': <Object?>[],
      'changesToken': 'expired',
      'hasMore': false,
      'tokenExpired': true,
    };
    final page = await provider.readChanges(HealthSyncCheckpoint(
      providerId: provider.providerId,
      metric: HealthMetric.workout,
      cursor: '{"phase":"changes","token":"old"}',
      historyStart: DateTime.utc(2025, 12, 3),
    ));

    expect(page.checkpointExpired, isTrue);
    expect(page.records, isEmpty);
  });

  test('legacy non-JSON checkpoint recovers with a bounded initial read',
      () async {
    bridge.responses['readInitial'] = {
      'records': <Object?>[],
      'pageToken': null,
      'changesToken': 'replacement-token',
    };

    final page = await provider.readChanges(HealthSyncCheckpoint(
      providerId: provider.providerId,
      metric: HealthMetric.distance,
      cursor: 'legacy-distance-token',
      historyStart: DateTime.utc(2025, 12, 3),
    ));

    expect(bridge.calls.single.method, 'readInitial');
    expect(page.nextCheckpoint.cursor, contains('replacement-token'));
  });

  test('native read failures retain a safe provider category', () async {
    bridge.failures['readChanges'] = PlatformException(
      code: 'health_connect_io_failure',
    );

    expect(
      () => provider.readChanges(HealthSyncCheckpoint(
        providerId: provider.providerId,
        metric: HealthMetric.steps,
        cursor: '{"phase":"changes","token":"changes-1"}',
        historyStart: DateTime.utc(2025, 12, 3),
      )),
      throwsA(isA<HealthDataProviderException>().having(
        (error) => error.reasonCode,
        'reasonCode',
        'health_connect_io_failure',
      )),
    );
  });

  test('malformed or non-finite platform values fail closed', () async {
    bridge.responses['readInitial'] = {
      'records': [_record(metric: 'steps', value: double.nan)],
      'pageToken': null,
      'changesToken': 'changes-1',
    };

    expect(
      () => provider.readChanges(HealthSyncCheckpoint(
        providerId: provider.providerId,
        metric: HealthMetric.steps,
        historyStart: DateTime.utc(2025, 12, 3),
      )),
      throwsFormatException,
    );
  });
}

Map<String, Object?> _record({required String metric, required num value}) => {
      'recordId': 'record-7',
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
      'startTime': '2026-01-02T10:00:00Z',
      'endTime': '2026-01-02T10:30:00Z',
      'startOffsetSeconds': -18000,
      'endOffsetSeconds': -18000,
      'lastModifiedTime': '2026-01-02T10:31:00Z',
      'clientRecordVersion': '2',
      'sourceApplicationId': 'test.writer',
      'deviceManufacturer': null,
      'deviceModel': null,
      'recordingMethod': 'sensor',
      'deleted': false,
    };

class _BridgeCall {
  final String method;
  final Map<String, Object?> arguments;

  const _BridgeCall(this.method, this.arguments);
}

class _FakeHealthConnectBridge implements HealthConnectBridge {
  final Map<String, Map<String, Object?>> responses = {};
  final Map<String, PlatformException> failures = {};
  final List<_BridgeCall> calls = [];

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    calls.add(_BridgeCall(method, arguments));
    final failure = failures[method];
    if (failure != null) throw failure;
    return responses[method] ??
        {
          'state': 'notGranted',
          'grantedMetrics': <Object?>[],
        };
  }

  @override
  Future<void> openSettings() async {}
}

class _AvailableDiscoveryBridge implements AndroidHealthDiscoveryBridge {
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
