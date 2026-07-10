import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/components/hydrion_startup_shark.dart';
import 'package:hydrion/ui/screens/startup_screen.dart';
import 'package:lottie/lottie.dart';

void main() {
  test('shark JSON asset decodes for the startup animation', () async {
    final data = await rootBundle.load(HydrionStartupShark.sharkAssetPath);
    final composition = await LottieComposition.fromByteData(data);

    expect(composition.durationFrames, greaterThan(0));
    expect(composition.bounds.width, 200);
    expect(composition.bounds.height, 200);
  });

  test('source dotLottie asset is retained and decodes', () async {
    final data = await File(
      HydrionStartupShark.sharkSourceAssetPath,
    ).readAsBytes();
    final composition = await HydrionStartupShark.decodeSharkDotLottie(data);

    expect(composition, isNotNull);
    expect(composition!.durationFrames, greaterThan(0));
    expect(composition.bounds.width, 200);
    expect(composition.bounds.height, 200);
  });

  testWidgets('startup buffer uses only shark lottie and minimal text',
      (tester) async {
    final warmUp = Completer<void>();
    String? selectedRoute;

    await tester.pumpWidget(
      MaterialApp(
        home: StartupScreen(
          warmUp: () => warmUp.future,
          isOnboardingCompleted: () => true,
          minimumDuration: const Duration(seconds: 3),
          onRouteSelected: (route) => selectedRoute = route,
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-shark-loader')), findsOneWidget);
    expect(
      find.byKey(const Key('hydrion-shark-lottie-loader')),
      findsOneWidget,
    );
    expect(find.text(StartupScreen.welcomeText), findsOneWidget);
    expect(find.text(StartupScreen.preparingText), findsNothing);
    expect(find.byKey(const Key('startup-mascot')), findsNothing);
    expect(find.byKey(const Key('startup-droplet-loader')), findsNothing);
    expect(find.byKey(const Key('startup-completion-ring')), findsNothing);
    expect(find.textContaining('Preparing local-first'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(StartupScreen.preparingText), findsOneWidget);
    expect(find.text(StartupScreen.welcomeText), findsNothing);
    expect(selectedRoute, isNull);

    warmUp.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(selectedRoute, isNull);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(selectedRoute, '/home');
  });

  testWidgets('startup supports reduced motion with the shark lottie',
      (tester) async {
    final warmUp = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: StartupScreen(
                  warmUp: () => warmUp.future,
                  isOnboardingCompleted: () => true,
                ),
              ),
          '/home': (_) => const SizedBox(key: Key('dummy-home')),
        },
      ),
    );
    await tester.pump();

    final dynamic lottie = tester.widget(
      find.byKey(const Key('hydrion-shark-lottie-loader')),
    );
    expect(lottie.animate, isFalse);
    expect(find.byKey(const Key('startup-shark-loader')), findsOneWidget);
    expect(find.byKey(const Key('hydrion-droplet-fallback')), findsNothing);

    warmUp.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dummy-home')), findsOneWidget);
  });

  testWidgets('fresh install bootstrap shows buffer before onboarding',
      (tester) async {
    final services = await HydrionServices.fromStore(MemoryHydrionStore());
    final servicesReady = Completer<HydrionServices>();

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: const Duration(seconds: 3),
        servicesLoader: () => servicesReady.future,
      ),
    );
    await tester.pump();

    expect(find.text(StartupScreen.welcomeText), findsOneWidget);
    expect(find.byKey(const Key('startup-shark-loader')), findsOneWidget);

    servicesReady.complete(services);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(StartupScreen.preparingText), findsOneWidget);
    expect(find.text('Welcome to Hydrion'), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Hydrion'), findsOneWidget);
  });

  testWidgets('returning user bootstrap shows same buffer before home',
      (tester) async {
    final services = HydrionServices.memory();
    final servicesReady = Completer<HydrionServices>();

    await tester.pumpWidget(
      HydrionBootstrapApp(
        startupMinimumDuration: const Duration(seconds: 3),
        servicesLoader: () => servicesReady.future,
      ),
    );
    await tester.pump();

    expect(find.text(StartupScreen.welcomeText), findsOneWidget);
    expect(find.byKey(const Key('startup-shark-loader')), findsOneWidget);

    servicesReady.complete(services);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(StartupScreen.preparingText), findsOneWidget);
    expect(find.byKey(const Key('hydrion-bottom-nav')), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hydrion-bottom-nav')), findsOneWidget);
  });
}
