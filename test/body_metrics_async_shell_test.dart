import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<HydrionServices> fixture(_PausedStore store,
      {required bool auto}) async {
    final services = await HydrionServices.fromStore(
      store,
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
    await settings.setWeatherGoalDailyConfirmationEnabled(!auto);
    await services.guidedTourRepository.skipCoreTour();
    await services.bodyMetricsRepository.save(
        const HydrionBodyMetrics(
            weightKg: 70, heightCm: 175, personalizationEnabled: true),
        femaleProfile: false);
    return services;
  }

  Future<void> makeUnknown(HydrionServices services) async {
    await services.localStore
        .writeString(BodyMetricsRepository.storageKey, '{bad');
    await services.bodyMetricsRepository.reload();
    expect(
        services.bodyMetricsRepository.state.status, BodyMetricsStatus.corrupt);
  }

  testWidgets(
      'shell cannot auto-apply when safety disappears during calculation',
      (tester) async {
    final store = _PausedStore();
    final services = await fixture(store, auto: true);
    final goal = services.settingsRepository.settings.dailyGoalMl;
    store.pause = true;
    await tester
        .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
    await tester.pumpAndSettle();
    expect(store.entered.isCompleted, isTrue);
    expect(
        services
            .personalizationStateRepository.latestRecommendation!.mayAutoApply,
        isTrue);
    await makeUnknown(services);
    store.resume.complete();
    await tester.pumpAndSettle();
    expect(services.settingsRepository.settings.dailyGoalMl, goal);
    expect(
        services.settingsRepository.settings.lastWeatherGoalLocalDate, isNull);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final loseSafety in [false, true]) {
    testWidgets('shell dialog commit respects current safety: lost=$loseSafety',
        (tester) async {
      final services = await fixture(_PausedStore(), auto: false);
      final goal = services.settingsRepository.settings.dailyGoalMl;
      await tester
          .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final label =
          AppLocalizations.of(tester.element(find.byType(AlertDialog)))
              .useSuggestion;
      if (loseSafety) await makeUnknown(services);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      if (loseSafety) {
        expect(services.settingsRepository.settings.dailyGoalMl, goal);
        expect(services.settingsRepository.settings.lastWeatherGoalLocalDate,
            isNull);
      } else {
        expect(services.settingsRepository.settings.dailyGoalMl, isNot(goal));
        expect(services.settingsRepository.settings.lastWeatherGoalLocalDate,
            isNotNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

class _PausedStore extends MemoryHydrionStore {
  bool pause = false;
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<bool> writeString(String key, String value) async {
    if (pause && key == PersonalizationStateRepository.storageKey) {
      pause = false;
      entered.complete();
      await resume.future;
    }
    return super.writeString(key, value);
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
