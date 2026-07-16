import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/domain/challenge_catalog.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/profile_photo_service.dart';

void main() {
  Future<void> openLogHistory(WidgetTester tester) async {
    final history = find.byKey(const Key('home-log-history'));
    await tester.ensureVisible(history);
    await tester.pumpAndSettle();
    await tester.tap(history);
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, Key key) async {
    final navigationBar = tester.widget<NavigationBar>(
      find.byKey(const Key('hydrion-bottom-nav')),
    );
    navigationBar.onDestinationSelected?.call(_tabIndex(key));
    await tester.pumpAndSettle();
  }

  testWidgets('selected hydration amount updates Home, Log, and Analytics',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(find.text('0 ml / 2200 ml'), findsOneWidget);
    expect(find.text('Today\'s hydration rhythm'), findsNothing);
    expect(find.byKey(const Key('hydration-rhythm-card-0')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const Key('quick-volume-500')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    tester
        .widget<ChoiceChip>(find.byKey(const Key('quick-volume-500')))
        .onSelected
        ?.call(true);
    await tester.pumpAndSettle();

    final dynamic logButton =
        tester.widget(find.byKey(const Key('log-water-button')));
    logButton.onPressed();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('500 ml / 2200 ml'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('500 ml / 2200 ml'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await openLogHistory(tester);
    expect(find.text('500 ml'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab(tester, const Key('nav-progress'));

    expect(find.byKey(const Key('weekly-hydration-strip')), findsOneWidget);
    expect(find.text('500 / 2200 ml today'), findsOneWidget);
    expect(find.text('Achievements'), findsNothing);
    expect(find.text('Daily Goal'), findsNothing);
    final reusableEstimate = find.text(
      'Enable reusable-container tracking in Settings before Hydrion '
      'estimates avoided disposable plastic.',
    );
    await tester.scrollUntilVisible(
      reusableEstimate,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(reusableEstimate, findsOneWidget);
  });

  testWidgets('Home hydration immediately updates the active challenge truth',
      (tester) async {
    final services = HydrionServices.memory();
    final challenge = HydrionChallengeCatalog.byId('temperature-roulette');
    await services.challengeRepository.join(
      id: challenge.id,
      name: challenge.name,
      description: challenge.description,
      targetMl: challenge.targetMl,
      durationDays: challenge.durationDays,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    final logButton = tester.widget<FilledButton>(
      find.byKey(const Key('log-water-button')),
    );
    logButton.onPressed?.call();
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-challenges'));
    expect(find.text("Today's total hydration: 250 ml"), findsOneWidget);
    expect(
      find.text('Hydration counted toward this challenge: 250 ml / 2200 ml'),
      findsOneWidget,
    );
  });

  testWidgets('persisted log entries can be edited and deleted',
      (tester) async {
    final services = HydrionServices.memory();
    final log = await services.hydrationRepository.addLog(
      volumeMl: 400,
      timestamp: DateTime.now(),
      source: 'test',
    );
    final logId = log!.id;

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openLogHistory(tester);

    expect(find.text('400 ml'), findsOneWidget);

    await tester.tap(find.byKey(Key('edit-log-$logId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-log-volume-field')),
      '650',
    );
    await tester.tap(find.byKey(const Key('save-log-edit-button')));
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.logs.single.volumeMl, 650);
    expect(find.text('650 ml'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('delete-log-$logId')));
    await tester.pump(const Duration(milliseconds: 750));

    expect(services.hydrationRepository.logs, isEmpty);
    expect(find.text('No hydration logs found'), findsOneWidget);

    expect(find.text('Undo'), findsOneWidget);
    tester.widget<SnackBarAction>(find.byType(SnackBarAction)).onPressed();
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.logs.single.id, logId);
    expect(services.hydrationRepository.logs.single.volumeMl, 650);
    expect(find.text('650 ml'), findsOneWidget);
  });

  testWidgets('empty states explain local runtime behavior', (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openLogHistory(tester);
    expect(find.text('No hydration logs found'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab(tester, const Key('nav-progress'));
    expect(find.text('No analytics yet'), findsOneWidget);

    await openTab(tester, const Key('nav-profile'));
    expect(find.byKey(const Key('profile-lifestyle-moment')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No reminders yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No reminders yet'), findsOneWidget);
    await openTab(tester, const Key('nav-challenges'));
    await tester.scrollUntilVisible(
      find.text('No active challenge yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No active challenge yet'), findsOneWidget);
    expect(find.byKey(const Key('bottle-bingo-board')), findsNothing);
  });

  testWidgets('settings expose only working V1 controls', (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-locale-picker')), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily hydration goal'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily hydration goal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reusable container'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reusable container'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-locale-picker')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-locale-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spanish').last);
    await tester.pumpAndSettle();

    expect(find.text('Idioma actualizado'), findsOneWidget);
    expect(services.i18n.locale.languageCode, 'es');

    expect(find.textContaining('Gemini'), findsNothing);
    expect(find.textContaining('provider'), findsNothing);
    expect(find.textContaining('adapter'), findsNothing);
  });

  testWidgets('local challenge join state is persisted in app services',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-challenges'));

    expect(find.text('Challenge dock'), findsOneWidget);
    final joinButton =
        find.byKey(const Key('join-around-the-world-infusion-week'));
    await tester.scrollUntilVisible(
      joinButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(joinButton);
    await tester.pumpAndSettle();

    expect(services.challengeRepository.activeChallenge, isNotNull);
  });

  testWidgets('non-Bottle active challenge card stays at the top',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-challenges'));
    final joinButton = find.byKey(const Key('join-temperature-roulette'));
    await tester.scrollUntilVisible(
      joinButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final dynamic join = tester.widget(joinButton);
    join.onPressed();
    await tester.pumpAndSettle();

    final activeCard =
        find.byKey(const Key('challenge-card-temperature-roulette'));
    final firstCatalogCard = find.byKey(
      const Key('challenge-card-around-the-world-infusion-week'),
    );
    await tester.scrollUntilVisible(
      activeCard,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(services.challengeRepository.activeChallenge?.id,
        'temperature-roulette');
    expect(activeCard, findsOneWidget);
    expect(firstCatalogCard, findsOneWidget);
    expect(
      tester.getTopLeft(activeCard).dy,
      lessThan(tester.getTopLeft(firstCatalogCard).dy),
    );
    expect(find.byKey(const Key('bottle-bingo-board')), findsNothing);
  });

  testWidgets('Bottle Bingo hydration action writes one normal log',
      (tester) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.setContainerSizeMl(500);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-challenges'));
    expect(find.byKey(const Key('bottle-bingo-board')), findsNothing);

    final joinBottleBingo = find.byKey(const Key('join-bottle-bingo'));
    await tester.scrollUntilVisible(
      joinBottleBingo,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(joinBottleBingo);
    await tester.pumpAndSettle();
    await tester.tap(joinBottleBingo);
    await tester.pumpAndSettle();

    expect(services.challengeRepository.activeChallenge?.id, 'bottle-bingo');
    await tester.scrollUntilVisible(
      find.byKey(const Key('bottle-bingo-tile-1')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bottle-bingo-board')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bottle-bingo-tile-1')));
    await tester.pumpAndSettle();

    expect(services.hydrationRepository.logs, hasLength(1));
    expect(
      services.hydrationRepository.logs.single.volumeMl,
      services.settingsRepository.settings.containerSizeMl,
    );
    expect(
      services.hydrationRepository.logs.single.source,
      'challenge:bottle-bingo:tile-1',
    );
    expect(
      services.hydrationRepository.totalForDay(DateTime.now()),
      services.settingsRepository.settings.containerSizeMl,
    );
    expect(
      services.challengeRepository.activeChallenge?.bottleBingoCompletedTiles,
      contains(1),
    );

    await tester.tap(find.byKey(const Key('bottle-bingo-tile-1')));
    await tester.pumpAndSettle();
    expect(services.hydrationRepository.logs, hasLength(1));

    await openTab(tester, const Key('nav-home'));
    expect(find.text('500 ml / 2200 ml'), findsOneWidget);
    await openLogHistory(tester);
    expect(find.text('500 ml'), findsOneWidget);
  });

  testWidgets('Settings applies and persists day night and system themes',
      (tester) async {
    final services = HydrionServices.memory();
    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await services.settingsRepository
        .setThemePreference(HydrionThemePreference.dark);
    await tester.pumpAndSettle();
    var app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);

    await services.settingsRepository
        .setThemePreference(HydrionThemePreference.light);
    await tester.pumpAndSettle();
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);

    await services.settingsRepository
        .setThemePreference(HydrionThemePreference.system);
    await tester.pumpAndSettle();
    app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('weather assistance shows location and profile based metrics',
      (tester) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.setProfile(
      nickname: 'Weather tester',
      age: 30,
      sex: HydrionSex.female,
    );
    await services.settingsRepository.setGoalMode(
      HydrionGoalMode.weatherInformed,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    expect(
      find.text("Today's weather hydration suggestion"),
      findsOneWidget,
    );
    expect(find.textContaining('Test clear'), findsOneWidget);
    expect(find.text('Humidity: 45%'), findsOneWidget);
    expect(find.text('Standard goal: 2200 ml'), findsOneWidget);
    expect(find.text('Weather adjustment: +0 ml'), findsOneWidget);
    expect(find.text("Today's suggested goal: 2200 ml"), findsOneWidget);
    expect(
      find.textContaining(
          'saved profile, location permission, and local weather'),
      findsOneWidget,
    );

    await tester.tap(find.text('Use suggestion'));
    await tester.pumpAndSettle();
    expect(
      services.settingsRepository.settings.weatherAdjustedGoalActive,
      isTrue,
    );
  });

  testWidgets(
      'profile editor saves a local photo without restarting onboarding',
      (tester) async {
    final picker = FakeHydrionProfilePhotoPicker(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
      ),
    );
    final services = HydrionServices.memory(profilePhotoPicker: picker);

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-profile'));
    expect(find.text('Welcome to Hydrion'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-edit-action')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('profile-edit-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-edit-age')), findsNothing);
    expect(find.text('Sex selection'), findsNothing);
    expect(find.byKey(const Key('profile-restart-guided-setup')), findsNothing);
    await tester.tap(find.byKey(const Key('profile-pick-photo')));
    await tester.pumpAndSettle();

    expect(services.settingsRepository.settings.profilePhotoBase64, isNotNull);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('profile editor preserves locked age and sex on save',
      (tester) async {
    final services = HydrionServices.memory();
    await services.settingsRepository.setProfile(
      nickname: 'Avery',
      age: 34,
      sex: HydrionSex.female,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-profile'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-edit-action')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('profile-edit-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-edit-age')), findsNothing);
    expect(find.text('Sex selection'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('profile-edit-nickname')),
      'Avery Reef',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-save')),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('profile-editor-list')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();

    expect(services.settingsRepository.settings.nickname, 'Avery Reef');
    expect(services.settingsRepository.settings.age, 34);
    expect(services.settingsRepository.settings.sex, HydrionSex.female);
  });

  testWidgets('legal screen opens bundled privacy terms and safety documents',
      (tester) async {
    final services = HydrionServices.memory();

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();

    await openTab(tester, const Key('nav-profile'));
    await tester.scrollUntilVisible(
      find.byKey(const Key('profile-legal-action')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('profile-legal-action')));
    await tester.pumpAndSettle();

    expect(find.text('About & Legal'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Terms of Use'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Terms of Use'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Health and Safety Disclaimer'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Health and Safety Disclaimer'), findsOneWidget);
    expect(find.text('Read Before Publishing'), findsNothing);

    await tester.tap(find.byKey(const Key('legal-document-tile-privacy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legal-document-privacy')), findsOneWidget);
    expect(find.text('Hydrion Privacy Policy'), findsOneWidget);
  });
}

int _tabIndex(Key key) {
  return switch (key) {
    const Key('nav-home') => 0,
    const Key('nav-challenges') => 1,
    const Key('nav-progress') => 2,
    const Key('nav-profile') => 3,
    _ => throw ArgumentError('Unknown tab key: $key'),
  };
}
