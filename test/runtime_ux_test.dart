import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  Future<void> scrollToHomeItem(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selected hydration amount updates Home, Log, and Analytics',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('0 / 2200 ml'), findsOneWidget);

    await tester.tap(find.byKey(const Key('volume-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('500 ml').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('log-water-button')));
    await tester.pumpAndSettle();

    expect(find.text('500 / 2200 ml'), findsOneWidget);

    await scrollToHomeItem(tester, find.byKey(const Key('route-/log')));
    await tester.tap(find.byKey(const Key('route-/log')));
    await tester.pumpAndSettle();

    expect(find.text('500 ml'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await scrollToHomeItem(tester, find.byKey(const Key('route-/analytics')));
    await tester.tap(find.byKey(const Key('route-/analytics')));
    await tester.pumpAndSettle();

    expect(find.text('500 / 2200 ml today'), findsOneWidget);
    expect(find.text('Local estimate from all saved hydration logs.'),
        findsOneWidget);
  });

  testWidgets('fallback-only actions are gated and labeled', (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('Voice commands are a future local feature'),
      findsOneWidget,
    );
    await scrollToHomeItem(tester, find.byKey(const Key('route-/ar')));
    expect(find.text('AR future'), findsOneWidget);

    await tester.tap(find.byTooltip('Save local reminder'));
    await tester.pumpAndSettle();

    expect(services.reminderRepository.reminders, hasLength(1));
    expect(find.text('Local reminder saved'), findsOneWidget);
  });

  testWidgets('local challenge join state is persisted in app services',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await scrollToHomeItem(tester, find.byKey(const Key('route-/challenges')));
    await tester.tap(find.byKey(const Key('route-/challenges')));
    await tester.pumpAndSettle();

    expect(find.text('Local challenge mode'), findsOneWidget);
    await tester.tap(find.text('Join'));
    await tester.pumpAndSettle();

    expect(services.challengeRepository.activeChallenge, isNotNull);
    expect(find.text('Joined'), findsOneWidget);
  });
}
