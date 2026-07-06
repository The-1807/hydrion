import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final services = HydrionServices.memory();
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: HydrionApp(services: services),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('compact phone renders Home without overflow', (tester) async {
    await pumpAtSize(tester, const Size(360, 640), textScale: 1.35);

    expect(find.byKey(const Key('hydration-progress-gauge')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('log-water-button')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log-water-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet renders progress and legal surfaces', (tester) async {
    await pumpAtSize(tester, const Size(834, 1112), textScale: 1.2);

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    navigationBar.onDestinationSelected?.call(2);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weekly-hydration-strip')), findsOneWidget);

    navigationBar.onDestinationSelected?.call(4);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-legal-action')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('profile-legal-action')));
    await tester.pumpAndSettle();
    expect(find.text('About & Legal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape phone keeps quick logging reachable', (tester) async {
    await pumpAtSize(tester, const Size(844, 390), textScale: 1.15);

    await tester.scrollUntilVisible(
      find.byKey(const Key('log-water-button')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('log-water-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
