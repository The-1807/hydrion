import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

import 'support/memory_protected_app_store.dart';

/// Wave 0 D6: confirming a weather suggestion must not silently change the
/// user's auto-apply preference.
void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<HydrionServices> fixture({
    required bool dailyConfirmation,
    required bool autoApply,
  }) async {
    final services = await HydrionServices.fromStore(
      protectedAppStore: MemoryProtectedAppStore(),
      MemoryHydrionStore(),
      locationService: FakeHydrionLocationService(),
      notificationAdapter: FakeHydrionNotificationAdapter(),
      timedSessionNotificationAdapter: FakeTimedSessionNotificationAdapter(),
      weatherProvider: _Weather(),
    );
    final settings = services.settingsRepository;
    await settings.completeOnboardingWithLegalReview(
        reviewedAt: DateTime.now());
    await settings.setProfile(
        nickname: 'Synthetic', age: 31, sex: HydrionSex.male);
    await settings.setGoalMode(HydrionGoalMode.weatherInformed);
    await settings.setPersonalizedGoalOptions(
      baselineSource: HydrionBaselineSource.personalized,
      weatherModifierEnabled: true,
    );
    await settings.setWeatherGoalDailyConfirmationEnabled(dailyConfirmation);
    await settings.setWeatherGoalAutoApplyEnabled(autoApply);
    await services.guidedTourRepository.skipCoreTour();
    // "Unsure" fluid safety blocks auto-apply in the engine, so the shell
    // asks for confirmation even when the user's auto-apply preference is on.
    await services.bodyMetricsRepository.save(
        const HydrionBodyMetrics(
          weightKg: 70,
          heightCm: 175,
          personalizationEnabled: true,
          fluidSafetyMode: HydrionFluidSafetyMode.unsure,
        ),
        femaleProfile: false);
    return services;
  }

  for (final (dailyConfirmation, autoApply) in [
    (false, true),
    (true, true),
    (true, false),
  ]) {
    testWidgets(
        'confirming a weather suggestion preserves auto-apply=$autoApply '
        '(daily confirmation=$dailyConfirmation)', (tester) async {
      final services = await fixture(
          dailyConfirmation: dailyConfirmation, autoApply: autoApply);
      final settings = services.settingsRepository;
      final goal = settings.settings.dailyGoalMl;
      expect(settings.settings.weatherGoalAutoApplyEnabled, autoApply);

      await tester
          .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final label =
          AppLocalizations.of(tester.element(find.byType(AlertDialog)))
              .useSuggestion;
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(settings.settings.dailyGoalMl, isNot(goal));
      expect(settings.settings.lastWeatherGoalLocalDate, isNotNull);
      expect(settings.settings.weatherGoalAutoApplyEnabled, autoApply);
      expect(settings.settings.weatherGoalDailyConfirmationEnabled,
          dailyConfirmation);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _Weather implements DailyWeatherProvider {
  @override
  bool get isConfigured => true;
  @override
  String get providerId => 'synthetic';
  @override
  Future<WeatherSnapshot> fetchDailyForecast(HydrionCoordinates coordinates,
      {DateTime? now}) async {
    final time = now ?? DateTime.now();
    return WeatherSnapshot(
        temperatureC: 32, uvIndex: 5, observedAt: time, retrievedAt: time);
  }
}
