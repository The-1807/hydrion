import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/startup_screen.dart';

void main() {
  testWidgets('first run shows onboarding and completion persists',
      (tester) async {
    final store = MemoryHydrionStore();
    final services = await HydrionServices.fromStore(store);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Hydrion'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-mascot')), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('onboarding-nickname')),
      'Avery',
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-avatar-grid')), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-legal-ack')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-logo')), findsOneWidget);

    final reloaded = await UserSettingsRepository.load(store);
    expect(reloaded.settings.nickname, 'Avery');
    expect(reloaded.settings.onboardingCompleted, isTrue);
    expect(reloaded.settings.legalAndHealthAcknowledged, isTrue);
  });

  testWidgets('returning users skip onboarding after startup', (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-logo')), findsOneWidget);
    expect(find.text('Welcome to Hydrion'), findsNothing);
  });

  testWidgets('startup supports reduced motion rendering', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => MediaQuery(
                data: const MediaQueryData(disableAnimations: true),
                child: StartupScreen(
                  minimumDuration: const Duration(seconds: 1),
                  warmUp: () async {},
                  isOnboardingCompleted: () => true,
                ),
              ),
          '/home': (_) => const SizedBox(key: Key('dummy-home')),
        },
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('startup-mascot')), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dummy-home')), findsOneWidget);
  });
}
