import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';

void main() {
  testWidgets('Hydrion app shell boots from the root package', (tester) async {
    await tester.pumpWidget(HydrionApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('home-logo')), findsOneWidget);
    expect(find.text('Hydrion'), findsOneWidget);
    expect(find.text('Log 250 ml'), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
