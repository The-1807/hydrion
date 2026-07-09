import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/legal_document_registry.dart';
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
    expect(find.text('Shark companion'), findsNothing);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-terms-accept')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();
    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-health-ack')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-logo')), findsOneWidget);

    final reloaded = await UserSettingsRepository.load(store);
    expect(reloaded.settings.nickname, 'Avery');
    expect(reloaded.settings.onboardingCompleted, isTrue);
    expect(reloaded.settings.legalAndHealthAcknowledged, isTrue);
    expect(
      reloaded.settings.acceptedTermsVersion,
      HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
    );
    expect(reloaded.settings.acceptedTermsAt, isNotNull);
    expect(
      reloaded.settings.acknowledgedHealthDisclaimerVersion,
      HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
    );
    expect(reloaded.settings.acknowledgedHealthDisclaimerAt, isNotNull);
    expect(
      reloaded.settings.privacyPolicyVersionShown,
      HydrionLegalAcceptancePolicy.currentPrivacyNoticeVersion,
    );
  });

  testWidgets('returning users skip onboarding after startup', (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-logo')), findsOneWidget);
    expect(find.text('Welcome to Hydrion'), findsNothing);
  });

  testWidgets('partial onboarding resumes at the saved step after relaunch',
      (tester) async {
    final store = MemoryHydrionStore();
    final services = await HydrionServices.fromStore(store);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('onboarding-nickname')),
      'Riley',
    );
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();

    final saved = await UserSettingsRepository.load(store);
    expect(saved.settings.onboardingCompleted, isFalse);
    expect(saved.settings.onboardingStep, 2);
    expect(saved.settings.nickname, 'Riley');

    final relaunchedServices = await HydrionServices.fromStore(store);
    await tester.pumpWidget(HydrionApp(services: relaunchedServices));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-avatar-grid')), findsOneWidget);
    expect(find.text('Welcome to Hydrion'), findsOneWidget);
    expect(find.text('Basic profile'), findsNothing);
  });

  testWidgets('legacy completed users missing completion flag avoid onboarding',
      (tester) async {
    final store = MemoryHydrionStore();
    await store.writeString(
      UserSettingsRepository.storageKey,
      '{"languageCode":"en","dailyGoalMl":2200,'
      '"nickname":"Legacy Shark",'
      '"legalAndHealthAcknowledged":true}',
    );
    final services = await HydrionServices.fromStore(store);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(services.settingsRepository.settings.onboardingCompleted, isTrue);
    expect(find.text('Welcome to Hydrion'), findsNothing);
    expect(find.text('Review Hydrion terms'), findsOneWidget);
  });

  testWidgets('existing users get focused legal migration without data loss',
      (tester) async {
    final store = MemoryHydrionStore();
    await store.writeString(
      UserSettingsRepository.storageKey,
      '{"languageCode":"en","dailyGoalMl":2200,'
      '"onboardingCompleted":true,'
      '"legalAndHealthAcknowledged":true}',
    );
    final services = await HydrionServices.fromStore(store);
    await services.hydrationRepository.addLog(
      volumeMl: 450,
      timestamp: DateTime(2026, 7, 6, 9),
      source: 'migration-test',
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('Review Hydrion terms'), findsOneWidget);
    expect(find.byKey(const Key('onboarding-terms-accept')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-health-ack')), findsOneWidget);
    expect(services.hydrationRepository.logs.single.volumeMl, 450);

    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-terms-accept')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();
    tester
        .widget<CheckboxListTile>(
          find.byKey(const Key('onboarding-health-ack')),
        )
        .onChanged
        ?.call(true);
    await tester.pump();
    await tester.tap(find.byKey(const Key('legal-review-continue')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-logo')), findsOneWidget);
    expect(services.hydrationRepository.logs.single.volumeMl, 450);
    expect(
      services.settingsRepository.settings.acceptedTermsVersion,
      HydrionLegalAcceptancePolicy.requiredTermsAcceptanceVersion,
    );
    expect(
      services.settingsRepository.settings.acknowledgedHealthDisclaimerVersion,
      HydrionLegalAcceptancePolicy.requiredHealthAcknowledgementVersion,
    );
  });

  testWidgets('startup supports reduced motion rendering', (tester) async {
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

    expect(find.byKey(const Key('startup-mascot')), findsOneWidget);

    warmUp.complete();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dummy-home')), findsOneWidget);
  });
}
