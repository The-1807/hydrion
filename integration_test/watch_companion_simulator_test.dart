import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/hydration_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/watch_connectivity_service.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:integration_test/integration_test.dart';

// Synthetic context only. Run on the isolated paired iPhone after installing
// the watch product. This proves native queuing, not receipt on the watch.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('hydrion/watch_connectivity');

  setUpAll(() {
    expect(defaultTargetPlatform, TargetPlatform.iOS);
    expect(const bool.fromEnvironment('HYDRION_SIMULATOR_VALIDATION'), isTrue);
    expect(const String.fromEnvironment('SIMULATOR_UDID'), isNotEmpty);
  });

  testWidgets('native companion state reports pairing and installed watch app',
      (tester) async {
    Map<Object?, Object?>? state;
    for (var attempt = 0; attempt < 30; attempt++) {
      state = await channel
          .invokeMapMethod<Object?, Object?>('connectionState')
          .timeout(const Duration(seconds: 5));
      if (state?['paired'] == true && state?['watchAppInstalled'] == true) {
        break;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    expect(state?['supported'], isTrue);
    expect(state?['paired'], isTrue);
    expect(state?['watchAppInstalled'], isTrue);
  });

  testWidgets('malformed context fails without exposing payload in diagnostics',
      (tester) async {
    await expectLater(
      channel.invokeMethod<Object?>('updateContext', {'todayMl': -1}),
      throwsA(isA<PlatformException>().having(
        (error) => error.code,
        'code',
        'invalid_arguments',
      )),
    );
  });

  testWidgets('valid synthetic context is queued without claiming delivery',
      (tester) async {
    final result = await channel.invokeMapMethod<Object?, Object?>(
      'updateContext',
      {
        'todayMl': 500,
        'goalMl': 2000,
        'progressPercent': 25,
        'status': 'Synthetic validation',
      },
    ).timeout(const Duration(seconds: 5));
    expect(result?['queued'], isTrue);
    expect(result?['delivered'], isFalse);
    expect(result?['reason'], 'queued');
  });

  testWidgets('manual tracking persists with the native watch service attached',
      (tester) async {
    if (const bool.fromEnvironment('HYDRION_EXPECT_WATCH_UNREACHABLE')) {
      final state = await channel
          .invokeMapMethod<Object?, Object?>('connectionState')
          .timeout(const Duration(seconds: 5));
      expect(state?['reachable'], isFalse);
    }
    // Real simulator preferences, isolated from the application's normal keys.
    final store =
        _ValidationStore(await SharedPreferencesHydrionStore.create());
    final hydration = await HydrationRepository.load(store);
    final settings = await UserSettingsRepository.load(store);
    final locale = await AppLocaleRepository.load(store);
    final service = WatchConnectivityService(
      hydrationRepository: hydration,
      settingsRepository: settings,
      appLocaleRepository: locale,
    );
    try {
      await service.initialize();
      final now = DateTime.now();
      await hydration.addLog(volumeMl: 250, timestamp: now, source: 'manual');
      await service.sync();
      final reopened = await HydrationRepository.load(store);
      expect(reopened.totalForDay(now), 250);
      reopened.dispose();
      expect(settings.settings.dailyGoalMl, UserSettings.defaultDailyGoalMl);
    } finally {
      service.dispose();
      hydration.dispose();
      settings.dispose();
      locale.dispose();
      await store.cleanUp();
    }
  });
}

class _ValidationStore implements HydrionLocalStore {
  _ValidationStore(this.delegate);

  final HydrionLocalStore delegate;
  final String prefix =
      'hydrion.simulator.watch.${DateTime.now().microsecondsSinceEpoch}.';
  final Set<String> writtenKeys = {};

  @override
  Future<String?> readString(String key) => delegate.readString('$prefix$key');

  @override
  Future<void> writeString(String key, String value) async {
    writtenKeys.add(key);
    await delegate.writeString('$prefix$key', value);
  }

  @override
  Future<void> remove(String key) => delegate.remove('$prefix$key');

  Future<void> cleanUp() async {
    for (final key in writtenKeys) {
      await remove(key);
    }
  }
}
