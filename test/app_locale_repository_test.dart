import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/locale_registry.dart';
import 'package:hydrion/repositories/app_locale_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/language_selection_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fresh install requires a choice and unsupported device falls back',
      () async {
    final store = MemoryHydrionStore();
    final repository = await AppLocaleRepository.load(
      store,
      deviceLocale: const Locale('ja'),
    );

    expect(repository.selectionCompleted, isFalse);
    expect(repository.mode, HydrionLocaleMode.device);
    expect(repository.locale, const Locale('en'));
  });

  test('explicit application locale persists outside profile settings',
      () async {
    final store = MemoryHydrionStore();
    final repository = await AppLocaleRepository.load(store);
    await repository.selectLocale(const Locale('fr'));
    await store.remove(UserSettingsRepository.storageKey);

    final reloaded = await AppLocaleRepository.load(store);
    expect(reloaded.selectionCompleted, isTrue);
    expect(reloaded.locale, const Locale('fr'));
  });

  test('every production locale transition persists authoritatively', () async {
    const transitions = <(Locale, Locale)>[
      (Locale('en'), Locale('fr')),
      (Locale('fr'), Locale('es')),
      (Locale('es'), Locale('en')),
      (Locale('en'), Locale('es')),
      (Locale('es'), Locale('fr')),
      (Locale('fr'), Locale('en')),
    ];

    for (final (from, to) in transitions) {
      final store = MemoryHydrionStore();
      final repository = await AppLocaleRepository.load(
        store,
        legacyLocale: from,
        establishedUser: true,
      );
      expect(repository.locale, from);

      await repository.selectLocale(to);
      final reloaded = await AppLocaleRepository.load(
        store,
        deviceLocale: const Locale('de'),
      );

      expect(reloaded.mode, HydrionLocaleMode.explicit);
      expect(reloaded.locale, to);
      expect(reloaded.selectionCompleted, isTrue);
    }
  });

  test('existing user migrates once from legacy profile locale', () async {
    final repository = await AppLocaleRepository.load(
      MemoryHydrionStore(),
      legacyLocale: const Locale('es'),
      establishedUser: true,
    );

    expect(repository.selectionCompleted, isTrue);
    expect(repository.locale, const Locale('es'));
  });

  test('android locale refresh keeps first-run language selection pending',
      () async {
    final repository = await AppLocaleRepository.load(
      MemoryHydrionStore(),
      deviceLocale: const Locale('ja'),
    );
    expect(repository.selectionCompleted, isFalse);

    const channel = MethodChannel('hydrion/app_locale');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationLocale') {
        return <String, Object?>{
          'usesDeviceLocale': true,
          'languageTag': 'fr',
        };
      }
      return null;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await repository.refreshFromAndroid();

    expect(repository.selectionCompleted, isFalse);
    expect(repository.locale, const Locale('en'));
  });

  test('only fully ready locale packs are selectable', () {
    expect(
      HydrionLocaleRegistry.productionLocales
          .map((definition) => definition.languageTag),
      ['en', 'fr', 'es'],
    );
    expect(
      HydrionLocaleRegistry.locales
          .where((definition) => !definition.productionReady)
          .map((definition) => definition.languageTag),
      containsAll(['pt-BR', 'de']),
    );
  });

  test(
      'Android per-app locale updates the authoritative repository without a loop',
      () async {
    const channel = MethodChannel('hydrion/app_locale');
    final store = MemoryHydrionStore();
    final repository = AppLocaleRepository.memory(locale: const Locale('en'));
    var platformWrites = 0;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getApplicationLocale') {
        return <String, Object?>{
          'usesDeviceLocale': false,
          'languageTag': 'es',
        };
      }
      if (call.method == 'setApplicationLocale') platformWrites += 1;
      return null;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final persistedRepository = await AppLocaleRepository.load(
      store,
      legacyLocale: repository.locale,
      establishedUser: true,
    );
    await persistedRepository.refreshFromAndroid();

    expect(persistedRepository.locale, const Locale('es'));
    expect(persistedRepository.mode, HydrionLocaleMode.explicit);
    expect(platformWrites, 0);
    final reloaded = await AppLocaleRepository.load(store);
    expect(reloaded.locale, const Locale('es'));
  });

  testWidgets('language screen persists a Spanish first-run choice',
      (tester) async {
    final localeStore = MemoryHydrionStore();
    final localeRepository = await AppLocaleRepository.load(localeStore);
    final settingsStore = MemoryHydrionStore();
    final settingsRepository = await UserSettingsRepository.load(settingsStore);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: localeRepository),
          ChangeNotifierProvider.value(value: settingsRepository),
        ],
        child: MaterialApp(
          routes: {
            '/onboarding': (_) => const Scaffold(body: Text('Onboarding')),
          },
          home: const LanguageSelectionScreen(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('language-es')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('language-continue')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(localeRepository.locale, const Locale('es'));
    expect(localeRepository.selectionCompleted, isTrue);
  });
}
