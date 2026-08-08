import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/repositories/guided_tour_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/storage/local_store.dart';
import 'package:hydrion/ui/screens/mission_screen.dart';
import 'package:provider/provider.dart';

void main() {
  test('mission handled state persists and legacy completed users are spared',
      () async {
    final legacy = UserSettings.fromJson({
      'languageCode': 'en',
      'onboardingCompleted': true,
    });
    expect(legacy.missionIntroductionHandled, isTrue);

    final store = MemoryHydrionStore();
    final repository = await UserSettingsRepository.load(store);
    expect(repository.settings.missionIntroductionHandled, isFalse);
    await repository.setMissionIntroductionHandled(true);
    final reloaded = await UserSettingsRepository.load(store);
    expect(reloaded.settings.missionIntroductionHandled, isTrue);
  });

  testWidgets('onboarding mission continues into the first-run tour',
      (tester) async {
    final services = HydrionServices.memory(
      guidedTourRepository: GuidedTourRepository.memory(completed: true),
    );

    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/mission'),
    );
    await tester.pumpAndSettle();

    expect(services.guidedTourRepository.shouldShowCoreTour, isFalse);

    await tester.tap(find.byKey(const Key('mission-continue')));
    await tester.pumpAndSettle();

    expect(services.guidedTourRepository.shouldShowCoreTour, isTrue);
    expect(services.settingsRepository.settings.missionIntroductionHandled,
        isTrue);
  });

  testWidgets('mission has one continuation and does not replay after restart',
      (tester) async {
    final store = MemoryHydrionStore();
    const settings = UserSettings(
      locale: Locale('en'),
      onboardingCompleted: true,
      missionIntroductionHandled: false,
    );
    await store.writeString(
      UserSettingsRepository.storageKey,
      jsonEncode(settings.toJson()),
    );
    final services = await HydrionServices.fromStore(store);

    await tester.pumpWidget(
      HydrionApp(services: services, initialRoute: '/mission'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Why Hydrion exists'), findsOneWidget);
    expect(find.byKey(const Key('mission-skip')), findsNothing);
    await tester.tap(find.byKey(const Key('mission-continue')));
    await tester.pumpAndSettle();
    expect(services.settingsRepository.settings.missionIntroductionHandled,
        isTrue);

    final reloaded = await UserSettingsRepository.load(store);
    expect(reloaded.settings.missionIntroductionHandled, isTrue);
  });

  testWidgets('Discord action stays unavailable until an invite is approved',
      (tester) async {
    final repository = UserSettingsRepository.memory();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: repository,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MissionScreen(fromOnboarding: true),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('mission-join-community')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Community link coming later'), findsOneWidget);
    expect(find.textContaining('discord.com'), findsNothing);
  });

  testWidgets('farewell is profile-free and Finish returns to clean start',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          '/onboarding': (_) => const Scaffold(body: Text('Clean start')),
        },
        home: const ProfileDeletionFarewellScreen(),
      ),
    );

    expect(find.text('Your Hydrion profile has been deleted'), findsOneWidget);
    expect(find.textContaining('nickname'), findsNothing);
    expect(find.textContaining('health data'), findsNothing);
    await tester.tap(find.byKey(const Key('farewell-finish')));
    await tester.pumpAndSettle();
    expect(find.text('Clean start'), findsOneWidget);
  });
}
