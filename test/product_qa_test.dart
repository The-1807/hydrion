import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  Future<void> pumpHydrion(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    HydrionServices? services,
  }) async {
    final appServices = services ?? HydrionServices.memory();
    await appServices.i18n.setLocale(locale);
    await tester.pumpWidget(HydrionApp(services: appServices));
    await tester.pumpAndSettle();
  }

  Future<void> scrollToHomeItem(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('product QA: English localized app shell', (tester) async {
    await pumpHydrion(tester);

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Log hydration'), findsOneWidget);
    expect(find.text('Log 250 ml'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('product QA: Spanish localized app shell', (tester) async {
    await pumpHydrion(tester, locale: const Locale('es'));

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Registrar hidratación'), findsOneWidget);
    expect(find.text('Registrar 250 ml'), findsOneWidget);
  });

  testWidgets('product QA: French localized app shell', (tester) async {
    await pumpHydrion(tester, locale: const Locale('fr'));

    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Enregistrer hydratation'), findsOneWidget);
    expect(find.text('Enregistrer 250 ml'), findsOneWidget);
  });

  testWidgets('product QA: small mobile viewport keeps Home usable',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final services = HydrionServices.memory();
    await pumpHydrion(tester, services: services);

    expect(find.byKey(const Key('home-logo')), findsOneWidget);
    expect(find.byKey(const Key('volume-picker')), findsOneWidget);

    await tester.tap(find.byKey(const Key('volume-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('350 ml').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('log-water-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('log-water-button')));
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.totalForDay(DateTime.now()), 350);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('350 / 2200 ml'), findsOneWidget);
  });

  testWidgets('product QA: Settings capability dashboard is honest',
      (tester) async {
    await pumpHydrion(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.text('Standalone local mode'), findsOneWidget);
    expect(find.text('Runtime feature status'), findsOneWidget);
    expect(find.text('Local persistence'), findsOneWidget);
    expect(find.text('ELKA adapter'), findsOneWidget);
    expect(find.text('Unconfigured'), findsOneWidget);
    expect(find.text('Cloud AI'), findsOneWidget);
    expect(find.text('Voice input'), findsOneWidget);
    expect(find.text('Disabled'), findsWidgets);
  });

  testWidgets('product QA: empty states are reachable and explicit',
      (tester) async {
    await pumpHydrion(tester);

    await scrollToHomeItem(tester, find.byKey(const Key('route-/log')));
    await tester.tap(find.byKey(const Key('route-/log')));
    await tester.pumpAndSettle();
    expect(find.text('No hydration logs found'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollToHomeItem(tester, find.byKey(const Key('route-/analytics')));
    await tester.tap(find.byKey(const Key('route-/analytics')));
    await tester.pumpAndSettle();
    expect(find.text('No analytics yet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollToHomeItem(tester, find.byKey(const Key('route-/reminders')));
    await tester.tap(find.byKey(const Key('route-/reminders')));
    await tester.pumpAndSettle();
    expect(find.text('No local reminders saved'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollToHomeItem(tester, find.byKey(const Key('route-/challenges')));
    await tester.tap(find.byKey(const Key('route-/challenges')));
    await tester.pumpAndSettle();
    expect(find.text('No active challenge yet'), findsOneWidget);
  });

  testWidgets('product QA: Coach fallback flow stays local', (tester) async {
    await pumpHydrion(tester);

    await scrollToHomeItem(tester, find.byKey(const Key('route-/chat')));
    await tester.tap(find.byKey(const Key('route-/chat')));
    await tester.pumpAndSettle();

    expect(find.text('Local fallback coach'), findsOneWidget);
    expect(
      find.textContaining('No cloud AI or ELKA is connected'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'How am I doing?');
    final sendButton = find.widgetWithIcon(FilledButton, Icons.send);
    await tester.ensureVisible(sendButton);
    await tester.pumpAndSettle();
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hydrion is running in local deterministic mode'),
      findsOneWidget,
    );
  });
}
