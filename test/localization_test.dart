import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/utils/i18n_resolver.dart';

void main() {
  test('selected locale persists after service reload', () async {
    final store = MemoryHydrionStore();
    final first = await HydrionServices.fromStore(store);
    await first.i18n.setLocale(const Locale('fr'));
    final second = await HydrionServices.fromStore(store);
    expect(second.i18n.locale, const Locale('fr'));
  });

  test('unsupported locale falls back safely to English', () async {
    final services = HydrionServices.memory();
    await services.i18n.setLocale(const Locale('de', 'DE'));
    expect(services.i18n.locale, const Locale('en'));
    expect(services.i18n.localeStatus(const Locale('de')),
        LocaleSupportStatus.future);
  });

  for (final locale in const [Locale('es'), Locale('fr')]) {
    testWidgets('${locale.languageCode} localizes Home and Settings controls',
        (tester) async {
      final services = HydrionServices.memory();
      await services.i18n.setLocale(locale);
      final strings = lookupAppLocalizations(locale);

      await tester.pumpWidget(HydrionApp(services: services));
      await tester.pumpAndSettle();
      expect(find.text(strings.logHydration), findsOneWidget);
      expect(find.text(strings.logVolume(volumeMl: 250)), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      expect(find.text(strings.settingsTitle), findsOneWidget);
      expect(find.byKey(const Key('settings-locale-picker')), findsOneWidget);
    });
  }

  testWidgets('locale changes apply to visible Home copy', (tester) async {
    final services = HydrionServices.memory();
    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    final english = lookupAppLocalizations(const Locale('en'));
    final spanish = lookupAppLocalizations(const Locale('es'));
    expect(find.text(english.logHydration), findsOneWidget);

    await services.i18n.setLocale(const Locale('es'));
    await tester.pumpAndSettle();
    expect(find.text(spanish.logHydration), findsOneWidget);
    expect(find.text(english.logHydration), findsNothing);
  });
}
