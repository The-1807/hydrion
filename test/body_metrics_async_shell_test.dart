import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_protected_app_store.dart';
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
import 'package:hydrion/storage/protected_app_store.dart';
import 'support/controllable_hydrion_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<HydrionServices> fixture(ControllableHydrionStore store,
      {required bool auto, MemoryProtectedAppStore? protected}) async {
    final services = await HydrionServices.fromStore(
      protectedAppStore: protected ?? MemoryProtectedAppStore(),
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
    final store = ControllableHydrionStore();
    final services = await fixture(store, auto: true);
    final goal = services.settingsRepository.settings.dailyGoalMl;
    final hold = holdStateWrite(store);
    await tester
        .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
    await tester.pumpAndSettle();
    expect(hold.engaged, isTrue);
    expect(
        services
            .personalizationStateRepository.latestRecommendation!.mayAutoApply,
        isTrue);
    await makeUnknown(services);
    hold.release();
    await tester.pumpAndSettle();
    expect(services.settingsRepository.settings.dailyGoalMl, goal);
    expect(
        services.settingsRepository.settings.lastWeatherGoalLocalDate, isNull);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  for (final auto in [false, true]) {
    testWidgets('daily-context outage blocks shell commit: auto=$auto',
        (tester) async {
      final local = ControllableHydrionStore();
      final protected = MemoryProtectedAppStore();
      final services = await fixture(local, auto: auto, protected: protected);
      final goal = services.settingsRepository.settings.dailyGoalMl;
      final hold = auto ? holdStateWrite(local) : null;
      await tester
          .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
      await tester.pumpAndSettle();
      expect(
          auto
              ? hold!.engaged
              : find.byType(AlertDialog).evaluate().isNotEmpty,
          isTrue);
      protected.readFailure = ProtectedReadStatus.unavailable;
      await services.dailyHydrationContextRepository.retry();
      expect(services.dailyHydrationContextRepository.isKnown, isFalse);
      if (auto) {
        hold!.release();
      } else {
        final label =
            AppLocalizations.of(tester.element(find.byType(AlertDialog)))
                .useSuggestion;
        await tester.tap(find.text(label));
      }
      await tester.pumpAndSettle();
      expect(services.settingsRepository.settings.dailyGoalMl, goal);
      expect(services.settingsRepository.settings.lastWeatherGoalLocalDate,
          isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final loseSafety in [false, true]) {
    testWidgets('shell dialog commit respects current safety: lost=$loseSafety',
        (tester) async {
      final services = await fixture(ControllableHydrionStore(), auto: false);
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

/// Holds the first personalization-state write until released.
ControllableStoreHold holdStateWrite(ControllableHydrionStore store) =>
    store.hold(
        once: true,
        when: (key) => key == PersonalizationStateRepository.storageKey);
