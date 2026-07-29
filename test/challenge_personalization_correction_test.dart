import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/daily_hydration_context.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/current_weather_context.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/ui/screens/challenge_experience_screen.dart';

void main() {
  test(
      'current weather context rejects disabled, revoked, stale, and old-day data',
      () {
    final now = DateTime(2026, 7, 28, 12);
    final context = CurrentWeatherContext()
      ..publish(
        snapshot: WeatherSnapshot(
          temperatureC: 30,
          uvIndex: 5,
          observedAt: now,
          retrievedAt: now,
        ),
        localDateKey: '2026-07-28',
        fromCache: true,
      );
    expect(
      context.eligibleSnapshot(
        now: now,
        weatherEnabled: true,
        locationPermissionGranted: true,
      ),
      isNotNull,
    );
    expect(
      context.eligibleSnapshot(
        now: now,
        weatherEnabled: false,
        locationPermissionGranted: true,
      ),
      isNull,
    );
    expect(
      context.eligibleSnapshot(
        now: now,
        weatherEnabled: true,
        locationPermissionGranted: false,
      ),
      isNull,
    );
    expect(
      context.eligibleSnapshot(
        now: now.add(const Duration(hours: 19)),
        weatherEnabled: true,
        locationPermissionGranted: true,
      ),
      isNull,
    );
  });

  testWidgets('live hot-weather suggestion opens details without mutation',
      (tester) async {
    final services = HydrionServices.memory();
    await services.permissions.refresh();
    await services.settingsRepository.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.manual,
      weatherModifierEnabled: true,
    );
    final now = DateTime.now();
    await services.dailyHydrationContextRepository.save(
      DailyHydrationContext(
        localDateKey: hydrionLocalDateKey(now),
        environment: HydrionEnvironmentExposure.mostlyOutdoors,
        updatedAt: now,
      ),
    );
    final warmSnapshot = WeatherSnapshot(
      temperatureC: 30,
      apparentTemperatureC: 31,
      uvIndex: 5,
      observedAt: now,
      retrievedAt: now,
    );
    await WeatherForecastCacheRepository(services.localStore).write(
      localDateKey: hydrionLocalDateKey(now),
      forecast: warmSnapshot,
    );
    services.currentWeatherContext.publish(
      snapshot: warmSnapshot,
      localDateKey: hydrionLocalDateKey(now),
      fromCache: true,
    );

    await tester.pumpWidget(HydrionApp(services: services));
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(
          find.byKey(const Key('hydrion-bottom-nav')),
        )
        .onDestinationSelected
        ?.call(1);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommended-challenge-card')), findsOneWidget);
    expect(find.text('Temperature Roulette'), findsWidgets);
    expect(
      find.text("Today's warm conditions make this challenge a useful match."),
      findsOneWidget,
    );
    final view = find.byKey(const Key('view-recommended-challenge'));
    await tester.ensureVisible(view);
    await tester.pumpAndSettle();
    await tester.tap(view);
    await tester.pumpAndSettle();
    expect(find.byType(ChallengeExperienceScreen), findsOneWidget);
    expect(services.challengeRepository.activeChallenges, isEmpty);
    expect(services.hydrationRepository.logs, isEmpty);
  });

  testWidgets('challenge preferences work on narrow dark large-text layout',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final services = HydrionServices.memory();
    await services.settingsRepository
        .setThemePreference(HydrionThemePreference.dark);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: HydrionApp(services: services),
      ),
    );
    await tester.pumpAndSettle();
    tester
        .widget<NavigationBar>(
          find.byKey(const Key('hydrion-bottom-nav')),
        )
        .onDestinationSelected
        ?.call(1);
    await tester.pumpAndSettle();
    final card = find.byKey(const Key('challenge-suggestion-preferences'));
    await tester.scrollUntilVisible(
      card,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('edit-challenge-preferences')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('preference-timed-routines'));
    await tester.scrollUntilVisible(
      toggle,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final done = find.widgetWithText(FilledButton, 'Done');
    tester.widget<FilledButton>(done).onPressed!();
    await tester.pumpAndSettle();
    expect(
      services.personalizationStateRepository.challengePreferences
          .prefersTimedRoutines,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
