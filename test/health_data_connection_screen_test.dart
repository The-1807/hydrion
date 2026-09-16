import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/health_data.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/health_data_repository.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';
import 'package:hydrion/services/health_connect_provider.dart';
import 'package:hydrion/services/health_connection_controller.dart';
import 'package:hydrion/services/health_data_sync_coordinator.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/health_data_connection_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('explains consent before user initiates permission request',
      (tester) async {
    final bridge = _ScreenBridge();
    final repository = MemoryHealthDataRepository();
    final provider = AndroidHealthConnectProvider(
      bridge: bridge,
      discovery: AndroidHealthProviderDiscovery(
        bridge: _ScreenDiscoveryBridge(),
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
      store: MemoryHydrionStore(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HealthDataConnectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connect health data'), findsOneWidget);
    expect(find.textContaining('read-only'), findsWidgets);
    expect(find.textContaining('encrypted on this device'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a medical diagnosis'), findsOneWidget);
    expect(bridge.permissionRequests, 0);

    final connect = tester.widget<FilledButton>(
      find.byKey(const Key('health-data-connect')),
    );
    expect(connect.onPressed, isNotNull);
    connect.onPressed!();
    await tester.pumpAndSettle();

    expect(bridge.permissionRequests, 1);
    expect(controller.isConnected, isTrue);
    expect(
      controller.state,
      HealthConnectionViewState.connectedNotSynchronized,
    );
    expect(find.text('Health-data provider connected'), findsOneWidget);
    expect(find.text('No synchronization completed yet.'), findsOneWidget);
  });

  testWidgets('renders a durable synchronized dashboard with record evidence',
      (tester) async {
    final repository = MemoryHealthDataRepository();
    await repository.commitImport(
      records: [_screenRecord()],
      checkpoint: HealthSyncCheckpoint(
        providerId: AndroidHealthConnectProvider.id,
        metric: HealthMetric.steps,
        historyStart: DateTime.utc(2026, 8, 14),
      ),
    );
    final controller = await _pumpPersistedScreen(
      tester,
      repository: repository,
      values: {
        'connected': true,
        'permissionRequested': true,
        'lastAttempted': '2026-09-13T10:26:00Z',
        'lastSuccessful': '2026-09-13T10:26:00Z',
        'lastOutcome': 'success',
        'recordsRead': 1,
        'inserted': 1,
        'updated': 0,
        'deleted': 0,
        'rejected': 0,
      },
    );

    expect(controller.state, HealthConnectionViewState.synchronizedWithRecords);
    expect(find.text('Connected and synchronized'), findsOneWidget);
    expect(find.textContaining('1 read, 1 new'), findsOneWidget);
    expect(find.text('Imported records: 1'), findsOneWidget);
    expect(find.textContaining('synthetic.health.writer: 1'), findsOneWidget);
    expect(find.text('Steps'), findsWidgets);
  });

  testWidgets(
      'does not present legacy timestamps as a completed synchronization',
      (tester) async {
    await _pumpPersistedScreen(
      tester,
      values: {
        'connected': true,
        'permissionRequested': true,
        'lastAttempted': '2026-09-13T10:26:00.000Z',
        'lastSuccessful': '2026-09-13T10:26:00.000Z',
      },
    );

    expect(find.text('No synchronization completed yet.'), findsOneWidget);
    expect(find.textContaining('Last attempt:'), findsNothing);
    expect(
        find.textContaining('Last successful synchronization:'), findsNothing);
  });

  testWidgets('renders successful empty synchronization as a qualified state',
      (tester) async {
    await _pumpPersistedScreen(
      tester,
      values: {
        'connected': true,
        'permissionRequested': true,
        'lastAttempted': '2026-09-13T10:26:00Z',
        'lastSuccessful': '2026-09-13T10:26:00Z',
        'lastOutcome': 'success',
      },
    );

    expect(
        find.text('Connected, but no health data was found'), findsOneWidget);
    expect(find.textContaining('no readable workout'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Manage access'), findsOneWidget);
  });

  testWidgets('renders failed latest attempt without hiding prior success',
      (tester) async {
    await _pumpPersistedScreen(
      tester,
      values: {
        'connected': true,
        'permissionRequested': true,
        'lastAttempted': '2026-09-13T10:30:00Z',
        'lastSuccessful': '2026-09-13T10:26:00Z',
        'lastOutcome': 'failed',
        'failureReason': 'provider_or_repository_failure',
      },
    );

    expect(find.text('Health data could not be synchronized.'), findsOneWidget);
    expect(find.textContaining('Previously imported records'), findsOneWidget);
    expect(
        find.textContaining('Last successful synchronization'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
      'partial synchronization names categories and offers scoped retry',
      (tester) async {
    await _pumpPersistedScreen(
      tester,
      values: {
        'connected': true,
        'permissionRequested': true,
        'lastAttempted': '2026-09-13T10:30:00Z',
        'lastSuccessful': '2026-09-13T10:26:00Z',
        'lastOutcome': 'partial',
        'failureReason': 'provider_or_repository_failure',
        'metricResults': {
          'workout': {'status': 'success'},
          'steps': {'status': 'success'},
          'activeEnergy': {
            'status': 'failed',
            'reasonCode': 'provider_or_repository_failure',
          },
        },
      },
    );

    expect(
      find.textContaining('Synchronized categories: Workouts, Steps'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Categories needing attention: Active energy'),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('health-data-retry-failed')),
      findsOneWidget,
    );
  });

  testWidgets('renders revoked access and missing categories', (tester) async {
    await _pumpPersistedScreen(
      tester,
      bridge: _ScreenBridge(grantedMetrics: const {}),
      values: {
        'connected': true,
        'permissionRequested': true,
      },
    );

    expect(find.text('Health access needs attention'), findsOneWidget);
    expect(find.textContaining('Missing access:'), findsOneWidget);
    expect(
        find.byKey(const Key('health-data-request-missing')), findsOneWidget);
  });

  testWidgets('synchronizing is persistent and disables duplicate actions',
      (tester) async {
    final gate = Completer<void>();
    final bridge = _ScreenBridge(granted: true, readGate: gate);
    final controller = await _pumpPersistedScreen(
      tester,
      bridge: bridge,
      values: {
        'connected': true,
        'permissionRequested': true,
      },
    );

    final synchronization = controller.synchronize();
    await tester.pump();

    expect(find.text('Synchronizing health data...'), findsOneWidget);
    expect(find.byKey(const Key('health-data-sync-progress')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('health-data-sync')),
    );
    expect(button.onPressed, isNull);

    gate.complete();
    await synchronization;
    await tester.pumpAndSettle();
    expect(
        find.text('Connected, but no health data was found'), findsOneWidget);
  });
}

Future<HealthConnectionController> _pumpPersistedScreen(
  WidgetTester tester, {
  _ScreenBridge? bridge,
  HealthDataRepository? repository,
  required Map<String, Object?> values,
}) async {
  final resolvedBridge = bridge ?? _ScreenBridge(granted: true);
  final resolvedRepository = repository ?? MemoryHealthDataRepository();
  final provider = AndroidHealthConnectProvider(
    bridge: resolvedBridge,
    discovery: AndroidHealthProviderDiscovery(
      bridge: _ScreenDiscoveryBridge(),
      forceAndroidForTesting: true,
    ),
    clock: () => DateTime.utc(2026, 9, 13, 10, 31),
  );
  final controller = HealthConnectionController(
    provider: provider,
    coordinator: HealthDataSyncCoordinator(
      providers: [provider],
      repository: resolvedRepository,
      clock: () => DateTime.utc(2026, 9, 13, 10, 31),
    ),
    repository: resolvedRepository,
    store: MemoryHydrionStore({
      'health_connect_connection_v1': jsonEncode(values),
    }),
    clock: () => DateTime.utc(2026, 9, 13, 10, 31),
  );
  await controller.initialize();
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HealthDataConnectionScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

class _ScreenBridge implements HealthConnectBridge {
  int permissionRequests = 0;
  final Completer<void>? readGate;
  Set<HealthMetric> grantedMetrics;

  _ScreenBridge({
    bool granted = false,
    Set<HealthMetric>? grantedMetrics,
    this.readGate,
  }) : grantedMetrics = grantedMetrics ??
            (granted
                ? AndroidHealthConnectProvider.supportedMetrics
                : const <HealthMetric>{});

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (method == 'requestPermissions') {
      permissionRequests += 1;
      grantedMetrics = AndroidHealthConnectProvider.supportedMetrics;
    }
    if (method == 'readInitial' || method == 'readChanges') {
      if (readGate != null) await readGate!.future;
      return {
        'records': <Object?>[],
        'pageToken': null,
        'changesToken': 'next',
        'hasMore': false,
        'tokenExpired': false,
      };
    }
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

  @override
  Future<void> openSettings() async {}
}

CanonicalHealthRecord _screenRecord() => CanonicalHealthRecord(
      id: 'health-connect:steps:synthetic-1',
      providerId: AndroidHealthConnectProvider.id,
      externalRecordId: 'synthetic-1',
      synchronizationVersion: '1',
      metric: HealthMetric.steps,
      semanticId: 'activity.steps',
      value: 4321,
      originalUnit: HealthUnit.count,
      unit: HealthUnit.count,
      startTime: DateTime.utc(2026, 9, 12, 9),
      endTime: DateTime.utc(2026, 9, 13, 10),
      ingestedAt: DateTime.utc(2026, 9, 13, 10, 26),
      shape: HealthRecordShape.interval,
      valueOrigin: HealthValueOrigin.rawSensor,
      provenance: const HealthProvenance(
        sourcePlatform: 'android',
        sourceApplicationId: 'synthetic.health.writer',
        acquisitionRoute: HealthAcquisitionRoute.healthConnect,
        entryMethod: HealthEntryMethod.manual,
      ),
    );

class _ScreenDiscoveryBridge implements AndroidHealthDiscoveryBridge {
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
