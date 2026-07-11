import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  testWidgets('Coach remains a non-interactive V1 future-update notice',
      (tester) async {
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
    navigationBar.onDestinationSelected?.call(3);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach-coming-soon')), findsOneWidget);
    expect(find.text('Coach'), findsWidgets);
    expect(find.textContaining('future update'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('coach-send-button')), findsNothing);
  });
}
