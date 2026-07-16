import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  Future<HydrionServices> pumpApp(WidgetTester tester) async {
    final services = HydrionServices.memory();
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    return services;
  }

  Future<void> openTab(WidgetTester tester, int index) async {
    final navigation = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    navigation.onDestinationSelected?.call(index);
    await tester.pumpAndSettle();
  }

  testWidgets('product QA: deferred Coach is absent from V1', (tester) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('nav-coach')), findsNothing);
    expect(find.byKey(const Key('coach-coming-soon')), findsNothing);
  });

  testWidgets('product QA: Settings expose working V1 controls only',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-locale-picker')), findsOneWidget);
    expect(find.byKey(const Key('settings-daily-goal-field')), findsOneWidget);
    expect(find.text('Reusable container'), findsOneWidget);
    expect(find.text('Legal, privacy, and support'), findsOneWidget);
    expect(find.textContaining('Gemini'), findsNothing);
    expect(find.textContaining('provider'), findsNothing);
    expect(find.textContaining('diagnostic'), findsNothing);
    expect(find.textContaining('adapter'), findsNothing);
  });

  testWidgets('product QA: Home hydration logging remains accessible',
      (tester) async {
    final services = await pumpApp(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('log-water-button')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('log-water-button')));
    await tester.pumpAndSettle();
    expect(services.hydrationRepository.logs, hasLength(1));
  });

  testWidgets('product QA: Challenges remain usable', (tester) async {
    final services = await pumpApp(tester);
    await openTab(tester, 1);
    final join = find.byKey(const Key('join-bottle-bingo'));
    await tester.scrollUntilVisible(
      join,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(join);
    await tester.pumpAndSettle();
    await tester.tap(join);
    await tester.pumpAndSettle();
    expect(services.challengeRepository.activeChallenge?.id, 'bottle-bingo');
  });

  testWidgets('product QA: Legal and support information remains reachable',
      (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    final legal = find.text('Legal, privacy, and support');
    await tester.scrollUntilVisible(
      legal,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(legal);
    await tester.pumpAndSettle();
    expect(find.text('About & Legal'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
