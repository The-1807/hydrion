import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/watch_connectivity_service.dart';

/// D11 (watch/startup part): the watch bridge must decide support from the
/// Flutter target-platform capability, never from `dart:io Platform`, which
/// throws `UnsupportedError` on Web.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hydrion/watch_connectivity');
  late List<MethodCall> calls;
  late HydrationRepository hydration;
  late UserSettingsRepository settings;
  late AppLocaleRepository locale;

  setUp(() {
    calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <Object?, Object?>{'status': 'queued'};
    });
    hydration = HydrationRepository.memory();
    settings = UserSettingsRepository.memory();
    locale = AppLocaleRepository.memory();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  WatchConnectivityService build({bool? isSupported}) =>
      WatchConnectivityService(
        hydrationRepository: hydration,
        settingsRepository: settings,
        appLocaleRepository: locale,
        isSupported: isSupported,
      );

  test('iOS target platform enables the watch bridge (capability, not host)',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = build();
    addTearDown(service.dispose);

    expect(service.isSupported, isTrue);
    await service.initialize();

    expect(calls.map((call) => call.method), ['updateContext']);
  });

  test(
      'Web-equivalent unsupported capability is an explicit no-op: '
      'no listeners and no channel calls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = build(isSupported: false);
    addTearDown(service.dispose);

    await service.initialize();
    await service.sync();
    await hydration.addLog(volumeMl: 250, timestamp: DateTime.now());
    await settings.setDailyGoalMl(2600);
    await Future<void>.delayed(Duration.zero);

    expect(service.isSupported, isFalse);
    expect(calls, isEmpty);
  });

  test('non-iOS target platforms are explicit no-ops', () async {
    for (final platform in [
      TargetPlatform.android,
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.fuchsia,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      final service = build();
      expect(service.isSupported, isFalse, reason: platform.name);
      await service.initialize();
      await service.sync();
      service.dispose();
    }
    expect(calls, isEmpty);
  });

  test('watch bridge does not depend on dart:io Platform', () {
    final source =
        File('lib/services/watch_connectivity_service.dart').readAsStringSync();
    expect(source, isNot(contains("import 'dart:io'")));
    expect(source, isNot(contains('Platform.is')));
  });
}
