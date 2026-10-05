import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrion/domain/body_metrics.dart';
import 'package:hydrion/domain/hydration_recommendation.dart';
import 'package:hydrion/l10n/app_localizations.dart';
import 'package:hydrion/main.dart';
import 'package:hydrion/repositories/body_metrics_repository.dart';
import 'package:hydrion/repositories/daily_hydration_context_repository.dart';
import 'package:hydrion/repositories/personalization_state_repository.dart';
import 'package:hydrion/repositories/settings_repository.dart';
import 'package:hydrion/services/daily_hydration_recommendation_coordinator.dart';
import 'package:hydrion/services/location_service.dart';
import 'package:hydrion/services/notifications.dart';
import 'package:hydrion/services/personalized_hydration_engine.dart';
import 'package:hydrion/services/timed_session_notification_service.dart';
import 'package:hydrion/services/weather_goal_service.dart';
import 'package:hydrion/storage/local_store.dart';

import 'support/memory_protected_app_store.dart';

/// Wave 0 D1 / owner decision O1: clinician mode without a valid clinician
/// target must block auto-apply and carry the fluid-restriction notice until
/// a valid target is entered.
void main() {
  const engine = PersonalizedHydrationEngine();
  final now = DateTime(2026, 7, 28, 12);

  PersonalizedHydrationInputs inputs(HydrionBodyMetrics metrics) =>
      PersonalizedHydrationInputs(
        existingBaselineGoalMl: 2200,
        requestedBaselineSource: HydrationBaselineSource.personalized,
        age: 30,
        sex: HydrionSex.female,
        bodyMetrics: metrics,
        dailyContext: null,
        weather: null,
        weatherEnabled: false,
        locationPermissionGranted: false,
        cachedWeatherUsed: false,
        localDateKey: '2026-07-28',
        calculatedAt: now,
      );

  HydrionBodyMetrics clinician({int? target, bool allowAbove = false}) =>
      HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 170,
        fluidSafetyMode: HydrionFluidSafetyMode.clinicianTarget,
        clinicianTargetMl: target,
        allowAdjustmentsAboveClinicianTarget: allowAbove,
      );

  group('engine', () {
    for (final allowAbove in [false, true]) {
      test(
          'missing clinician target carries restriction notice and blocks '
          'auto-apply (allowAbove=$allowAbove)', () {
        final result =
            engine.calculate(inputs(clinician(allowAbove: allowAbove)));
        expect(result.safetyNotices,
            contains(HydrationFactorCode.fluidRestriction));
        expect(result.mayAutoApply, isFalse);
        expect(result.clinicianTargetOverrodeFactors, isFalse);
        expect(result.clinicianTargetMl, isNull);
        expect(result.confidenceLevel,
            isNot(HydrationRecommendationConfidence.clinicianSet));
      });
    }

    for (final raw in [0, 100, 499, 5001, 9000, -1]) {
      test('out-of-range clinician target $raw is never an ordinary goal', () {
        final sanitized = clinician(target: raw).sanitized(femaleProfile: true);
        // Sanitization keeps the clinician mode; the invalid value becomes
        // unknown (null), not a substituted valid target.
        expect(
            sanitized.fluidSafetyMode, HydrionFluidSafetyMode.clinicianTarget);
        expect(sanitized.clinicianTargetMl, isNull);
        final result = engine.calculate(inputs(sanitized));
        expect(result.safetyNotices,
            contains(HydrationFactorCode.fluidRestriction));
        expect(result.mayAutoApply, isFalse);
      });
    }

    test('a valid clinician target keeps its accepted behavior', () {
      final result = engine.calculate(inputs(clinician(target: 1800)));
      expect(result.roundedRecommendedGoalMl, 1800);
      expect(
          result.safetyNotices, contains(HydrationFactorCode.clinicianTarget));
      expect(result.safetyNotices,
          isNot(contains(HydrationFactorCode.fluidRestriction)));
      expect(result.mayAutoApply, isFalse);
    });

    test('no fluid safety mode remains auto-appliable', () {
      final result = engine.calculate(inputs(const HydrionBodyMetrics(
        personalizationEnabled: true,
        weightKg: 70,
        heightCm: 170,
      )));
      expect(result.safetyNotices, isEmpty);
      expect(result.mayAutoApply, isTrue);
    });
  });

  group('coordinator', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));
    TestWidgetsFlutterBinding.ensureInitialized();

    test('persisted clinician mode without target is not auto-appliable',
        () async {
      final store = MemoryHydrionStore();
      final settings = await UserSettingsRepository.load(store,
          protectedStore: MemoryProtectedAppStore());
      await settings.setProfile(
          nickname: 'River', age: 30, sex: HydrionSex.female);
      await settings.setPersonalizedGoalOptions(
        baselineSource: HydrionBaselineSource.personalized,
        weatherModifierEnabled: false,
      );
      final metrics = await BodyMetricsRepository.load(store);
      await metrics.save(clinician(), femaleProfile: true, now: now);
      expect(metrics.metrics.fluidSafetyMode,
          HydrionFluidSafetyMode.clinicianTarget);
      expect(metrics.metrics.clinicianTargetMl, isNull);
      final coordinator = DailyHydrationRecommendationCoordinator(
        settingsRepository: settings,
        bodyMetricsRepository: metrics,
        dailyContextRepository: await DailyHydrationContextRepository.load(
            store,
            protectedStore: MemoryProtectedAppStore()),
        stateRepository: await PersonalizationStateRepository.load(store),
      );
      final result = await coordinator.calculateResult(now: now);
      expect(result.recommendation, isNotNull);
      expect(result.mayAutoApply, isFalse);
      expect(result.recommendation!.safetyNotices,
          contains(HydrationFactorCode.fluidRestriction));
    });
  });

  group('shell', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    testWidgets(
        'auto-apply preference cannot silently commit; dialog shows the '
        'restriction notice', (tester) async {
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
      // "Don't ask each day": auto-apply preference on.
      await settings.setWeatherGoalDailyConfirmationEnabled(false);
      expect(settings.settings.weatherGoalAutoApplyEnabled, isTrue);
      await services.guidedTourRepository.skipCoreTour();
      await services.bodyMetricsRepository
          .save(clinician(), femaleProfile: false);
      final goal = settings.settings.dailyGoalMl;

      await tester
          .pumpWidget(HydrionApp(services: services, initialRoute: '/home'));
      await tester.pumpAndSettle();

      expect(settings.settings.dailyGoalMl, goal);
      expect(settings.settings.lastWeatherGoalLocalDate, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      final l10n =
          AppLocalizations.of(tester.element(find.byType(AlertDialog)));
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(l10n.restrictionSafetyNotice),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    });
  });
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
