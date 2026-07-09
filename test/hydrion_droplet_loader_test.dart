import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
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
      expect(
        find.byKey(const Key('hydrion-shark-lottie-loader')),
        findsOneWidget,
      );
    }
  });

  test('shark dotLottie asset decodes from the bundled animation file',
      () async {
    final data = await rootBundle.load(HydrionDropletLoader.sharkAssetPath);
    final composition = await HydrionDropletLoader.decodeSharkDotLottie(
      Uint8List.sublistView(data),
    );

    expect(composition, isNotNull);
    expect(composition!.durationFrames, greaterThan(0));
    expect(composition.bounds.width, 200);
    expect(composition.bounds.height, 200);
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
    expect(find.byKey(const Key('hydrion-droplet-fallback')), findsOneWidget);

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

  testWidgets('bootstrap shows shark loader while services warm up',
      (tester) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.completeOnboardingWithLegalReview(
      reviewedAt: DateTime(2026, 7, 9),
    );
    final servicesReady = Completer<HydrionServices>();

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: const Duration(seconds: 3),
        servicesLoader: () => servicesReady.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-droplet-loader')), findsOneWidget);
    expect(
      find.byKey(const Key('hydrion-shark-lottie-loader')),
      findsOneWidget,
    );

    servicesReady.complete(services);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('startup-droplet-loader')), findsOneWidget);
    expect(find.byKey(const Key('hydrion-bottom-nav')), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
    expect(find.byKey(const Key('startup-droplet-loader')), findsNothing);
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
