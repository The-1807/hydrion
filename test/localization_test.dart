import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/utils/i18n_resolver.dart';

void main() {
  test('selected locale persists after service reload', () async {
    final store = MemoryHydrionStore();
    final firstServices = await HydrionServices.fromStore(store);

    await firstServices.i18n.setLocale(const Locale('fr'));

    final secondServices = await HydrionServices.fromStore(store);
    expect(secondServices.i18n.locale, const Locale('fr'));
  });

  test('unsupported locale falls back safely to English', () async {
    final services = HydrionServices.memory();

    await services.i18n.setLocale(const Locale('de', 'DE'));

    expect(services.i18n.locale, const Locale('en'));
    expect(
      services.i18n.localeStatus(const Locale('de')),
      LocaleSupportStatus.future,
    );
    expect(
      services.i18n.localeStatus(const Locale('it')),
      LocaleSupportStatus.unsupported,
    );
  });

  testWidgets('Spanish locale changes visible app, home, and settings text',
      (tester) async {
    final services = HydrionServices.memory();
    await services.i18n.setLocale(const Locale('es'));

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Registrar hidratación'), findsOneWidget);
    expect(find.text('Registrar 250 ml'), findsOneWidget);
    expect(find.textContaining('Empieza con 300'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
  });

  testWidgets('French locale changes visible app, home, and settings text',
      (tester) async {
    final services = HydrionServices.memory();
    await services.i18n.setLocale(const Locale('fr'));

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Enregistrer hydratation'), findsOneWidget);
    expect(find.text('Enregistrer 250 ml'), findsOneWidget);
    expect(find.textContaining('Commencez avec 300'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Langue'), findsOneWidget);
  });

  testWidgets('locale controller notifies MaterialApp when locale changes',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    expect(find.text('Log hydration'), findsOneWidget);
    expect(find.textContaining('Start with 300'), findsOneWidget);

    await services.i18n.setLocale(const Locale('es'));
    await tester.pumpAndSettle();

    expect(find.text('Registrar hidratación'), findsOneWidget);
    expect(find.text('Log hydration'), findsNothing);
    expect(find.textContaining('Empieza con 300'), findsOneWidget);
    expect(find.textContaining('Start with 300'), findsNothing);
  });

  testWidgets('generated localization lookup works in widget tests',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Text(AppLocalizations.of(context).settingsTitle);
          },
        ),
      ),
    );

    expect(find.text('Paramètres'), findsOneWidget);
  });
}
