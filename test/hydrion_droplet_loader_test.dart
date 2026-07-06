import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/ui/components/hydrion_droplet_loader.dart';
import 'package:hydrion/ui/screens/startup_screen.dart';

void main() {
  Widget loaderHarness({
    required double progress,
    bool reducedMotion = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: HydrionDropletLoader(
            progress: progress,
            reducedMotion: reducedMotion,
          ),
        ),
      ),
    );
  }

  testWidgets('droplet renders at 0, 50, and 100 percent', (tester) async {
    for (final progress in [0.0, 0.5, 1.0]) {
      await tester.pumpWidget(loaderHarness(progress: progress));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('hydrion-droplet-loader')), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    }
  });

  testWidgets('droplet progress clamps and exposes useful semantics',
      (tester) async {
    await tester.pumpWidget(loaderHarness(progress: -0.5));
    await tester.pump();
    var semantics = _dropletSemantics(tester);
    expect(semantics.properties.label, 'Loading Hydrion, 0 percent complete');
    expect(semantics.properties.value, '0%');

    await tester.pumpWidget(loaderHarness(progress: 1.4));
    await tester.pumpAndSettle();
    semantics = _dropletSemantics(tester);
    expect(
      semantics.properties.label,
      'Loading Hydrion, 100 percent complete',
    );
    expect(semantics.properties.value, '100%');
  });

  testWidgets('droplet supports reduced motion and clean disposal',
      (tester) async {
    await tester.pumpWidget(
      loaderHarness(progress: 0.5, reducedMotion: true),
    );
    await tester.pump();

    expect(find.byKey(const Key('hydrion-droplet-loader')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup exposes droplet progress and completion handoff',
      (tester) async {
    final warmUp = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => StartupScreen(
                warmUp: () => warmUp.future,
                isOnboardingCompleted: () => true,
              ),
          '/home': (_) => const SizedBox(key: Key('dummy-home')),
        },
      ),
    );

    await tester.pump();
    expect(find.byKey(const Key('startup-droplet-loader')), findsOneWidget);

    warmUp.complete();
    await tester.pump();

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dummy-home')), findsOneWidget);
  });

  testWidgets('startup timeout stops loading and offers recovery actions',
      (tester) async {
    final blocked = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => StartupScreen(
                timeout: const Duration(milliseconds: 20),
                warmUp: () => blocked.future,
                isOnboardingCompleted: () => true,
              ),
          '/home': (_) => const SizedBox(key: Key('dummy-home')),
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump();

    expect(
      find.text('Hydrion took longer than expected to finish startup checks.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('startup-retry')), findsOneWidget);
    expect(find.byKey(const Key('startup-continue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('startup-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dummy-home')), findsOneWidget);
  });
}

Semantics _dropletSemantics(WidgetTester tester) {
  return tester.widget<Semantics>(
    find
        .ancestor(
          of: find.byKey(const Key('hydrion-droplet-loader')),
          matching: find.byType(Semantics),
        )
        .first,
  );
}
