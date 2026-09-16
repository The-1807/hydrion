import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/android_health_provider.dart';
import 'package:hydrion/services/android_health_provider_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('keeps phone, health service and companion application distinct',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final discovery = AndroidHealthProviderDiscovery(
      bridge: _FakeBridge(_infinixFixture()),
    );

    final result = await discovery.discover();

    expect(result.phoneManufacturer, 'INFINIX');
    expect(result.phoneModel, 'Infinix X6835B');
    expect(result.healthConnectStatus,
        AndroidHealthProviderStatus.installationRequired);
    expect(result.canRequestHealthConnectPermission, isFalse);
    expect(result.manualHydrationAvailable, isTrue);
    expect(result.permissionState, AndroidHealthPermissionState.notRequested);
    expect(result.connectionState, AndroidHealthConnectionState.disconnected);
    final fitPro = result.companionServices.singleWhere(
      (service) => service.packageName == 'cn.xiaofengkj.fitpro',
    );
    expect(fitPro.installed, isTrue);
    expect(fitPro.kind, AndroidHealthServiceKind.companionApp);
    expect(fitPro.exportStatus, AndroidHealthExportStatus.requiresVerification);
    expect(fitPro.route, AndroidHealthIntegrationRoute.unknown);
  });

  test('work profile remains explicitly unsupported despite an available hub',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = _infinixFixture()
      ..['workProfile'] = true
      ..['healthConnectStatus'] = 'workProfileUnsupported'
      ..['healthConnectPackageInstalled'] = true;
    final result = await AndroidHealthProviderDiscovery(
      bridge: _FakeBridge(fixture),
    ).discover();

    expect(result.workProfile, isTrue);
    expect(result.healthConnectStatus,
        AndroidHealthProviderStatus.workProfileUnsupported);
    expect(result.canRequestHealthConnectPermission, isFalse);
  });

  test('keeps connection and permission failures distinct', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final fixture = _infinixFixture()
      ..['healthConnectStatus'] = 'available'
      ..['healthConnectPackageInstalled'] = true
      ..['permissionState'] = 'revoked'
      ..['connectionState'] = 'connectedRequiredMetricUnavailable';

    final result = await AndroidHealthProviderDiscovery(
      bridge: _FakeBridge(fixture),
    ).discover();

    expect(result.healthConnectStatus, AndroidHealthProviderStatus.available);
    expect(result.permissionState, AndroidHealthPermissionState.revoked);
    expect(
      result.connectionState,
      AndroidHealthConnectionState.connectedRequiredMetricUnavailable,
    );
    expect(result.manualHydrationAvailable, isTrue);
  });

  test('malformed native state fails closed as a configuration error',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final result = await const AndroidHealthProviderDiscovery(
      bridge: _FakeBridge(<String, Object?>{'phoneManufacturer': 'INFINIX'}),
    ).discover();

    expect(
      result.healthConnectStatus,
      AndroidHealthProviderStatus.configurationError,
    );
    expect(result.canRequestHealthConnectPermission, isFalse);
  });
}

Map<String, Object?> _infinixFixture() => <String, Object?>{
      'phoneManufacturer': 'INFINIX',
      'phoneModel': 'Infinix X6835B',
      'sdkLevel': 33,
      'googleMobileServicesAvailable': true,
      'googlePlayStoreAvailable': true,
      'workProfile': false,
      'healthConnectBuiltIn': false,
      'healthConnectPackageInstalled': false,
      'healthConnectStatus': 'installationRequired',
      'permissionState': 'notRequested',
      'connectionState': 'disconnected',
      'companions': <Object?>[
        <Object?, Object?>{
          'packageName': 'cn.xiaofengkj.fitpro',
          'serviceName': 'FitPro',
          'kind': 'companionApp',
          'installed': true,
          'enabled': true,
          'exportStatus': 'requiresVerification',
          'route': 'unknown',
        },
      ],
    };

class _FakeBridge implements AndroidHealthDiscoveryBridge {
  final Map<String, Object?> value;

  const _FakeBridge(this.value);

  @override
  Future<Map<String, Object?>> discover() async => value;
}
