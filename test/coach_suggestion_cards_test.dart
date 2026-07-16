import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  testWidgets('deferred Coach is not reachable in V1', (tester) async {
    final services = HydrionServices.memory();
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    expect(navigationBar.destinations, hasLength(4));
    expect(find.byKey(const Key('nav-coach')), findsNothing);
    expect(find.byKey(const Key('coach-coming-soon')), findsNothing);
  });
}
