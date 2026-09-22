import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/android_health_provider.dart';
import '../utils/startup_trace.dart';

abstract interface class AndroidHealthDiscoveryBridge {
  Future<Map<String, Object?>> discover();
}

class MethodChannelAndroidHealthDiscoveryBridge
    implements AndroidHealthDiscoveryBridge {
  static const _channel = MethodChannel(
    'hydrion/android_health_provider_discovery',
  );

  const MethodChannelAndroidHealthDiscoveryBridge();

  @override
  Future<Map<String, Object?>> discover() async {
    final timer = Stopwatch()..start();
    late final Map<String, Object?>? result;
    try {
      result = await _channel
          .invokeMapMethod<String, Object?>('discover')
          .timeout(const Duration(seconds: 10));
    } finally {
      HydrionStartupTrace.log('health provider discovery complete', data: {
        'elapsedMs': timer.elapsedMilliseconds,
      });
    }
    if (result == null) {
      throw const FormatException(
          'Android provider discovery returned no data.');
    }
    return result;
  }
}

class AndroidHealthProviderDiscovery {
  final AndroidHealthDiscoveryBridge _bridge;
  final bool _forceAndroidForTesting;

  const AndroidHealthProviderDiscovery({
    AndroidHealthDiscoveryBridge bridge =
        const MethodChannelAndroidHealthDiscoveryBridge(),
    bool forceAndroidForTesting = false,
  })  : _bridge = bridge,
        _forceAndroidForTesting = forceAndroidForTesting;

  Future<AndroidHealthEnvironment> discover() async {
    if (!_forceAndroidForTesting &&
        (kIsWeb || defaultTargetPlatform != TargetPlatform.android)) {
      return const AndroidHealthEnvironment(
        phoneManufacturer: 'unknown',
        phoneModel: 'unknown',
        sdkLevel: 0,
        googleMobileServicesAvailable: false,
        googlePlayStoreAvailable: false,
        workProfile: false,
        healthConnectBuiltIn: false,
        healthConnectPackageInstalled: false,
        healthConnectStatus: AndroidHealthProviderStatus.unsupported,
        companionServices: [],
      );
    }

    try {
      return _parse(await _bridge.discover());
    } on MissingPluginException {
      return _unavailable(AndroidHealthProviderStatus.unsupported);
    } on PlatformException {
      return _unavailable(AndroidHealthProviderStatus.temporarilyUnavailable);
    } on FormatException {
      return _unavailable(AndroidHealthProviderStatus.configurationError);
    }
  }

  AndroidHealthEnvironment _parse(Map<String, Object?> value) {
    final companions = (value['companions'] as List<Object?>? ?? const [])
        .map((entry) => _parseService(entry as Map<Object?, Object?>))
        .toList(growable: false);
    return AndroidHealthEnvironment(
      phoneManufacturer: _string(value, 'phoneManufacturer'),
      phoneModel: _string(value, 'phoneModel'),
      sdkLevel: _integer(value, 'sdkLevel'),
      googleMobileServicesAvailable:
          _boolean(value, 'googleMobileServicesAvailable'),
      googlePlayStoreAvailable: _boolean(value, 'googlePlayStoreAvailable'),
      workProfile: _boolean(value, 'workProfile'),
      healthConnectBuiltIn: _boolean(value, 'healthConnectBuiltIn'),
      healthConnectPackageInstalled:
          _boolean(value, 'healthConnectPackageInstalled'),
      healthConnectStatus: _enumByName(
        AndroidHealthProviderStatus.values,
        _string(value, 'healthConnectStatus'),
      ),
      permissionState: _enumByName(
        AndroidHealthPermissionState.values,
        _string(value, 'permissionState'),
      ),
      connectionState: _enumByName(
        AndroidHealthConnectionState.values,
        _string(value, 'connectionState'),
      ),
      companionServices: companions,
    );
  }

  AndroidHealthService _parseService(Map<Object?, Object?> value) =>
      AndroidHealthService(
        packageName: _serviceString(value, 'packageName'),
        serviceName: _serviceString(value, 'serviceName'),
        kind: _enumByName(
          AndroidHealthServiceKind.values,
          _serviceString(value, 'kind'),
        ),
        installed: _serviceBoolean(value, 'installed'),
        enabled: _serviceBoolean(value, 'enabled'),
        exportStatus: _enumByName(
          AndroidHealthExportStatus.values,
          _serviceString(value, 'exportStatus'),
        ),
        route: _enumByName(
          AndroidHealthIntegrationRoute.values,
          _serviceString(value, 'route'),
        ),
      );

  AndroidHealthEnvironment _unavailable(AndroidHealthProviderStatus status) =>
      AndroidHealthEnvironment(
        phoneManufacturer: 'unknown',
        phoneModel: 'unknown',
        sdkLevel: 0,
        googleMobileServicesAvailable: false,
        googlePlayStoreAvailable: false,
        workProfile: false,
        healthConnectBuiltIn: false,
        healthConnectPackageInstalled: false,
        healthConnectStatus: status,
        companionServices: const [],
      );

  static String _string(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! String || result.trim().isEmpty) {
      throw FormatException('Missing provider discovery field: $key');
    }
    return result;
  }

  static int _integer(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! int) throw FormatException('Invalid field: $key');
    return result;
  }

  static bool _boolean(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! bool) throw FormatException('Invalid field: $key');
    return result;
  }

  static String _serviceString(Map<Object?, Object?> value, String key) {
    final result = value[key];
    if (result is! String || result.trim().isEmpty) {
      throw FormatException('Invalid companion field: $key');
    }
    return result;
  }

  static bool _serviceBoolean(Map<Object?, Object?> value, String key) {
    final result = value[key];
    if (result is! bool) throw FormatException('Invalid companion field: $key');
    return result;
  }

  static T _enumByName<T extends Enum>(List<T> values, String name) {
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Unknown provider state: $name'),
    );
  }
}
