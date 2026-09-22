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
import 'package:hydrion/ui/screens/wearable_data_dashboard_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('repository failure shows an error and retry can recover',
      (tester) async {
    final repository = _FailingDashboardRepository();
    final provider = AndroidHealthConnectProvider(
        bridge: _DashboardBridge(granted: true),
        discovery: AndroidHealthProviderDiscovery(
            bridge: _DashboardDiscoveryBridge(), forceAndroidForTesting: true));
    final controller = HealthConnectionController(
        provider: provider,
        coordinator: HealthDataSyncCoordinator(
            providers: [provider], repository: repository),
        repository: repository,
        store: MemoryHydrionStore());
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: WearableDataDashboardScreen())));
    await tester.pumpAndSettle();
    final l10n = AppLocalizations.of(
        tester.element(find.byType(WearableDataDashboardScreen)));
    expect(find.text(l10n.healthDataSummaryUnavailable), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    repository.failRead = false;
    await tester.tap(find.text(l10n.healthDataTryAgain));
    await tester.pumpAndSettle();
    expect(find.text(l10n.healthDataSummaryUnavailable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders workout timeline and steps trend from imported records',
      (tester) async {
    final repository = MemoryHealthDataRepository();
    await repository.commitImport(
      records: [
        _record(
          metric: HealthMetric.workout,
          value: 30,
          unit: HealthUnit.minute,
          start: DateTime.utc(2026, 9, 12, 9),
          end: DateTime.utc(2026, 9, 12, 9, 30),
        ),
      ],
      checkpoint: HealthSyncCheckpoint(
        providerId: AndroidHealthConnectProvider.id,
        metric: HealthMetric.workout,
        historyStart: DateTime.utc(2026, 8, 14),
      ),
    );
    await repository.commitImport(
      records: [
        _record(
          metric: HealthMetric.steps,
          value: 4321,
          unit: HealthUnit.count,
          start: DateTime.utc(2026, 9, 12, 9),
          end: DateTime.utc(2026, 9, 12, 9, 1),
        ),
      ],
      checkpoint: HealthSyncCheckpoint(
        providerId: AndroidHealthConnectProvider.id,
        metric: HealthMetric.steps,
        historyStart: DateTime.utc(2026, 8, 14),
      ),
    );
    final provider = AndroidHealthConnectProvider(
      bridge: _DashboardBridge(granted: true),
      discovery: AndroidHealthProviderDiscovery(
        bridge: _DashboardDiscoveryBridge(),
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
          home: WearableDataDashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('30 min workout'), findsOneWidget);
    expect(find.text('Distance trend (last 14 days)'), findsOneWidget);
    expect(find.text('No data in the last 14 days.'), findsWidgets);
  });
}

class _FailingDashboardRepository extends MemoryHealthDataRepository {
  bool failRead = true;

  @override
  Future<List<CanonicalHealthRecord>> records(
      {Set<HealthMetric>? metrics,
      DateTime? start,
      DateTime? end,
      bool includeDeleted = false,
      bool includeDuplicates = false,
      int limit = HealthDataRepository.defaultPageSize,
      int offset = 0}) async {
    if (failRead) throw StateError('synthetic storage failure');
    return [];
  }
}

CanonicalHealthRecord _record({
  required HealthMetric metric,
  required double value,
  required HealthUnit unit,
  required DateTime start,
  required DateTime end,
}) =>
    CanonicalHealthRecord(
      id: 'health-connect:${metric.name}:synthetic-${start.millisecondsSinceEpoch}',
      providerId: AndroidHealthConnectProvider.id,
      externalRecordId:
          'synthetic-${metric.name}-${start.millisecondsSinceEpoch}',
      synchronizationVersion: '1',
      metric: metric,
      semanticId: 'activity.${metric.name}',
      value: value,
      originalUnit: unit,
      unit: unit,
      startTime: start,
      endTime: end,
      ingestedAt: end,
      shape: HealthRecordShape.interval,
      valueOrigin: HealthValueOrigin.rawSensor,
      provenance: const HealthProvenance(
        sourcePlatform: 'android',
        sourceApplicationId: 'synthetic.health.writer',
        acquisitionRoute: HealthAcquisitionRoute.healthConnect,
        entryMethod: HealthEntryMethod.manual,
      ),
    );

class _DashboardBridge implements HealthConnectBridge {
  Set<HealthMetric> grantedMetrics;

  _DashboardBridge({bool granted = false})
      : grantedMetrics = granted
            ? AndroidHealthConnectProvider.supportedMetrics
            : const <HealthMetric>{};

  @override
  Future<Map<String, Object?>> invoke(
    String method, [
    Map<String, Object?> arguments = const {},
  ]) async {
    if (method == 'readInitial' || method == 'readChanges') {
      return {
        'records': <Object?>[],
        'pageToken': null,
        'changesToken': 'next',
        'hasMore': false,
        'tokenExpired': false,
      };
    }
    return {
      'state': 'granted',
      'grantedMetrics': grantedMetrics.map((metric) => metric.name).toList(),
    };
  }

  @override
  Future<void> openSettings() async {}
}

class _DashboardDiscoveryBridge implements AndroidHealthDiscoveryBridge {
  @override
  Future<Map<String, Object?>> discover() async => {
        'phoneManufacturer': 'Google',
        'phoneModel': 'Pixel',
        'sdkLevel': 33,
        'googleMobileServicesAvailable': true,
        'googlePlayStoreAvailable': true,
        'workProfile': false,
        'healthConnectBuiltIn': false,
        'healthConnectPackageInstalled': true,
        'healthConnectStatus': 'available',
        'permissionState': 'granted',
        'connectionState': 'connected',
        'companions': <Object?>[],
      };
}
